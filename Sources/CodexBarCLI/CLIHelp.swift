import CodexBarCore
import Foundation

extension CodexBarCLI {
    static func usageHelp(version: String) -> String {
        """
        \(AppIdentity.displayName) \(version)

        Usage:
          researchbar usage [--format text|json]
                       [--json]
                       [--json-only]
                       [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>] [-v|--verbose]
                       [--provider \(ProviderHelp.list)]
                       [--account <label>] [--account-index <index>] [--all-accounts]
                       [--no-credits] [--no-color] [--pretty] [--status] [--source <auto|web|cli|oauth|api>]
                       [--web-timeout <seconds>] [--web-debug-dump-html] [--antigravity-plan-debug] [--augment-debug]

        Description:
          Print usage from enabled providers as text (default) or JSON. Honors your in-app toggles.
          Output format: use --json (or --format json) for JSON on stdout; use --json-output for JSON logs on stderr.
          Source behavior is provider-specific:
          - Codex: OpenAI web dashboard (usage limits, credits remaining, code review remaining, usage breakdown).
            Auto falls back to Codex CLI only when cookies are missing.
          - Claude: claude.ai API.
            Auto falls back to Claude CLI only when cookies are missing.
          - Kilo: app.kilo.ai API.
            Auto falls back to Kilo CLI when API credentials are missing or unauthorized.
          Token accounts are loaded from the resolved ResearchBar config file.
          Use --account or --account-index to select a specific token account.
          Use --all-accounts to fetch every token account, or every visible Codex account for Codex.
          Account selection requires a single provider.

        Global flags:
          -h, --help      Show help
          -V, --version   Show version
          -v, --verbose   Enable verbose logging
          --no-color      Disable ANSI colors in text output
          --log-level <trace|verbose|debug|info|warning|error|critical>
          --json-output   Emit machine-readable logs (JSONL) to stderr

        Examples:
          researchbar usage
          researchbar usage --provider claude
          researchbar usage --provider gemini
          researchbar usage --format json --provider all --pretty
          researchbar usage --provider all --json
          researchbar usage --status
          researchbar usage --provider codex --source web --format json --pretty
        """
    }

    static func costHelp(version: String) -> String {
        """
        \(AppIdentity.displayName) \(version)

        Usage:
          researchbar cost [--format text|json]
                       [--json]
                       [--json-only]
                       [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>] [-v|--verbose]
                       [--provider \(ProviderHelp.list)]
                       [--no-color] [--pretty] [--refresh]

        Description:
          Print local token cost usage from Claude/Codex native logs plus supported pi sessions.
          This does not require web or CLI access and uses cached scan results unless --refresh is provided.

        Examples:
          researchbar cost
          researchbar cost --provider claude --format json --pretty
        """
    }

    static func serveHelp(version: String) -> String {
        """
        \(AppIdentity.displayName) \(version)

        Usage:
          researchbar serve [--port <port>] [--refresh-interval <seconds>]
                         [--request-timeout <seconds>]
                         [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>]
                         [-v|--verbose]

        Description:
          Start a foreground localhost-only HTTP server that exposes existing CLI JSON payloads.
          The server binds to 127.0.0.1 only in this initial version.

        Endpoints:
          GET /health
          GET /usage
          GET /usage?provider=claude
          GET /usage?provider=all
          GET /cost
          GET /cost?provider=codex

        Examples:
          researchbar serve
          researchbar serve --port 8080 --refresh-interval 60 --request-timeout 30
          curl http://127.0.0.1:8080/usage?provider=all
        """
    }

    static func configHelp(version: String) -> String {
        """
        \(AppIdentity.displayName) \(version)

        Usage:
          researchbar config validate [--format text|json]
                                 [--json]
                                 [--json-only]
                                 [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>]
                                 [-v|--verbose]
                                 [--pretty]
          researchbar config dump [--format text|json]
                             [--json]
                             [--json-only]
                             [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>]
                             [-v|--verbose]
                             [--pretty]
          researchbar config providers [--format text|json] [--json] [--json-only] [--pretty]
          researchbar config enable --provider <name> [--format text|json] [--json] [--json-only] [--pretty]
          researchbar config disable --provider <name> [--format text|json] [--json] [--json-only] [--pretty]
          researchbar config set-api-key --provider <name> (--api-key <key>|--stdin)
                                    [--no-enable]
                                    [--format text|json] [--json] [--json-only] [--pretty]

        Description:
          Validate or print the ResearchBar config file (default: validate).
          providers lists persistent provider enablement.
          enable/disable updates the same provider toggle used by Settings.
          set-api-key stores a provider API key in the resolved config file and enables that provider by default.

        Examples:
          researchbar config validate --format json --pretty
          researchbar config dump --pretty
          researchbar config providers
          researchbar config enable --provider grok
          researchbar config disable --provider cursor
          printf '%s' "$ELEVENLABS_API_KEY" | researchbar config set-api-key --provider elevenlabs --stdin
        """
    }

