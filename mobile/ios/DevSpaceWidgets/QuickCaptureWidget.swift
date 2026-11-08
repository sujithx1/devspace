import SwiftUI
import WidgetKit

struct QuickCaptureWidget: Widget {
    let kind = "QuickCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevSpaceProvider()) { entry in
            QuickCaptureView(entry: entry).devSpaceBackground()
        }
        .configurationDisplayName("Quick Capture")
        .description("Add a task for today or tomorrow, start a project, or jump into DevSpace.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// A capture action. Buttons with intents work in every widget size, unlike links.
private struct CaptureAction: Identifiable {
    let id: String
    let title: String
    let symbol: String
    let tint: Color

    static let newTask = CaptureAction(id: Links.captureTask(due: "today"), title: "Today", symbol: "plus.circle.fill", tint: DS.accent)
    static let tomorrow = CaptureAction(id: Links.captureTask(due: "tomorrow"), title: "Tomorrow", symbol: "sunrise.fill", tint: DS.warning)
    static let project = CaptureAction(id: "capture/project", title: "Project", symbol: "square.stack.3d.up.fill", tint: DS.project("violet"))
    static let tasks = CaptureAction(id: "open/tasks", title: "My Tasks", symbol: "checklist", tint: DS.success)

    static let all = [newTask, tomorrow, project, tasks]
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
                    .widgetAccentable()
                Text(action.title)
                    .font(compact ? .system(size: 10, weight: .semibold) : .footnote.weight(.semibold))
                    .foregroundStyle(DS.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: compact ? .center : .leading)
            .padding(compact ? 4 : 12)
            .background(action.tint.opacity(0.1), in: RoundedRectangle(cornerRadius: compact ? 14 : 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(action.id.hasPrefix("capture/task") ? "New task for \(action.title.lowercased())" : action.title)
    }

    private var small: some View {
        let a = CaptureAction.all
        return Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow { tile(a[0], compact: true); tile(a[1], compact: true) }
            GridRow { tile(a[2], compact: true); tile(a[3], compact: true) }
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                WidgetHeader(symbol: "plus.circle.fill", title: "New task or project")
                Spacer()
                if let workspace = entry.snapshot?.workspace {
                    Text("\(workspace.icon) \(workspace.name)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DS.secondary)
                        .lineLimit(1)
                }
            }
            HStack(spacing: 8) {
                ForEach(CaptureAction.all) { tile($0, compact: false) }
            }
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
            .frame(height: 140)
            if let day = entry.day {
                let next = Array(day.items(.today).filter { !$0.isCompleted }.prefix(4))
                SectionLabel(text: "Up next")
                if next.isEmpty {
                    Text("Nothing left today. Enjoy the calm.")
                        .font(.subheadline)
                        .foregroundStyle(DS.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(next) { TaskRow(task: $0, day: day) }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

#Preview(as: .systemMedium) {
    QuickCaptureWidget()
} timeline: {
    DevSpaceEntry(date: .now, snapshot: .sample)
}
