import SwiftUI
import AppKit

// MARK: - Model

enum Mark {
    case kept       // filled ink
    case broken     // filled stone
    case unsettled  // hollow outline ring
}

enum Phase {
    case idle
    case recording
    case waiting    // released, transcript not back yet
    case review     // transcript + verdicts
    case settling   // mark flying into the strip
    case closing
}

private let cannedTranscript =
    "\u{201C}went after the shift. forty minutes. didn\u{2019}t want to until I was through the door.\u{201D}"

// MARK: - Screen

struct GateView: View {
    @StateObject private var meter = AudioMeter()
    @Namespace private var ns

    @State private var phase: Phase = .idle
    /// The six days before today. Today's slot is the flight destination.
    @State private var history: [Mark] = [.unsettled, .unsettled, .unsettled, .unsettled, .kept, .kept]
    @State private var today: Mark?
    @State private var landed = false
    @State private var showTranscript = false
    @State private var showVerdicts = false

    private var recording: Bool { phase == .recording }

    var body: some View {
        ZStack {
            Ink.base.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 44)
                    .padding(.top, 30)

                ZStack {
                    if phase == .closing {
                        closingColumn.transition(.opacity)
                    } else {
                        mainColumn.transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: Metrics.windowWidth, height: Metrics.windowHeight)
        .onAppear {
            Instrument.markFirstPaint()
            scriptedHoldIfRequested()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Text(dateLine)
                .font(Face.label)
                .tracking(1.9)
                .foregroundStyle(Ink.mute)
            Spacer(minLength: 24)
            recordStrip
        }
    }

    private var recordStrip: some View {
        HStack(spacing: 9) {
            ForEach(Array(history.enumerated()), id: \.offset) { _, mark in
                MarkDot(mark: mark, size: 8)
            }
            ZStack {
                // Today's slot, still empty — a pip, so it reads differently
                // from an `unsettled` ring.
                Circle()
                    .fill(Ink.outlineSoft)
                    .frame(width: 4, height: 4)
                    .opacity(landed ? 0 : 1)
                if landed, let today {
                    MarkDot(mark: today, size: 8)
                        .matchedGeometryEffect(id: "todayMark", in: ns)
                }
            }
            .frame(width: 8, height: 8)
        }
    }

    // MARK: Main column

    private var mainColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: 0)

