import AppKit
import CodexBarCore
import Testing
@testable import CodexBar

@MainActor
@Suite(.serialized)
struct ResearchBarTabSwitcherTests {
    @Test
    func corbisIsAFourthPeerOnTheCompactSingleRowRail() {
        var selections: [ProviderSwitcherSelection] = []
        let switcher = ProviderSwitcherView(
            providers: [.codex, .claude],
            selected: .provider(.codex),
            includesOverview: true,
            includesResearchBar: true,
            width: StatusItemController.menuCardBaseWidth,
            showsIcons: true,
            iconProvider: { _ in NSImage() },
            weeklyRemainingProvider: { _ in nil },
            onSelect: { selections.append($0) })

        switcher.layoutSubtreeIfNeeded()
        let buttons = switcher.subviews.compactMap { $0 as? NSButton }.sorted { $0.tag < $1.tag }

        #expect(buttons.count == 4)
        #expect(buttons.map(\.title) == ["Overview", "Codex", "Claude", "Corbis"])
        #expect(abs(switcher.frame.height - 30) <= 0.5)
        #expect(switcher._test_simulateRuntimeClick(buttonTag: 3))
        #expect(selections == [.researchBar])
    }

    @Test
    func corbisRefreshIsGatedToTheSelectedTabAndProviderContentStaysSeparate() async throws {
        let previousOwnerOverride = StatusItemController.researchBarStatusItemOwnerOverrideForTesting
        let previousMenuCardRendering = StatusItemController.menuCardRenderingEnabled
        let previousMenuRefresh = StatusItemController.menuRefreshEnabled
        StatusItemController.researchBarStatusItemOwnerOverrideForTesting = true
        StatusItemController.menuCardRenderingEnabled = false
        StatusItemController.setMenuRefreshEnabledForTesting(false)
        defer {
            StatusItemController.researchBarStatusItemOwnerOverrideForTesting = previousOwnerOverride
            StatusItemController.menuCardRenderingEnabled = previousMenuCardRendering
            StatusItemController.setMenuRefreshEnabledForTesting(previousMenuRefresh)
        }

        let settings = self.makeSettings()
        settings.mergeIcons = true
        let registry = ProviderRegistry.shared
        for provider in UsageProvider.allCases {
            guard let metadata = registry.metadata[provider] else { continue }
            settings.setProviderEnabled(
                provider: provider,
                metadata: metadata,
                enabled: provider == .codex || provider == .claude)
        }
        settings.setMergedOverviewProviderSelection(
            provider: .codex,
            isSelected: true,
            activeProviders: [.codex, .claude])
        settings.setMergedOverviewProviderSelection(
            provider: .claude,
            isSelected: true,
            activeProviders: [.codex, .claude])
        let fetcher = UsageFetcher()
        let controller = StatusItemController(
            store: UsageStore(
                fetcher: fetcher,
                browserDetection: BrowserDetection(cacheTTL: 0),
                settings: settings),
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: .system)
        defer { controller.releaseStatusItemsForTesting() }

        let providers: [UsageProvider] = [.codex, .claude]
        #expect(!controller.shouldRefreshResearchPulseForMenuOpen(enabledProviders: providers))

        let pulse = try ResearchBarFixtures.pulse("pulse-linked-tracked")
        controller.researchPulseMenuInput = .loaded(pulse: pulse, fromStaleCache: false)

        let menu = try #require(controller.makeMenu() as? StatusItemMenu)
        controller.populateMenu(menu, provider: .codex)
        let providerSwitcher = try #require(menu.items.first?.view as? ProviderSwitcherView)
        #expect(abs(providerSwitcher.frame.width - StatusItemController.menuCardBaseWidth) <= 0.5)
        #expect(!menu.items.contains { $0.title == "ResearchBar" })
        #expect(try controller.handleProviderSwitcherShortcut(Self.commandKeyEvent("4", keyCode: 21), menu: menu))

        #expect(controller.shouldRefreshResearchPulseForMenuOpen(enabledProviders: providers))
        controller.populateMenu(menu, provider: .codex)
        let corbisSwitcher = try #require(menu.items.first?.view as? ProviderSwitcherView)
        #expect(abs(corbisSwitcher.frame.width - StatusItemController.menuCardBaseWidth) <= 0.5)
        #expect(menu.items.contains { $0.title == "ResearchBar" })
        #expect(controller.renderedProviders(for: menu).isEmpty)
        #expect(menu.items.contains { $0.title == "Settings..." })
        #expect(menu.items.contains { $0.title == "About ResearchBar" })
        #expect(menu.items.contains { $0.title == "Quit" })
        let refreshItems = menu.items.filter { $0.title == "Refresh" }
        #expect(refreshItems.count == 1)
        #expect(refreshItems.first?.action == #selector(StatusItemController.refreshResearchPulseNow))

        var providerRefreshes = 0
        var corbisRefreshes = 0
        controller._test_manualRefreshOperation = { providerRefreshes += 1 }
        controller._test_researchPulseManualRefreshOperation = { corbisRefreshes += 1 }
        #expect(try menu.performKeyEquivalent(with: Self.commandKeyEvent("r", keyCode: 15)))
        for _ in 0..<10 where corbisRefreshes == 0 {
            await Task.yield()
        }
        #expect(corbisRefreshes == 1)
        #expect(providerRefreshes == 0)

        controller.selectProviderOrOverviewTab()
        #expect(!controller.shouldRefreshResearchPulseForMenuOpen(enabledProviders: providers))
        controller.populateMenu(menu, provider: .codex)
        #expect(!menu.items.contains { $0.title == "ResearchBar" })
    }

