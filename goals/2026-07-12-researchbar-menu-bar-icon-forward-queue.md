# Forward queue after ResearchBar menu-bar icon work, 2026-07-12

Candidate work surfaced during this session. This is a menu, not a roadmap.

## Evaluation

- **Complete the no-prompt visual proof** (priority: high, confidence: verified gap)
  Launch the freshly packaged app with the no-UI credential gate, confirm ResearchBar is enabled in macOS Menu Bar settings under `Allow in the Menu Bar`, then capture the cap before interaction, record the active display and status-item bounds, and open the attached menu from that item.

## Robustness

- **Make startup credential prompts observable and avoidable in UI verification** (priority: high, confidence: verified gap)
  The fresh bundle displayed a Keychain prompt before visibility could be inspected. Add or document a test-only startup configuration that guarantees `KeychainNoUIQuery` compatible behavior without changing production credential policy.

## Hardening

- **Add a focused owner-shutdown assertion** (priority: medium, confidence: hypothesis)
  The current generic shutdown suite covers status-item cleanup, and the branch removes the ResearchBar placement sentinel during shutdown. A ResearchBar-owner-specific test would confirm that the sentinel and merged item are both removed without affecting normal provider lifecycle coverage.

- **Capture the placement sentinel in live diagnostics** (priority: low, confidence: hypothesis)
  The sentinel is intentionally excluded from current visibility snapshots. If live placement diagnosis remains difficult after no-prompt verification, add an explicit diagnostic record that distinguishes the visible cap item from the one-point placement helper.

- **Document the app-group approval prerequisite for fresh local verification** (priority: high, confidence: verified gap)
  After the legacy visibility migration persisted `researchbar-merged = 1`, a fresh app launch prompted for macOS access to data from other apps. That approval has now been accepted. The remaining admission control is macOS Menu Bar settings, where ResearchBar must appear under and be enabled in `Allow in the Menu Bar` before visual proof is possible.
