import AppKit
import CodexBarCore

extension StatusItemController {
    /// Seed the no-credit launch state so the always-visible status-item tooltip is correct
    /// from launch and the first menu open builds with the right input instead of the
    /// `.notConnected` default. `currentMenuInput()` reads only the credential and cache, so
    /// this never spends a credit or touches the network.
    func seedResearchPulseLaunchState() {
        guard !SettingsStore.isRunningTests else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let input = await self.researchPulseRefreshCoordinator.currentMenuInput()
            self.applyResearchPulseMenuInput(input, openMenu: nil)
        }
    }

    func refreshResearchPulseForMenuOpen(_ menu: NSMenu) {
        Task { @MainActor [weak self, weak menu] in
            guard let self else { return }
            let input = await self.researchPulseRefreshCoordinator.refreshOnMenuOpen()
            self.applyResearchPulseMenuInput(input, openMenu: menu)
        }
    }

    @objc func refreshResearchPulseNow() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            let input = await self.researchPulseRefreshCoordinator.manualRefresh()
            self.applyResearchPulseMenuInput(input, openMenu: self.mergedMenu)
        }
    }

    @objc func openResearchBarCorbisHome() {
        NSWorkspace.shared.open(Self.corbisHomeURL)
    }

    @objc func openResearchBarProfileLink(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func clearResearchPulseCache() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.researchPulseCache.clearAll()
            let input = await self.researchPulseRefreshCoordinator.currentMenuInput()
            self.applyResearchPulseMenuInput(input, openMenu: self.mergedMenu)
        }
    }

    func addResearchBarMenuContent(to menu: NSMenu, width _: CGFloat) {
        let sections = ResearchPulseMenuFactory.makeHostMenuSections(from: self.researchPulseMenuInput)
        guard !sections.isEmpty else { return }

        self.addResearchBarHeader(to: menu)
        for section in sections {
            if let title = section.title {
                menu.addItem(self.makeResearchBarTextItem(title: title, emphasized: true))
            }
            for item in section.items {
                menu.addItem(self.makeResearchBarMenuItem(item))
            }
        }
        menu.addItem(.separator())
    }

    private static let corbisHomeURL = URL(string: "https://www.corbis.ai")!

    private func applyResearchPulseMenuInput(_ input: ResearchPulseMenuInput, openMenu menu: NSMenu?) {
        guard input != self.researchPulseMenuInput else {
            self.updateResearchBarStatusAccessibility()
            return
        }
        self.researchPulseMenuInput = input
        self.updateResearchBarStatusAccessibility()
        if let menu, self.openMenus[ObjectIdentifier(menu)] != nil {
            self.refreshOpenMenuIfStillVisible(menu, provider: self.menuProvider(for: menu))
        } else {
            self.invalidateMenus()
        }
    }

    func updateResearchBarStatusAccessibility() {
        let model = ResearchPulseStatusIconModel.make(from: self.researchPulseMenuInput)
        guard let button = self.statusItem.button else { return }
        button.setAccessibilityValue(model.accessibilityValue)
        button.toolTip = "ResearchBar: \(model.accessibilityValue)"
    }

    private func addResearchBarHeader(to menu: NSMenu) {
        let item = self.makeResearchBarTextItem(title: "ResearchBar", emphasized: true)
        if let image = NSImage(systemSymbolName: "graduationcap", accessibilityDescription: nil) {
            image.isTemplate = true
            image.size = NSSize(width: 16, height: 16)
            item.image = image
        }
        menu.addItem(item)
    }

    private func makeResearchBarMenuItem(_ item: ResearchBarMenuItem) -> NSMenuItem {
        switch item.kind {
        case .header:
            self.makeResearchBarTextItem(title: item.title, emphasized: true)
        case .info, .notice, .trend:
            self.makeResearchBarTextItem(title: item.title, emphasized: false)
        case let .action(action):
            self.makeResearchBarActionItem(title: item.title, action: action)
        }
    }

    private func makeResearchBarTextItem(title: String, emphasized: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        if emphasized {
            item.attributedTitle = NSAttributedString(
                string: title,
                attributes: [.font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)])
        } else {
            item.attributedTitle = NSAttributedString(
                string: title,
                attributes: [.foregroundColor: NSColor.secondaryLabelColor])
        }
        return item
    }

    private func makeResearchBarActionItem(title: String, action: ResearchBarMenuAction) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.target = self
        switch action {
        case .refresh:
            item.action = #selector(self.refreshResearchPulseNow)
            item.keyEquivalent = "r"
            item.keyEquivalentModifierMask = [.command, .option]
        case .connect, .reconnect, .reviewIdentity:
            item.action = #selector(self.showSettingsResearch)
        case .openCorbis:
            item.action = #selector(self.openResearchBarCorbisHome)
        case let .openProfileLink(url):
            item.action = #selector(self.openResearchBarProfileLink(_:))
            item.representedObject = url
        case .openSettings:
            item.action = #selector(self.showSettingsResearch)
        case .clearCache:
            item.action = #selector(self.clearResearchPulseCache)
        case .quit:
            item.action = #selector(self.quit)
        }
        return item
    }
}