    @Test
    func corbisRemainsReachableWithoutProvidersAndAsTheSecondPeerTab() throws {
        let previousOwnerOverride = StatusItemController.researchBarStatusItemOwnerOverrideForTesting
        let previousMenuCardRendering = StatusItemController.menuCardRenderingEnabled
        let previousMenuRefresh = StatusItemController.menuRefreshEnabled
        StatusItemController.researchBarStatusItemOwnerOverrideForTesting = true
        StatusItemController.menuCardRenderingEnabled = false
        StatusItemController.setMenuRefreshEnabledForTesting(false)
        defer {
            StatusItemController.researchBarStatusItemOwnerOverrideForTesting = previousOwnerOverride
            StatusItemController.menuCardRenderingEnabled = previousMenuCardRendering
            StatusItemController.setMenuRefreshEnabledForTesting(previousMenuRefresh)
        }

        let settings = self.makeSettings()
        settings.mergeIcons = true
        let registry = ProviderRegistry.shared
        for provider in UsageProvider.allCases {
            guard let metadata = registry.metadata[provider] else { continue }
            settings.setProviderEnabled(provider: provider, metadata: metadata, enabled: false)
        }
        let fetcher = UsageFetcher()
        let controller = StatusItemController(
            store: UsageStore(
                fetcher: fetcher,
                browserDetection: BrowserDetection(cacheTTL: 0),
                settings: settings),
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: .system)
        defer { controller.releaseStatusItemsForTesting() }

        let menu = controller.makeMenu()
        controller.populateMenu(menu, provider: nil)
        #expect(!(menu.items.first?.view is ProviderSwitcherView))
        #expect(menu.items.contains { $0.title == "ResearchBar" })
        #expect(controller.renderedProviders(for: menu).isEmpty)

        let codexMetadata = try #require(registry.metadata[.codex])
        settings.setProviderEnabled(provider: .codex, metadata: codexMetadata, enabled: true)
        controller.selectProviderOrOverviewTab()
        controller.populateMenu(menu, provider: .codex)
        let switcher = try #require(menu.items.first?.view as? ProviderSwitcherView)
        #expect(switcher.subviews.compactMap { $0 as? NSButton }.count >= 2)

        controller.navigateProviderSwitcher(.next)
        #expect(controller.researchBarTabSelected)
        controller.populateMenu(menu, provider: .codex)
        #expect(menu.items.contains { $0.title == "ResearchBar" })

        controller.navigateProviderSwitcher(.next)
        #expect(!controller.researchBarTabSelected)
    }

