import CodexBarCore
import SwiftUI

// MARK: - CorbisSettingsModel

/// Observable wrapper around the pure `CorbisSettingsViewState`. Owns the editable token
/// field and the resolved connection state; intent callbacks are injected so the view stays
/// free of network and Keychain work.
@MainActor
@Observable
final class CorbisSettingsModel {
    var tokenField: String = ""
    var connectionState: CorbisConnectionState
    var displayEmail: String?

    var onConnect: (String) -> Void = { _ in }
    var onUnlink: () -> Void = {}
    var onClearCache: () -> Void = {}

    init(connectionState: CorbisConnectionState = .notConnected, displayEmail: String? = nil) {
        self.connectionState = connectionState
        self.displayEmail = displayEmail
    }

    /// The pure state derived from the current fields.
    var state: CorbisSettingsViewState {
        CorbisSettingsViewState(
            connectionState: self.connectionState,
            tokenField: self.tokenField,
            displayEmail: self.displayEmail)
    }

    func connect() {
        guard self.state.isTokenFieldValid else { return }
        self.onConnect(self.tokenField)
    }

    func unlink() {
        self.onUnlink()
    }

    func clearCache() {
        self.onClearCache()
    }
}

// MARK: - CorbisSettingsView

/// Native settings surface for the Corbis research connection. Lets the researcher paste a
/// `corbis_mcp_` token, connect/reconnect/unlink, and clear the cached pulse, with a
/// redacted connection diagnostics line.
@MainActor
struct CorbisSettingsView: View {
    @Bindable var model: CorbisSettingsModel

    var body: some View {
        let state = self.model.state
        VStack(alignment: .leading, spacing: 14) {
            Text("Research connection")
                .font(.title3)
                .bold()

            Text(state.accountSummary)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Corbis MCP token")
                    .font(.subheadline)
                SecureField("corbis_mcp_…", text: self.$model.tokenField)
                    .textFieldStyle(.roundedBorder)
                if !self.model.tokenField.isEmpty, !state.isTokenFieldValid {
                    Text("Token must start with \(CorbisSettingsViewState.tokenPrefix)")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            HStack(spacing: 10) {
                if state.availableIntents.contains(.connect) {
                    Button("Connect") { self.model.connect() }
                        .disabled(!state.isTokenFieldValid)
                }
                if state.availableIntents.contains(.reconnect) {
                    Button("Reconnect") { self.model.connect() }
                        .disabled(!state.isTokenFieldValid)
                }
                if state.availableIntents.contains(.unlink) {
                    Button("Unlink") { self.model.unlink() }
                }
                if state.availableIntents.contains(.clearCache) {
                    Button("Clear cache") { self.model.clearCache() }
                }
            }

            Text(self.diagnostics(for: state))
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func diagnostics(for state: CorbisSettingsViewState) -> String {
        switch state.connectionState {
        case .notConnected:
            "Paste your Corbis MCP token to start tracking your research pulse."
        case .connecting:
            "Validating your connection…"
        case .connected:
            "Connection healthy. Pulse refreshes on menu open and manual refresh."
        case .invalid:
            "The stored token was rejected. Reconnect with a fresh token."
        }
    }
}
