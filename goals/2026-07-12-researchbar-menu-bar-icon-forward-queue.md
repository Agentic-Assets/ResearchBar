# Forward queue after ResearchBar menu-bar icon work, 2026-07-12

Candidate work surfaced during this session. This is a menu, not a roadmap.

## Evaluation

- **Complete the no-prompt visual proof** (priority: high, confidence: verified gap)
  Launch the freshly packaged app in an environment where the Corbis and provider startup paths use no-UI credential access. Capture the cap before interaction, record the active display and status-item bounds, then open the attached menu and capture it from the same item.

## Robustness

- **Make startup credential prompts observable and avoidable in UI verification** (priority: high, confidence: verified gap)
  The fresh bundle displayed a Keychain prompt before visibility could be inspected. Add or document a test-only startup configuration that guarantees `KeychainNoUIQuery` compatible behavior without changing production credential policy.

## Hardening

- **Add a focused owner-shutdown assertion** (priority: medium, confidence: hypothesis)
  The current generic shutdown suite covers status-item cleanup, and the branch removes the ResearchBar placement sentinel during shutdown. A ResearchBar-owner-specific test would confirm that the sentinel and merged item are both removed without affecting normal provider lifecycle coverage.

- **Capture the placement sentinel in live diagnostics** (priority: low, confidence: hypothesis)
  The sentinel is intentionally excluded from current visibility snapshots. If live placement diagnosis remains difficult after no-prompt verification, add an explicit diagnostic record that distinguishes the visible cap item from the one-point placement helper.