    @Test
    func corbisPointerSelectionRebuildsOnlyAfterMouseUp() async throws {
        let previousOwnerOverride = StatusItemController.researchBarStatusItemOwnerOverrideForTesting
        let previousMenuCardRendering = StatusItemController.menuCardRenderingEnabled
        let previousMenuRefresh = StatusItemController.menuRefreshEnabled
        StatusItemController.researchBarStatusItemOwnerOverrideForTesting = true
        StatusItemController.menuCardRenderingEnabled = false
        StatusItemController.setMenuRefreshEnabledForTesting(false)
        defer {
            StatusItemController.researchBarStatusItemOwnerOverrideForTesting = previousOwnerOverride
            StatusItemController.menuCardRenderingEnabled = previousMenuCardRendering
            StatusItemController.setMenuRefreshEnabledForTesting(previousMenuRefresh)
        }

        let settings = self.makeSettings()
        settings.mergeIcons = true
        let registry = ProviderRegistry.shared
        for provider in UsageProvider.allCases {
            guard let metadata = registry.metadata[provider] else { continue }
            settings.setProviderEnabled(
                provider: provider,
                metadata: metadata,
                enabled: provider == .codex || provider == .claude)
        }
        settings.setMergedOverviewProviderSelection(
            provider: .codex,
            isSelected: true,
            activeProviders: [.codex, .claude])
        settings.setMergedOverviewProviderSelection(
            provider: .claude,
            isSelected: true,
            activeProviders: [.codex, .claude])

        let fetcher = UsageFetcher()
        let controller = StatusItemController(
            store: UsageStore(
                fetcher: fetcher,
                browserDetection: BrowserDetection(cacheTTL: 0),
                settings: settings),
            settings: settings,
            account: fetcher.loadAccountInfo(),
            updater: DisabledUpdaterController(),
            preferencesSelection: PreferencesSelection(),
            statusBar: .system)
        defer { controller.releaseStatusItemsForTesting() }

        let menu = controller.makeMenu()
        controller.populateMenu(menu, provider: .codex)
        controller.menuRefreshEnabledOverrideForTesting = true
        controller.openMenus[ObjectIdentifier(menu)] = menu
        let switcher = try #require(menu.items.first?.view as? ProviderSwitcherView)
        let mouseDown = try #require(switcher._test_mouseDownEvent(buttonTag: 3))
        let mouseUp = try #require(switcher._test_mouseUpEvent(buttonTag: 3))
        var rebuildCount = 0
        var corbisOpenRefreshes = 0
        controller._test_openMenuRebuildObserver = { _ in rebuildCount += 1 }
        controller._test_researchPulseMenuOpenRefreshOperation = { corbisOpenRefreshes += 1 }
        defer {
            controller._test_openMenuRebuildObserver = nil
            controller._test_researchPulseMenuOpenRefreshOperation = nil
        }

        #expect(controller.handleProviderSwitcherTrackingEvent(mouseDown, menu: menu))
        #expect(!controller.researchBarTabSelected)
        #expect(rebuildCount == 0)

        #expect(controller.handleProviderSwitcherTrackingEvent(mouseUp, menu: menu))
        #expect(controller.researchBarTabSelected)
        for _ in 0..<100 where rebuildCount == 0 {
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(rebuildCount == 1)
        #expect(corbisOpenRefreshes == 1)
        #expect(menu.items.contains { $0.title == "ResearchBar" })
        #expect(controller.renderedProviders(for: menu).isEmpty)
    }

    private func makeSettings() -> SettingsStore {
        let suite = "ResearchBarTabSwitcherTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return SettingsStore(
            userDefaults: defaults,
            configStore: testConfigStore(suiteName: suite),
            zaiTokenStore: NoopZaiTokenStore(),
            syntheticTokenStore: NoopSyntheticTokenStore())
    }

    private static func commandKeyEvent(_ characters: String, keyCode: UInt16) throws -> NSEvent {
        try #require(NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.command],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: characters,
            charactersIgnoringModifiers: characters,
            isARepeat: false,
            keyCode: keyCode))
    }
}
