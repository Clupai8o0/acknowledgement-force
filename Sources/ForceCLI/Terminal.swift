import Foundation
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(CRT)
import CRT
#endif

/// Small terminal toolkit: ANSI styling (only when stdout is a TTY) and
/// prompting, including no-echo password entry on POSIX systems.
enum Terminal {
    /// True when stdout is an interactive terminal — gates ANSI codes so
    /// piped/redirected output stays plain.
    static let isTTY: Bool = {
        #if os(Windows)
        return _isatty(_fileno(stdout)) != 0
        #else
        return isatty(STDOUT_FILENO) == 1
        #endif
    }()

    static func bold(_ s: String) -> String {
        isTTY ? "\u{1B}[1m\(s)\u{1B}[0m" : s
    }
    static func dim(_ s: String) -> String {
        isTTY ? "\u{1B}[2m\(s)\u{1B}[0m" : s
    }

    /// Prompts and reads one trimmed line; returns "" on EOF.
    static func prompt(_ label: String) -> String {
        print(label, terminator: "")
        return (readLine() ?? "").trimmingCharacters(in: .whitespaces)
    }

    /// Reads a password without echoing on POSIX. Windows consoles fall back
    /// to echoed input (documented in the README); prefer piping via stdin
    /// with `login --password-stdin` for scripting on any platform.
    static func promptPassword(_ label: String) -> String {
        print(label, terminator: "")
        #if os(Windows)
        let line = readLine() ?? ""
        #else
        var current = termios()
        tcgetattr(STDIN_FILENO, &current)
        var original = current
        current.c_lflag &= ~tcflag_t(ECHO)
        tcsetattr(STDIN_FILENO, TCSANOW, &current)
        let line = readLine() ?? ""
        tcsetattr(STDIN_FILENO, TCSANOW, &original)
        print("") // the suppressed newline
        #endif
        return line
    }

    /// Writes to stderr and exits with the given status.
    static func fail(_ message: String, code: Int32 = 1) -> Never {
        FileHandle.standardError.write(Data(("error: " + message + "\n").utf8))
        exit(code)
    }
}
