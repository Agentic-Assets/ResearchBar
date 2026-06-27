import CodexBarCore
import Foundation

// MARK: - Render model

/// A single rendered ResearchBar menu item. Self-contained: it carries a
/// `ResearchBarMenuAction` directly rather than bridging through `MenuDescriptor.MenuAction`,
/// so the inherited CodexBar quota menu (`MenuDescriptor` / `MenuContent` / `MenuActions`)
/// is left untouched.
struct ResearchBarMenuItem: Equatable {
    enum Kind: Equatable {
        case header
        case info
        case notice
        /// A compact textual trend summary. Never a fabricated zero.
        case trend
        case action(ResearchBarMenuAction)
    }

    let title: String
    let kind: Kind
}

/// One section of the rendered ResearchBar menu.
struct ResearchBarMenuRenderSection: Equatable {
    let title: String?
    let items: [ResearchBarMenuItem]
}

// MARK: - ResearchPulseMenuFactory

/// Builds the renderable ResearchBar menu from the (already tested) Core
/// `ResearchPulseMenuModel`. The factory only maps row kinds to display items; all product
/// rules (no zeroed metrics, no fabricated trends, no leaked ids/backends) are enforced
/// upstream in the Core model and preserved here verbatim.
enum ResearchPulseMenuFactory {
    static func makeSections(from input: ResearchPulseMenuInput) -> [ResearchBarMenuRenderSection] {
        self.makeSections(from: ResearchPulseMenuModel.make(from: input))
    }

    static func makeSections(from model: ResearchPulseMenuModel) -> [ResearchBarMenuRenderSection] {
        model.sections.map { section in
            ResearchBarMenuRenderSection(
                title: section.title,
                items: section.rows.compactMap(self.item(for:)))
        }
    }

    // MARK: Row mapping

    private static func item(for row: ResearchMenuRow) -> ResearchBarMenuItem? {
        switch row.kind {
        case .header:
            ResearchBarMenuItem(title: row.label, kind: .header)
        case .info:
            ResearchBarMenuItem(title: self.labeled(row), kind: .info)
        case .notice:
            ResearchBarMenuItem(title: self.labeled(row), kind: .notice)
        case let .sparkline(values):
            ResearchBarMenuItem(title: self.trendSummary(label: row.label, values: values), kind: .trend)
        case let .action(action):
            ResearchBarMenuItem(title: row.label, kind: .action(action))
        }
    }

    private static func labeled(_ row: ResearchMenuRow) -> String {
        guard let value = row.value, !value.isEmpty else { return row.label }
        return "\(row.label): \(value)"
    }

    // MARK: Trend rendering

    /// A compact textual trend line built from the real sparkline values. The Core model
    /// only ever emits a non-empty `sparkline` for a `tracked` pulse with complete trend
    /// data, so this never invents a zero. An empty array degrades to the label only.
    private static func trendSummary(label: String, values: [Int]) -> String {
        guard let first = values.first, let last = values.last else { return label }
        let blocks = self.blocks(for: values)
        return "\(label): \(first) → \(last)  \(blocks)"
    }

    private static let blockGlyphs = Array("▁▂▃▄▅▆▇█")

    private static func blocks(for values: [Int]) -> String {
        guard let min = values.min(), let max = values.max() else { return "" }
        let span = max - min
        guard span > 0 else {
            // A flat series renders as a mid-height baseline, never a zero floor.
            return String(repeating: self.blockGlyphs[self.blockGlyphs.count / 2], count: values.count)
        }
        let lastIndex = self.blockGlyphs.count - 1
        let scaled = values.map { value -> Character in
            let ratio = Double(value - min) / Double(span)
            let index = Int((ratio * Double(lastIndex)).rounded())
            return self.blockGlyphs[Swift.min(Swift.max(index, 0), lastIndex)]
        }
        return String(scaled)
    }
}
