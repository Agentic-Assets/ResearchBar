import CodexBarCore
import Foundation
import Testing

struct CorbisSettingsViewStateTests {
    // MARK: Token validation

    @Test
    func validTokenRequiresCorbisPrefixAndBody() {
        #expect(CorbisSettingsViewState.isValidToken("corbis_mcp_abcdef123456"))
        #expect(!CorbisSettingsViewState.isValidToken("corbis_mcp_"))
        #expect(!CorbisSettingsViewState.isValidToken("sk-live-abcdef"))
        #expect(!CorbisSettingsViewState.isValidToken(""))
        #expect(!CorbisSettingsViewState.isValidToken("   "))
    }

    @Test
    func tokenFieldValidityTrimsWhitespace() {
        let state = CorbisSettingsViewState(connectionState: .notConnected, tokenField: "  corbis_mcp_xyz789  ")
        #expect(state.isTokenFieldValid)
    }

    // MARK: Intents per connection state

    @Test
    func notConnectedOffersConnectAndClearCacheOnly() {
        let state = CorbisSettingsViewState(connectionState: .notConnected)
        #expect(state.availableIntents == [.connect, .clearCache])
        #expect(!state.availableIntents.contains(.unlink))
        #expect(!state.availableIntents.contains(.reconnect))
    }

    @Test
    func connectedOffersReconnectUnlinkAndClearCache() {
        let identity = CorbisAccountIdentity.make(accountID: "acct-1", token: "corbis_mcp_secret")
        let state = CorbisSettingsViewState(connectionState: .connected(identity))
        #expect(state.availableIntents.contains(.reconnect))
        #expect(state.availableIntents.contains(.unlink))
        #expect(state.availableIntents.contains(.clearCache))
        #expect(!state.availableIntents.contains(.connect))
    }

    @Test
    func invalidOffersReconnectUnlinkAndClearCache() {
        let state = CorbisSettingsViewState(connectionState: .invalid)
        #expect(state.availableIntents.contains(.reconnect))
        #expect(state.availableIntents.contains(.unlink))
        #expect(state.availableIntents.contains(.clearCache))
    }

    @Test
    func clearCacheIsAlwaysAvailable() {
        let identity = CorbisAccountIdentity.make(accountID: nil, token: "corbis_mcp_secret")
        let states: [CorbisConnectionState] = [.notConnected, .connecting, .connected(identity), .invalid]
        for connection in states {
            let state = CorbisSettingsViewState(connectionState: connection)
            #expect(state.availableIntents.contains(.clearCache))
        }
    }

    // MARK: Redacted summary

    @Test
    func summaryShowsDisplayEmailNeverTheToken() {
        let secretToken = "corbis_mcp_supersecrettoken"
        let identity = CorbisAccountIdentity.make(accountID: "acct-42", token: secretToken)
        let state = CorbisSettingsViewState(
            connectionState: .connected(identity),
            tokenField: secretToken,
            displayEmail: "dr.researcher@example.edu")
        #expect(state.accountSummary == "Connected as dr.researcher@example.edu")
        #expect(!state.accountSummary.contains(secretToken))
    }

    @Test
    func summaryDoesNotExposeAccountIDWhenNoEmail() {
        let identity = CorbisAccountIdentity.make(accountID: "acct-42", token: "corbis_mcp_secret")
        let state = CorbisSettingsViewState(connectionState: .connected(identity))
        #expect(state.accountSummary == "Connected to Corbis")
        #expect(!state.accountSummary.contains("acct-42"))
        #expect(!state.accountSummary.contains("corbis_mcp_secret"))
    }

    @Test
    func summaryNeverEchoesTokenForAnyState() {
        let secretToken = "corbis_mcp_tokendonotleak"
        let identity = CorbisAccountIdentity.make(accountID: "acct-7", token: secretToken)
        let states: [CorbisConnectionState] = [.notConnected, .connecting, .connected(identity), .invalid]
        for connection in states {
            let state = CorbisSettingsViewState(connectionState: connection, tokenField: secretToken)
            #expect(!state.accountSummary.contains(secretToken))
        }
    }
}
