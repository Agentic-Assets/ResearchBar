import Foundation

enum MenuBarStatusItemDefaultsRepair {
    static let didRepairKey = "hasRepairedHiddenStatusItemVisibilityDefaults"
    static let didRepairResearchBarLegacyItemKey = "hasRepairedResearchBarLegacyItemVisibility"
    private static let visibilityPrefix = "NSStatusItem VisibleCC "
    private static let repairableAutosavePrefixes = ["codexbar-", "researchbar-"]

    static func repairHiddenVisibilityDefaultsIfNeeded(defaults: UserDefaults) -> [String] {
        guard !defaults.bool(forKey: self.didRepairKey) else { return [] }

        let repairedKeys = defaults.dictionaryRepresentation().keys
            .filter { key in
                self.shouldRepair(key: key, value: defaults.object(forKey: key))
            }
            .sorted()

        for key in repairedKeys {
            defaults.removeObject(forKey: key)
        }
        defaults.set(true, forKey: self.didRepairKey)
        return repairedKeys
    }

    static func repairResearchBarLegacyItemVisibilityIfNeeded(defaults: UserDefaults) -> [String] {
        guard !defaults.bool(forKey: self.didRepairResearchBarLegacyItemKey) else { return [] }

        let key = "\(self.visibilityPrefix)Item-0"
        let repairedKeys = self.isFalse(defaults.object(forKey: key)) ? [key] : []
        for key in repairedKeys {
            defaults.removeObject(forKey: key)
        }
        defaults.set(true, forKey: self.didRepairResearchBarLegacyItemKey)
        return repairedKeys
    }

    static func shouldRepair(key: String, value: Any?) -> Bool {
        guard key.hasPrefix(self.visibilityPrefix), self.isFalse(value) else { return false }
        let itemName = String(key.dropFirst(self.visibilityPrefix.count))
        return self.repairableAutosavePrefixes.contains { itemName.hasPrefix($0) }
            || self.isDefaultStatusItemName(itemName)
    }

    private static func isDefaultStatusItemName(_ itemName: String) -> Bool {
        guard itemName.hasPrefix("Item-") else { return false }
        return itemName.dropFirst("Item-".count).allSatisfy(\.isNumber)
    }

    private static func isFalse(_ value: Any?) -> Bool {
        switch value {
        case let number as NSNumber:
            !number.boolValue
        case let bool as Bool:
            !bool
        default:
            false
        }
    }
}
