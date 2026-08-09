import Foundation
import ForceKit

// force-cli — the terminal version of Acknowledgement Force for Linux and
// Windows (it runs on macOS too). Same contract, same gate policy, same
// Supabase sync as the macOS app, rendered for a terminal.
//
// Exit codes: 0 success · 1 error · 2 usage · 3 `status` while locked
// (so shell profiles / schedulers can branch on the gate).

@main
struct ForceCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        let env = CLIEnvironment()

        switch args.first {
        case nil, "status":
            status(env)
        case "contract":
            print(ContractRenderer.render(settings: env.settings))
        case "ack":
            acknowledge(env, args: Array(args.dropFirst()))
        case "check":
            checklist(env, args: Array(args.dropFirst()))
        case "history":
            history(env)
        case "login":
            await login(env, args: Array(args.dropFirst()))
        case "logout":
            await env.engine.logout()
            print("Logged out.")
        case "sync":
            await sync(env)
        case "config":
            config(env, args: Array(args.dropFirst()))
        case "help", "-h", "--help":
            print(usage)
        case let cmd?:
            FileHandle.standardError.write(Data("error: unknown command '\(cmd)'\n\n\(usage)\n".utf8))
            exit(2)
        }
    }

    // MARK: status

    /// Shows the gate, today's action, and checklist progress. Exits 3 when
    /// the gate is locked so scripts can react.
    static func status(_ env: CLIEnvironment) {
        let locked = env.isLocked
        print(Terminal.bold("ACKNOWLEDGEMENT FORCE"))
        print("Schedule:  \(env.settings.frequency.label)")
        if let ack = env.journal.acknowledgement() {
            print("Last ack:  \(AppDate.short(ack.date)) — \(ack.action)")
        } else {
            print("Last ack:  never")
        }

        let items = env.settings.nonNegotiables
        let state = env.journal.loadChecklist(items: items)
        let done = items.filter { state[$0.id] == true }.count
        print("Checklist: \(done)/\(items.count) done today")

        if locked {
            print("Gate:      " + Terminal.bold("LOCKED") + " — run `force-cli ack` to read and sign today's contract")
            exit(3)
        }
        print("Gate:      open")
    }

    // MARK: ack

    /// Reads the contract and signs it. Interactive by default; pass
    /// `--action "..."` and `--yes` to script it.
    static func acknowledge(_ env: CLIEnvironment, args: [String]) {
        var action: String?
        var skipConfirmation = false
        var rest = args[...]
        while let arg = rest.first {
            rest = rest.dropFirst()
            switch arg {
            case "--action":
                guard let value = rest.first else { Terminal.fail("--action needs a value", code: 2) }
                action = value
                rest = rest.dropFirst()
            case "--yes", "-y":
                skipConfirmation = true
            default:
                Terminal.fail("unknown option '\(arg)'", code: 2)
            }
        }

        if !env.isLocked {
            print("Already acknowledged for this period — nothing to sign.")
            return
        }

        print(ContractRenderer.render(settings: env.settings))
        print("")

        if !skipConfirmation {
            let typed = Terminal.prompt("Type \"I ACKNOWLEDGE\" to sign today's contract: ")
            guard typed.uppercased() == "I ACKNOWLEDGE" else {
                Terminal.fail("not acknowledged — the contract stays locked")
            }
        }

        var finalAction = action?.trimmingCharacters(in: .whitespaces) ?? ""
        while finalAction.isEmpty {
            finalAction = Terminal.prompt("Today's single highest-leverage action: ")
        }

        env.journal.confirm(action: finalAction, items: env.settings.nonNegotiables)
        print("")
        print("Signed. Gate is open — go execute: " + Terminal.bold(finalAction))
    }

    // MARK: check

    /// `check` lists today's non-negotiables; `check <n>` toggles item n.
    static func checklist(_ env: CLIEnvironment, args: [String]) {
        let items = env.settings.nonNegotiables
        var state = env.journal.loadChecklist(items: items)

        if let first = args.first {
            guard let n = Int(first), items.indices.contains(n - 1) else {
                Terminal.fail("expected an item number 1-\(items.count)", code: 2)
            }
            let id = items[n - 1].id
            state[id, default: false].toggle()
            env.journal.persistChecklist(state, for: AppDate.todayKey())
        }

        print(Terminal.bold("DAILY NON-NEGOTIABLES"))
        for (i, item) in items.enumerated() {
            let mark = state[item.id] == true ? "[x]" : "[ ]"
            print("  \(i + 1). \(mark) \(item.label)")
        }
    }

    // MARK: history

    static func history(_ env: CLIEnvironment) {
        let entries = env.journal.history()
        guard !entries.isEmpty else {
            print("No past actions recorded yet.")
            return
        }
        print(Terminal.bold("PAST ACTIONS"))
        for entry in entries {
            print("  \(AppDate.short(entry.date))  \(entry.action)")
        }
    }

    // MARK: login / sync

    static func login(_ env: CLIEnvironment, args: [String]) async {
        guard env.isConfigured else {
            Terminal.fail("""
            no Supabase connection configured. Set it first:
              force-cli config set url https://xxxx.supabase.co
              force-cli config set key <anon public key>
            """)
        }
        var email = args.first(where: { !$0.hasPrefix("--") }) ?? ""
        if email.isEmpty { email = Terminal.prompt("Email: ") }
        guard !email.isEmpty else { Terminal.fail("an email is required", code: 2) }

        // --password-stdin reads the secret from a pipe (echo-free and
        // script-friendly on every platform, including Windows).
        let password: String
        if args.contains("--password-stdin") {
            password = (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            password = Terminal.promptPassword("Password: ")
        }
        guard !password.isEmpty else { Terminal.fail("a password is required", code: 2) }

        do {
            let session = try await env.engine.login(email: email, password: password)
            print("Logged in as \(session.email ?? email).")
            await sync(env)
        } catch {
            Terminal.fail(friendly(error))
        }
    }

    /// Pulls cloud content into local state. The CLI never edits synced fields
    /// (contract/goals are edited on the web or the Mac), so sync is pull-only.
    static func sync(_ env: CLIEnvironment) async {
        guard env.engine.isLoggedIn else {
            Terminal.fail("not logged in — run `force-cli login <email>` first")
        }
        do {
            let content = try await env.engine.fetchContent()
            let settings = env.settings

            let contract = content.contractMd.trimmingCharacters(in: .whitespacesAndNewlines)
            if !contract.isEmpty { settings.contractText = content.contractMd }
            if !content.goals.isEmpty {
                settings.nonNegotiables = content.goals.map { NonNegotiable(id: $0.id, label: $0.label) }
            }
            let quotes = content.quotes
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if let quote = quotes.randomElement() { settings.motivation = quote }
            settings.reflection = content.reflection

            print("Synced contract, goals, quotes, and reflection from the cloud.")
        } catch {
            Terminal.fail(friendly(error))
        }
    }

    // MARK: config

    /// `config` prints the current setup; `config set <field> <value>` edits it.
    static func config(_ env: CLIEnvironment, args: [String]) {
        guard !args.isEmpty else {
            print(Terminal.bold("CONFIG"))
            print("  url:        \(env.effectiveURL.isEmpty ? "(unset)" : env.effectiveURL)")
            print("  key:        \(env.effectiveAnonKey.isEmpty ? "(unset)" : "(set)")")
            print("  name:       \(env.settings.displayName.isEmpty ? "(unset)" : env.settings.displayName)")
            print("  frequency:  \(env.settings.frequency.rawValue)")
            print("  state dir:  \(CLIEnvironment.stateDirectory().path)")
            print("")
            print("Edit with: force-cli config set <url|key|name|frequency> <value>")
            return
        }
        guard args.count == 3, args[0] == "set" else {
            Terminal.fail("usage: force-cli config set <url|key|name|frequency> <value>", code: 2)
        }
        let value = args[2]
        switch args[1] {
        case "url":
            guard value.hasPrefix("https://") else { Terminal.fail("the Supabase URL must be https://") }
            env.store.set(value, forKey: CLIEnvironment.Keys.baseURL)
        case "key":
            env.store.set(value, forKey: CLIEnvironment.Keys.anonKey)
        case "name":
            env.settings.displayName = value
        case "frequency":
            guard let freq = Frequency(rawValue: value) else {
                let all = Frequency.allCases.map(\.rawValue).joined(separator: ", ")
                Terminal.fail("unknown frequency '\(value)' — one of: \(all)", code: 2)
            }
            env.settings.frequency = freq
        default:
            Terminal.fail("unknown config field '\(args[1])'", code: 2)
        }
        print("Saved.")
    }

    // MARK: helpers

    private static func friendly(_ error: Error) -> String {
        switch error {
        case let e as SyncError: return e.message
        case let e as HTTPStatusError: return e.message
        default: return (error as NSError).localizedDescription
        }
    }

    static let usage = """
    force-cli — Acknowledgement Force for the terminal

    USAGE
      force-cli [command]

    COMMANDS
      status            Gate state, last acknowledgement, checklist progress (default)
      contract          Print today's contract
      ack               Read and sign today's contract
                          --action "..."  set the action non-interactively
                          --yes           skip the I ACKNOWLEDGE confirmation
      check [n]         Show the daily checklist; toggle item n
      history           Past acknowledged actions (last 30 days)
      login [email]     Sign in to sync (--password-stdin to pipe the password)
      logout            Sign out and revoke the session
      sync              Pull contract/goals/quotes/reflection from the cloud
      config            Show configuration
      config set <f> v  Set url | key | name | frequency
      help              This text

    FILES
      State lives in the per-user data directory (override: FORCE_STATE_DIR).
      Run `force-cli config` to see the resolved path.
    """
}
