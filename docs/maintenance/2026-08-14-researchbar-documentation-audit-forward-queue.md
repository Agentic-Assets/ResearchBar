# Forward queue after ResearchBar documentation audit (2026-08-14)

Candidate follow-up work surfaced during the audit. This is a menu, not a roadmap; verify each item before acting.

## Correctness

- **Repair the Preferences CLI installer** (priority: high, confidence: verified gap)
  Align `PreferencesAdvancedPane` with the packaged `ResearchBarCLI` helper and `researchbar` command, then restore the in-app installer documentation. Until then, manual linking is the only supported documented path.

- **Reconcile CloudKit runtime and packaging** (priority: high, confidence: verified gap)
  ResearchBar runtime retains an inherited container identifier while packaging omits CloudKit entitlement for the ResearchBar bundle. Decide whether sync should be supported, then align source, entitlements, migration behavior, and release verification before claiming availability.

## Hardening

- **Add a contract-reference drift check** (priority: high, confidence: verified gap)
  The local Corbis integration guide drifted on transport, protocol, and production query-token behavior. Add a small source-backed check or refresh procedure tied to a recorded backend SHA so the guide cannot silently become unsafe again.

- **Add documentation assertions for packaged identities** (priority: medium, confidence: verified gap)
  Module names intentionally retain `CodexBar*` while app, helper, and widget names are ResearchBar. A lightweight check for the documented config, helper, widget, Sparkle-feed, and artifact values would prevent another broad doc audit.

## Process

- **Establish an owner/cadence for maintained cross-repo references** (priority: medium, confidence: verified gap)
  The Corbis guide is intentionally a local reference, not a symlink. Record a refresh owner and require source revalidation whenever the MCP contract changes or before a public release.
