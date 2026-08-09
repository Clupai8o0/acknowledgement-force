import Foundation
import AVFoundation
import QuartzCore

/// Live microphone amplitude, exposed as a 40-slot scrolling ring buffer.
///
/// Two clocks on purpose:
///   • the AVAudioEngine input tap fires at the hardware IO buffer rate
///     (~93 Hz at 512 frames / 48 kHz) and only updates `current`;
///   • a 60 Hz timer shifts the ring so the bars scroll at display rate
///     independently of buffer size.
///
/// `levels` is deliberately NOT `@Published`: the view reads it from inside a
/// `TimelineView(.animation)` body, so SwiftUI is already re-evaluating at
/// display rate and a 60 Hz publisher would only add invalidation churn.
@MainActor
final class AudioMeter: ObservableObject {
    static let barCount = 40

    /// Newest sample is the LAST element (right-hand end of the meter).
    private(set) var levels = [CGFloat](repeating: 0, count: AudioMeter.barCount)

    /// Seconds since `start()`. Read by the timer readout each frame.
    private(set) var elapsed: TimeInterval = 0

    /// Surfaced so the UI can say something when the mic is refused.
    @Published private(set) var denied = false
    @Published private(set) var failed: String?

    private let engine = AVAudioEngine()
    private var tick: DispatchSourceTimer?
    private var startedAt: CFTimeInterval = 0
    private var running = false

    // Written on the audio thread, read on main. A single Double, and the
    // meter is cosmetic — a lock here would be worse than the tear it prevents.
    private let raw = Atomic()
    private var smoothed: CGFloat = 0

    /// GATE_DEBUG=1 logs the amplitude pipeline to stderr — spike diagnostics only.
    static let debug = ProcessInfo.processInfo.environment["GATE_DEBUG"] != nil
    /// GATE_FAKE_MIC=1 substitutes a synthetic amplitude source. Only for
    /// headless measurement runs: answering the microphone TCC prompt needs a
    /// human click, and synthetic clicks are blocked on TCC dialogs by design.
    static let fakeMic = ProcessInfo.processInfo.environment["GATE_FAKE_MIC"] != nil
    private var peak: CGFloat = 0
    private var frames = 0

    final class Atomic: @unchecked Sendable {
        private var value: Double = 0
        private let lock = NSLock()
        var level: Double {
            get { lock.lock(); defer { lock.unlock() }; return value }
            set { lock.lock(); value = newValue; lock.unlock() }
        }
    }

    func start() {
        guard !running else { return }
        running = true
        startedAt = CACurrentMediaTime()
        elapsed = 0
        levels = [CGFloat](repeating: 0, count: Self.barCount)
        smoothed = 0
        frameStamps.removeAll()

        startTicker()

        if Self.fakeMic { return }

        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            Task { @MainActor in
                guard let self, self.running else { return }
                if Self.debug {
                    FileHandle.standardError.write(Data("mic access granted=\(granted)\n".utf8))
                }
                guard granted else { self.denied = true; return }
                self.startEngine()
            }
        }
    }

    // MARK: - Frame-time sampling (diagnostics)

    private var frameStamps: [CFTimeInterval] = []

    /// Called from the `TimelineView` body so the sample is the actual view
    /// re-evaluation cadence, not our own timer's.
    func noteFrame() {
        guard Self.debug else { return }
        frameStamps.append(CACurrentMediaTime())
    }

    private func reportFrames() {
        guard Self.debug, frameStamps.count > 2 else { return }
        var gaps: [Double] = []
        for i in 1..<frameStamps.count { gaps.append((frameStamps[i] - frameStamps[i - 1]) * 1000) }
        let sorted = gaps.sorted()
        let mean = gaps.reduce(0, +) / Double(gaps.count)
        let p50 = sorted[sorted.count / 2]
        let p99 = sorted[Int(Double(sorted.count) * 0.99)]
        let worst = sorted.last ?? 0
        let over20 = gaps.filter { $0 > 20 }.count
        let over33 = gaps.filter { $0 > 33 }.count
        let msg = """
        frames=\(gaps.count + 1) over \(String(format: "%.2f", elapsed))s \
        (\(String(format: "%.1f", Double(gaps.count + 1) / max(elapsed, 0.001))) fps) \
        mean=\(String(format: "%.2f", mean))ms p50=\(String(format: "%.2f", p50))ms \
        p99=\(String(format: "%.2f", p99))ms worst=\(String(format: "%.2f", worst))ms \
        gaps>20ms=\(over20) gaps>33ms=\(over33)\n
        """
        FileHandle.standardError.write(Data(msg.utf8))
        frameStamps.removeAll()
    }

    func stop() {
        guard running else { return }
        reportFrames()
        running = false
        tick?.cancel()
        tick = nil
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
        raw.level = 0
    }

    // MARK: - Engine

    private func startEngine() {
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        guard format.sampleRate > 0, format.channelCount > 0 else {
            failed = "no input device"
            return
        }
        let box = raw
        input.installTap(onBus: 0, bufferSize: 512, format: format) { buffer, _ in
            guard let data = buffer.floatChannelData else { return }
            let n = Int(buffer.frameLength)
            guard n > 0 else { return }
            var sum: Float = 0
            let channel = data[0]
            for i in 0..<n { let s = channel[i]; sum += s * s }
            let rms = (sum / Float(n)).squareRoot()
            // dBFS -> 0...1, floor at -55 dB so room tone sits near the baseline.
            let db = 20 * log10(max(rms, 1e-7))
            let norm = Double(max(0, min(1, (db + 55) / 55)))
            box.level = norm
        }
        do {
            engine.prepare()
            try engine.start()
            if Self.debug {
                FileHandle.standardError.write(
                    Data("engine started sr=\(format.sampleRate) ch=\(format.channelCount)\n".utf8))
            }
        } catch {
            failed = error.localizedDescription
            if Self.debug {
                FileHandle.standardError.write(Data("engine start FAILED: \(error)\n".utf8))
            }
        }
    }

    // MARK: - 60 Hz ring shift

    /// Speech-shaped stand-in: syllable-rate bursts inside a phrase envelope.
    private static func synthetic(at t: TimeInterval) -> Double {
        let syllable = 0.5 + 0.5 * sin(t * 2 * .pi * 4.3)
        let phrase = 0.55 + 0.45 * sin(t * 2 * .pi * 0.33)
        let jitter = 0.85 + 0.15 * sin(t * 2 * .pi * 17.0)
        return max(0, min(1, syllable * phrase * jitter))
    }

    private func startTicker() {
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: .milliseconds(16), leeway: .milliseconds(1))
        t.setEventHandler { [weak self] in self?.shift() }
        tick = t
        t.resume()
    }

    private func shift() {
        elapsed = CACurrentMediaTime() - startedAt
        if Self.fakeMic { raw.level = Self.synthetic(at: elapsed) }
        let target = CGFloat(raw.level)
        if Self.debug {
            peak = max(peak, target)
            frames += 1
            if frames % 60 == 0 {
                FileHandle.standardError.write(
                    Data("meter t=\(Int(elapsed))s level=\(String(format: "%.3f", target)) peak=\(String(format: "%.3f", peak)) engine=\(engine.isRunning)\n".utf8))
            }
        }
        // Fast attack, slow release — makes speech read as speech, not as noise.
        let k: CGFloat = target > smoothed ? 0.55 : 0.14
        smoothed += (target - smoothed) * k
        levels.removeFirst()
        levels.append(max(0, min(1, smoothed)))
    }
}
