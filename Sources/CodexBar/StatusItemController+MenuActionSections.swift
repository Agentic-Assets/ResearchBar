import AppKit
import CodexBarCore

extension StatusItemController {
    func addActionableSections(
        _ sections: [MenuDescriptor.Section],
        to menu: NSMenu,
        width: CGFloat,
        captureMenu: NSMenu? = nil,
        excluding excludedActions: [MenuDescriptor.MenuAction] = [])
    {
        let actionableSections = self.actionableSections(sections, excluding: excludedActions)
        for (index, section) in actionableSections.enumerated() {
            for entry in section.entries {
                self.addActionableEntry(entry, to: menu, width: width, captureMenu: captureMenu)
            }
            if index < actionableSections.count - 1 {
                menu.addItem(.separator())
            }
        }
    }

    private func actionableSections(
        _ sections: [MenuDescriptor.Section],
        excluding excludedActions: [MenuDescriptor.MenuAction]) -> [MenuDescriptor.Section]
    {
        sections.map { section in
            MenuDescriptor.Section(entries: section.entries.filter { entry in
                guard case let .action(_, action) = entry else { return true }
                return !excludedActions.contains(action)
            })
        }.filter { section in
            section.entries.contains { entry in
                if case .action = entry { return true }
                if case .submenu = entry { return true }
                if case .unavailable = entry { return true }
                return false
            }
        }
    }

    private func addActionableEntry(
        _ entry: MenuDescriptor.Entry,
        to menu: NSMenu,
        width: CGFloat,
        captureMenu: NSMenu?)
    {
        switch entry {
        case let .text(text, style):
            self.addActionableTextItem(text, style: style, to: menu, width: width)
        case let .action(title, action):
            self.addActionableMenuItem(title, action: action, to: menu, width: width, captureMenu: captureMenu)
        case let .unavailable(title, message):
            self.addActionableTextItem(title, style: .headline, to: menu, width: width)
            if let message, !message.isEmpty {
                self.addActionableTextItem(message, style: .secondary, to: menu, width: width)
            }
        case let .submenu(title, systemImageName, submenuItems):
            menu.addItem(self.makeActionableSubmenuItem(
                title: title,
                systemImageName: systemImageName,
                submenuItems: submenuItems))
        case .divider:
            menu.addItem(.separator())
        }
    }

    private func addActionableTextItem(
        _ text: String,
        style: MenuDescriptor.TextStyle,
        to menu: NSMenu,
        width: CGFloat)
    {
        if style == .secondary {
            menu.addItem(self.makeWrappedSecondaryTextItem(text: text, width: width))
            return
        }
        let item = NSMenuItem(title: text, action: nil, keyEquivalent: "")
        item.isEnabled = false
        if style == .headline {
            let font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
            item.attributedTitle = NSAttributedString(string: text, attributes: [.font: font])
        }
        menu.addItem(item)
    }

    private func addActionableMenuItem(
        _ title: String,
        action: MenuDescriptor.MenuAction,
        to menu: NSMenu,
        width: CGFloat,
        captureMenu: NSMenu?)
    {
        let localizedTitle = L(title)
        _ = width
        _ = captureMenu
        menu.addItem(self.makeActionableMenuItem(title: localizedTitle, action: action))
    }

    private func makeActionableMenuItem(
        title: String,
        action: MenuDescriptor.MenuAction) -> NSMenuItem
    {
        let (selector, represented) = self.selector(for: action)
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        item.representedObject = represented
        if let shortcut = self.shortcut(for: action) {
            item.keyEquivalent = shortcut.key
            item.keyEquivalentModifierMask = shortcut.modifiers
        }
        self.applyActionIcon(for: action, to: item)
        self.applyActionAvailability(for: action, to: item, title: title)
        return item
    }

    private func applyActionIcon(for action: MenuDescriptor.MenuAction, to item: NSMenuItem) {
        guard let iconName = action.systemImageName,
              let image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
        else {
            return
        }
        image.isTemplate = true
        image.size = NSSize(width: 16, height: 16)
        item.image = image
    }

    private func applyActionAvailability(
        for action: MenuDescriptor.MenuAction,
        to item: NSMenuItem,
        title: String)
    {
        if case let .switchAccount(targetProvider) = action,
           let subtitle = self.switchAccountSubtitle(for: targetProvider)
        {
            item.isEnabled = false
            self.applySubtitle(subtitle, to: item, title: title)
        } else if case .addCodexAccount = action,
                  let subtitle = self.codexAddAccountSubtitle()
        {
            item.isEnabled = false
            self.applySubtitle(subtitle, to: item, title: title)
        }
    }

    private func makeActionableSubmenuItem(
        title: String,
        systemImageName: String?,
        submenuItems: [MenuDescriptor.SubmenuItem]) -> NSMenuItem
    {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        if let systemImageName,
           let image = NSImage(systemSymbolName: systemImageName, accessibilityDescription: nil)
        {
            image.isTemplate = true
            image.size = NSSize(width: 16, height: 16)
            item.image = image
        }
        let submenu = NSMenu(title: title)
        submenu.autoenablesItems = false
        for submenuItem in submenuItems {
            submenu.addItem(self.makeActionableSubmenuChild(submenuItem))
        }
        item.submenu = submenu
        return item
    }

    private func makeActionableSubmenuChild(_ submenuItem: MenuDescriptor.SubmenuItem) -> NSMenuItem {
        let child = NSMenuItem(title: submenuItem.title, action: nil, keyEquivalent: "")
        child.state = submenuItem.isChecked ? .on : .off
        child.isEnabled = submenuItem.isEnabled
        if let action = submenuItem.action {
            let (selector, represented) = self.selector(for: action)
            child.action = selector
            child.target = self
            child.representedObject = represented
        }
        return child
    }
}