            Text("I am someone who trains\nwhen I don\u{2019}t feel like it.")
                .font(Face.claim)
                .tracking(-0.5)
                .lineSpacing(9)
                .foregroundStyle(Ink.ink)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Text("this morning you said:")
                    .font(Face.meta)
                    .foregroundStyle(Ink.mute)
                Text("\u{201C}gym after the 4pm shift\u{201D}")
                    .font(Face.meta)
                    .foregroundStyle(Ink.inkContainer)
            }
            .padding(.top, 30)

            // Stubbed STT result — fades in ~400ms after release.
            Text(cannedTranscript)
                .font(Face.meta)
                .foregroundStyle(Ink.ash)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(showTranscript ? 1 : 0)
                .padding(.top, 18)
                .frame(height: 40, alignment: .top)

            Spacer(minLength: 0)

            actionZone
                .frame(maxWidth: .infinity, alignment: .center)

            Text("Not tonight")
                .font(Face.meta)
                .foregroundStyle(Ink.mute)
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .contentShape(Rectangle())
                .onTapGesture { notTonight() }
                .opacity(phase == .settling ? 0 : 1)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 26)

            Spacer(minLength: 0)
        }
        .frame(width: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Action zone

    /// Fixed height so the button → meter → verdicts → mark sequence never
    /// reflows the column above it.
    private var actionZone: some View {
        ZStack {
            if phase == .idle || phase == .recording {
                holdButton
            }
            if phase == .review {
                verdicts
                    .opacity(showVerdicts ? 1 : 0)
                    .scaleEffect(showVerdicts ? 1 : 0.96)
            }
            if phase == .settling, !landed, let today {
                MarkDot(mark: today, size: 18)
                    .matchedGeometryEffect(id: "todayMark", in: ns)
            }
        }
        .frame(height: 88)
    }

    private var holdButton: some View {
        // Overlays, not a ZStack: the 40-bar meter has an intrinsic width of
        // 356pt, and inside a ZStack that would stretch the idle button to 356
        // even at opacity 0. Overlay content is sized by its parent instead.
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(recording ? Ink.containerLow : Ink.container)
            .frame(width: recording ? 420 : 280, height: recording ? 78 : 64)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(recording ? Ink.bright : Ink.outline, lineWidth: 1)
            }
            .overlay {
                Text("HOLD  TO  SPEAK")
                    .font(Face.button)
                    .tracking(2.4)
                    .foregroundStyle(Ink.ash)
                    .fixedSize()
                    .opacity(recording ? 0 : 1)
            }
            .overlay {
                MeterView(meter: meter, active: recording)
                    .fixedSize()
                    .opacity(recording ? 1 : 0)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .animation(.spring(response: 0.34, dampingFraction: 0.84), value: recording)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in beginHold() }
                .onEnded { _ in endHold() }
        )
        .transition(.opacity)
    }

    private var verdicts: some View {
        HStack(spacing: 14) {
            verdictButton("KEPT", fill: Ink.ink, label: Ink.onPrimary) { settle(.kept) }
            verdictButton("BROKEN", fill: Ink.container, label: Ink.ash) { settle(.broken) }
        }
        .transition(.opacity)
    }

    private func verdictButton(_ title: String,
                               fill: Color,
                               label: Color,
                               action: @escaping () -> Void) -> some View {
        Text(title)
            .font(Face.button)
            .tracking(2.0)
            .foregroundStyle(label)
            .frame(width: 132, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Ink.outline, lineWidth: fill == Ink.ink ? 0 : 1)
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
    }

    // MARK: Closing

    private var closingColumn: some View {
        VStack(spacing: 12) {
            Text(closingHeadline)
                .font(Face.closing)
                .foregroundStyle(Ink.ink)
            Text("see you tomorrow")
                .font(Face.meta)
                .foregroundStyle(Ink.mute)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var closingHeadline: String {
        switch today {
        case .kept: return "Kept."
        case .broken: return "Broken."
        case .unsettled, nil: return "Unsettled."
        }
    }

    // MARK: Sequence

    private func beginHold() {
        guard phase == .idle else { return }
        phase = .recording
        meter.start()
    }

    private func endHold() {
        guard phase == .recording else { return }
        meter.stop()
        withAnimation(.easeOut(duration: 0.2)) { phase = .waiting }

        // Stubbed STT: canned string after ~400ms. Real transcription is out of
        // scope for the spike (SPEC "Explicitly out of scope").
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeInOut(duration: 0.45)) {
                showTranscript = true
                phase = .review
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) {
                    showVerdicts = true
                }
            }
        }
    }

    private func notTonight() {
        meter.stop()
        settle(.unsettled)
    }

    private func settle(_ mark: Mark) {
        guard phase != .settling, phase != .closing else { return }
        today = mark
        withAnimation(.easeOut(duration: 0.18)) {
            showVerdicts = false
            phase = .settling
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) { landed = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            withAnimation(.easeInOut(duration: 0.55)) { phase = .closing }
        }
        // "immediate close, no confirmation" — the gate shuts after the closing
        // state has been readable for a beat. GATE_STAY=1 keeps it open.
        if ProcessInfo.processInfo.environment["GATE_STAY"] == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { NSApp.terminate(nil) }
        }
    }

    /// Measurement scaffolding only: GATE_HOLD=10 drives a 10s press-and-hold
    /// with no human hand, so "RSS while metering" is reproducible.
    private func scriptedHoldIfRequested() {
        let env = ProcessInfo.processInfo.environment
        guard let raw = env["GATE_HOLD"], let seconds = Double(raw) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { beginHold() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + seconds) { endHold() }
        if let verdict = env["GATE_VERDICT"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6 + seconds + 1.8) {
                settle(verdict == "broken" ? .broken : .kept)
            }
        }
    }

    private var dateLine: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
        f.locale = Locale(identifier: "en_GB")
        return f.string(from: Date()).uppercased()
    }
}

// MARK: - Record-strip mark

struct MarkDot: View {
    let mark: Mark
    let size: CGFloat

    var body: some View {
        Group {
            switch mark {
            case .kept:
                Circle().fill(Ink.ink)
            case .broken:
                Circle().fill(Ink.stone)
            case .unsettled:
                Circle().strokeBorder(Ink.outline, lineWidth: max(1, size / 7))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - 40-bar live meter

/// 40 discrete SwiftUI views rather than a single `Canvas` on purpose: the point
/// of the spike is to compare what each stack does when a normal developer
/// writes 40 elements and animates all of them, which is what the React and
/// Flutter builds will do.
struct MeterView: View {
    @ObservedObject var meter: AudioMeter
    /// Parked when idle — the view stays mounted for the crossfade, but a
    /// paused schedule keeps the display link from running at 60 Hz all evening.
    var active: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !active)) { _ in
            let levels = meter.levels
            let _ = active ? meter.noteFrame() : ()
            VStack(spacing: 7) {
                HStack(alignment: .center, spacing: 4) {
                    ForEach(0..<AudioMeter.barCount, id: \.self) { i in
                        let v = levels[i]
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(Ink.ink.opacity(0.28 + 0.72 * Double(v)))
                            .frame(width: 5, height: max(3, 3 + v * 34))
                    }
                }
                .frame(height: 37)

                Text(readout)
                    .font(Face.timer)
                    .monospacedDigit()
                    .tracking(1.2)
                    .foregroundStyle(Ink.mute)
            }
        }
    }

    private var readout: String {
        if meter.denied { return "MIC DENIED" }
        if let failed = meter.failed { return failed.uppercased() }
        let t = meter.elapsed
        return String(format: "%d:%02d.%01d", Int(t) / 60, Int(t) % 60, Int((t * 10).truncatingRemainder(dividingBy: 10)))
    }
}