    static func cacheHelp(version: String) -> String {
        """
        \(AppIdentity.displayName) \(version)

        Usage:
          researchbar cache clear <--cookies|--cost|--all>
                              [--provider <name>]
                              [--format text|json]
                              [--json]
                              [--json-only]
                              [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>]
                              [-v|--verbose]
                              [--pretty]

        Description:
          Clear cached data. Use --cookies to clear browser cookie caches (stored in Keychain),
          --cost to clear cost usage scan caches, or --all for both.
          Optionally specify --provider with --cookies to clear cookies for a single provider only.

        Examples:
          researchbar cache clear --cookies
          researchbar cache clear --cookies --provider claude
          researchbar cache clear --cost
          researchbar cache clear --all
          researchbar cache clear --all --format json --pretty
        """
    }

    static func diagnoseHelp(version: String) -> String {
        """
        \(AppIdentity.displayName) \(version)

        Usage:
          researchbar diagnose --provider <name|all> --format json
                           [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>]
                           [-v|--verbose]
                           [--pretty]

        Description:
          Run provider diagnostic fetches and print a safe JSON export for issue reporting.
          The export is redacted and omits raw API tokens, cookies, auth headers, emails,
          account IDs, org IDs, raw responses, and billing-history records.

        Examples:
          researchbar diagnose --provider minimax --format json --pretty
          researchbar diagnose --provider claude --format json --pretty
          researchbar diagnose --provider all --format json
        """
    }

    static func rootHelp(version: String) -> String {
        """
        \(AppIdentity.displayName) \(version)

        Usage:
          researchbar [--format text|json]
                  [--json]
                  [--json-only]
                  [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>] [-v|--verbose]
                  [--provider \(ProviderHelp.list)]
                  [--account <label>] [--account-index <index>] [--all-accounts]
                  [--no-credits] [--no-color] [--pretty] [--status] [--source <auto|web|cli|oauth|api>]
                  [--web-timeout <seconds>] [--web-debug-dump-html] [--antigravity-plan-debug] [--augment-debug]
          researchbar cost [--format text|json]
                       [--json]
                       [--json-only]
                       [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>] [-v|--verbose]
                       [--provider \(ProviderHelp.list)] [--no-color] [--pretty] [--refresh]
          researchbar serve [--port <port>] [--refresh-interval <seconds>]
                       [--request-timeout <seconds>]
                       [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>] [-v|--verbose]
          researchbar config <validate|dump|providers> [--format text|json]
                                        [--json]
                                        [--json-only]
                                        [--json-output] [--log-level <trace|verbose|debug|info|warning|error|critical>]
                                        [-v|--verbose]
                                        [--pretty]
          researchbar config enable --provider <name>
          researchbar config disable --provider <name>
          researchbar config set-api-key --provider <name> (--api-key <key>|--stdin)
          researchbar cache clear <--cookies|--cost|--all> [--provider <name>]
          researchbar diagnose --provider <name|all> --format json [--pretty]

        Global flags:
          -h, --help      Show help
          -V, --version   Show version
          -v, --verbose   Enable verbose logging
          --no-color      Disable ANSI colors in text output
          --log-level <trace|verbose|debug|info|warning|error|critical>
          --json-output   Emit machine-readable logs (JSONL) to stderr

        Examples:
          researchbar
          researchbar --format json --provider all --pretty
          researchbar --provider all --json
          researchbar --provider gemini
          researchbar cost --provider claude --format json --pretty
          researchbar serve --port 8080
          researchbar config validate --format json --pretty
          researchbar config enable --provider grok
          researchbar config set-api-key --provider elevenlabs --stdin
          researchbar cache clear --cookies
          researchbar diagnose --provider minimax --format json --pretty
          researchbar diagnose --provider all --format json
        """
    }
}
