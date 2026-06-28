import Foundation

public enum AppIdentity {
    public static let displayName = "ResearchBar"
    public static let bundleIdentifierBase = "com.corbis.researchbar"
    public static let legacyBundleIdentifierBase = "com.steipete.codexbar"
    public static let defaultTeamID = "Y5PE65HELJ"
    public static let teamIDInfoKey = "ResearchBarTeamID"

    public static let applicationSupportDirectoryName = "ResearchBar"
    public static let openAIDashboardCacheDirectoryName = "com.corbis.researchbar"
    public static let fileLogDirectoryName = "ResearchBar"
    public static let fileLogFilename = "ResearchBar.log"
    public static let logSubsystemBase = "com.corbis.researchbar"

    public static let configPathEnvironmentKey = "RESEARCHBAR_CONFIG"
    public static let legacyConfigPathEnvironmentKey = "CODEXBAR_CONFIG"
    public static let xdgConfigDirectoryName = "researchbar"
    public static let legacyXDGConfigDirectoryName = "codexbar"
    public static let legacyDotConfigDirectoryName = ".codexbar"

    public static let keychainCacheService = "com.corbis.researchbar.cache"
    public static let keychainCacheLabel = "ResearchBar Cache"
    public static let keychainSecretsService = "com.corbis.researchbar"
    public static let keychainSecretsLabel = "ResearchBar"

    public static let legacyReleaseGroupID = "group.com.steipete.codexbar"
    public static let legacyDebugGroupID = "group.com.steipete.codexbar.debug"

    public static func groupID(teamID: String, bundleID: String?) -> String {
        let base = "\(teamID).\(self.bundleIdentifierBase)"
        return self.isDebugBundleID(bundleID) ? "\(base).debug" : base
    }

    public static func legacyGroupID(bundleID: String?) -> String {
        self.isDebugBundleID(bundleID) ? self.legacyDebugGroupID : self.legacyReleaseGroupID
    }

    public static func isDebugBundleID(_ bundleID: String?) -> Bool {
        guard let bundleID, !bundleID.isEmpty else { return false }
        return bundleID.contains(".debug")
    }
}
