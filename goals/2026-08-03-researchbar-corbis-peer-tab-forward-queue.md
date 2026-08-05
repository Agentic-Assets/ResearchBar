# ResearchBar Corbis peer tab forward queue

Date: 2026-08-03

## Follow-up visual validation

Under explicit authorization, launch the freshly packaged bundle with
`./Scripts/launch.sh` and verify the compact four-tab rail in the target macOS
environment. Capture a screenshot at the normal menu-bar scale and confirm that
the Corbis label is legible, the row does not wrap, and switching tabs does not
resize the menu unexpectedly.

## Follow-up product decision

The selected tab is intentionally process-local. Decide separately whether the
Corbis selection should persist across an app restart. Persistence should be
implemented only if it is useful across the broader provider switcher, rather
than as a Corbis-only preference.

## Regression watch

When adding a provider or changing the compact switcher width, preserve the
single-row peer-tab contract and extend `ResearchBarTabSwitcherTests` for the new
layout. When adding a Corbis action, keep it isolated to the Corbis tab and
retain the global Settings, About, and Quit actions.
