import SwiftUI
import WidgetKit

struct QuickCaptureWidget: Widget {
    let kind = "QuickCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevSpaceProvider()) { entry in
            QuickCaptureView(entry: entry)
                .containerBackground(DS.background, for: .widget)
        }
        .configurationDisplayName("Quick Capture")
        .description("Add a task or project in one tap, or jump into DevSpace.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// A capture action. Buttons with intents work in every widget size, unlike links.
private struct CaptureAction: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let tint: Color

    static let all = [
        CaptureAction(id: "capture/task", title: "New Task", symbol: "checkmark.circle.fill", tint: DS.accent),
        CaptureAction(id: "capture/project", title: "New Project", symbol: "square.stack.3d.up.fill", tint: DS.project("violet")),
        CaptureAction(id: "open/tasks", title: "Today", symbol: "sun.max.fill", tint: DS.warning),
        CaptureAction(id: "open/home", title: "Open", symbol: "chevron.left.forwardslash.chevron.right", tint: DS.secondary),
    ]
}

struct QuickCaptureView: View {
    let entry: DevSpaceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall: small
        case .systemMedium: medium
        default: large
        }
    }

    private func tile(_ action: CaptureAction, compact: Bool) -> some View {
        Button(intent: OpenDevSpaceIntent(destination: action.id)) {
            VStack(alignment: compact ? .center : .leading, spacing: compact ? 3 : 6) {
                Image(systemName: action.symbol)
                    .font(.system(size: compact ? 17 : 20, weight: .semibold))
                    .foregroundStyle(action.tint)
                Text(action.title)
                    .font(compact ? .system(size: 10, weight: .semibold) : .footnote.weight(.semibold))
                    .foregroundStyle(DS.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: compact ? .center : .leading)
            .padding(compact ? 4 : 12)
            .background(DS.fill, in: RoundedRectangle(cornerRadius: compact ? 14 : 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.title)
    }

    private var small: some View {
        let a = CaptureAction.all
        return Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow { tile(a[0], compact: true); tile(a[1], compact: true) }
            GridRow { tile(a[2], compact: true); tile(a[3], compact: true) }
        }
    }

    private var medium: some View {
        HStack(spacing: 8) {
            ForEach(CaptureAction.all) { tile($0, compact: false) }
        }
    }

    private var large: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Quick Capture").font(.title3.weight(.bold)).foregroundStyle(DS.primary)
                Spacer()
                if let workspace = entry.snapshot?.workspace {
                    Text("\(workspace.icon) \(workspace.name)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.secondary)
                        .lineLimit(1)
                }
            }
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                GridRow { tile(CaptureAction.all[0], compact: false); tile(CaptureAction.all[1], compact: false) }
                GridRow { tile(CaptureAction.all[2], compact: false); tile(CaptureAction.all[3], compact: false) }
            }
            .frame(height: 150)
            if let day = entry.day {
                SectionLabel(text: "Up next")
                let next = Array((day.overdue + day.dueToday + day.upcoming).prefix(3))
                if next.isEmpty {
                    Text("Nothing scheduled. Enjoy the calm.")
                        .font(.subheadline)
                        .foregroundStyle(DS.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(next) { TaskRow(task: $0, day: day) }
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview(as: .systemSmall) {
    QuickCaptureWidget()
} timeline: {
    DevSpaceEntry(date: .now, snapshot: .sample)
}
