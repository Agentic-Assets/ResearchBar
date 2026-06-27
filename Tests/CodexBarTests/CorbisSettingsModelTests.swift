import Testing
@testable import CodexBar

@MainActor
struct CorbisSettingsModelTests {
    @Test
    func connectPassesTrimmedTokenToCallback() {
        let model = CorbisSettingsModel()
        model.tokenField = "  corbis_mcp_abcdef123  "
        var received: String?
        model.onConnect = { token in
            received = token
        }

        model.connect()

        #expect(received == "corbis_mcp_abcdef123")
    }
}
