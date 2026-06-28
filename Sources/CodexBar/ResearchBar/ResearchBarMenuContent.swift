import CodexBarCore
import SwiftUI

/// Self-contained SwiftUI renderer for the ResearchBar pulse menu.
///
/// It renders the `ResearchPulseMenuFactory` sections directly and dispatches taps through
/// `ResearchBarMenuActions`, touching none of the inherited `MenuDescriptor` / `MenuContent`
/// / `MenuActions` quota surfaces.
@MainActor
struct ResearchBarMenuContent: View {
    let sections: [ResearchBarMenuRenderSection]
    let actions: ResearchBarMenuActions

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(self.sections.enumerated()), id: \.offset) { index, section in
                VStack(alignment: .leading, spacing: 4) {
                    if let title = section.title {
                        Text(title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(title)
                    }
                    ForEach(Array(section.items.enumerated()), id: \.offset) { _, item in
                        self.row(for: item)
                    }
                }
                if index < self.sections.count - 1 {
                    Divider()
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minWidth: 260, alignment: .leading)
    }

    @ViewBuilder
    private func row(for item: ResearchBarMenuItem) -> some View {
        switch item.kind {
        case .header:
            Text(item.title).font(.headline).accessibilityLabel(item.title)
        case .info:
            Text(item.title).accessibilityLabel(item.title)
        case .notice:
            Text(item.title).foregroundStyle(.secondary).font(.footnote).accessibilityLabel(item.title)
        case .trend:
            Text(item.title).font(.callout.monospaced()).accessibilityLabel(item.title)
        case let .action(action):
            Button {
                self.actions.perform(action)
            } label: {
                Text(item.title).accessibilityLabel(item.title)
            }
            .buttonStyle(.plain)
        }
    }
}
