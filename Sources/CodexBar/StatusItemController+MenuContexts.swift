import AppKit
import CodexBarCore

extension StatusItemController {
    struct OpenAIWebContext {
        let hasUsageBreakdown: Bool
        let hasCreditsHistory: Bool
        let hasCostHistory: Bool
        let canShowBuyCredits: Bool
        let hasOpenAIWebMenuItems: Bool
    }

    struct MenuCardContext {
        let currentProvider: UsageProvider
        let selectedProvider: UsageProvider?
        let menuWidth: CGFloat
        let codexAccountDisplay: CodexAccountMenuDisplay?
        let tokenAccountDisplay: TokenAccountMenuDisplay?
        let openAIContext: OpenAIWebContext
    }

    struct MenuRebuildContext {
        let enabledProviders: [UsageProvider]
        let includesOverview: Bool
        let includesResearchBar: Bool
        let switcherSelection: ProviderSwitcherSelection?
        let currentProvider: UsageProvider
        let selectedProvider: UsageProvider?
        let menuWidth: CGFloat
        let codexAccountDisplay: CodexAccountMenuDisplay?
        let tokenAccountDisplay: TokenAccountMenuDisplay?
        let openAIContext: OpenAIWebContext
        let descriptor: MenuDescriptor
    }

    struct MenuPopulationContext {
        let enabledProviders: [UsageProvider]
        let includesOverview: Bool
        let includesResearchBar: Bool
        let showsMergedProviderSwitcher: Bool
        let switcherSelection: ProviderSwitcherSelection?
        let isOverviewSelected: Bool
        let isResearchBarSelected: Bool
        let selectedProvider: UsageProvider?
        let currentProvider: UsageProvider
        let codexAccountDisplay: CodexAccountMenuDisplay?
        let tokenAccountDisplay: TokenAccountMenuDisplay?
        let openAIContext: OpenAIWebContext
        let descriptor: MenuDescriptor
        let menuWidth: CGFloat
    }
}
