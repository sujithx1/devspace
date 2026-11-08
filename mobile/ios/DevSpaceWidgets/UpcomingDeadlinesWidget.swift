import SwiftUI
import WidgetKit

struct UpcomingDeadlinesWidget: Widget {
    let kind = "UpcomingDeadlinesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevSpaceProvider()) { entry in
            UpcomingDeadlinesView(entry: entry).devSpaceBackground()
        }
        .configurationDisplayName("Deadlines")
        .description("Task and project deadlines for the next two weeks. Tick tasks off or push them to tomorrow.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

struct UpcomingDeadlinesView: View {
    let entry: DevSpaceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let day = entry.day {
            switch family {
            case .systemSmall: small(day)
            case .systemMedium: list(day, size: 3, large: false)
            case .accessoryRectangular: rectangular(day)
            default: list(day, size: 6, large: true)
            }
        } else {
            OpenAppPrompt()
        }
    }

    private func whenLabel(_ item: DayModel.Deadline, _ day: DayModel) -> String {
        item.isOverdue ? "Overdue · \(day.relative(item.date))" : day.relative(item.date)
    }

    private func small(_ day: DayModel) -> some View {
        let next = day.deadlines.first
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                WidgetHeader(symbol: "calendar", title: "Deadlines")
                Spacer(minLength: 0)
                if let task = next?.task {
                    TaskCheck(task: task, size: 18).padding(-5)
                }
            }
            Spacer(minLength: 6)
            if let next {
                DateBadge(date: next.date, color: next.color)
                Spacer(minLength: 6)
                Link(destination: next.url) {
                    Text(next.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(DS.primary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 4) {
                    if next.isUrgent {
                        Image(systemName: "flag.fill").font(.system(size: 8)).foregroundStyle(DS.warning)
                    }
                    Text(whenLabel(next, day)).foregroundStyle(next.isOverdue ? DS.danger : DS.secondary)
                }
                .font(.caption2)
                .lineLimit(1)
            } else {
                EmptyMessage(symbol: "calendar", text: "No deadlines")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(next?.url ?? Links.tasks)
    }

    private func list(_ day: DayModel, size: Int, large: Bool) -> some View {
        let page = Page(day.deadlines, size: size, key: large ? "deadlines.l" : "deadlines.m")
        return VStack(alignment: .leading, spacing: large ? 5 : 3) {
            HStack {
                if large {
                    Text("Deadlines").font(.title3.weight(.bold)).foregroundStyle(DS.primary)
                } else {
                    WidgetHeader(symbol: "calendar", title: "Deadlines")
                }
                Spacer()
                PagerButton(page: page)
            }
            if page.items.isEmpty {
                EmptyMessage(symbol: "calendar", text: "Nothing due in the next two weeks")
            } else {
                ForEach(page.items) { item in row(item, day, large: large) }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(Links.tasks)
    }

    private func row(_ item: DayModel.Deadline, _ day: DayModel, large: Bool) -> some View {
        HStack(spacing: 9) {
            Link(destination: item.url) {
                HStack(spacing: 9) {
                    DateBadge(date: item.date, color: item.color, size: large ? 32 : 28)
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(item.title)
                                .font((large ? Font.subheadline : Font.footnote).weight(.medium))
                                .foregroundStyle(item.task?.isCompleted == true ? DS.tertiary : DS.primary)
                                .strikethrough(item.task?.isCompleted == true, color: DS.tertiary)
                                .lineLimit(1)
                            if item.isUrgent {
                                Image(systemName: "flag.fill").font(.system(size: 8)).foregroundStyle(DS.warning)
                            }
                        }
                        Text([whenLabel(item, day), item.subtitle].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.caption2)
                            .foregroundStyle(item.isOverdue ? DS.danger : DS.secondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                }
            }
            if let task = item.task {
                if large && !task.isCompleted {
                    IntentIconButton(
                        systemName: "sunrise.fill", label: "Move \(task.title) to tomorrow",
                        intent: RescheduleTaskIntent(taskId: task.id, days: 1), tint: DS.secondary, size: 24
                    )
                }
                TaskCheck(task: task, size: 19)
            } else if let project = item.project {
                ProgressRing(progress: project.progress, lineWidth: 3, color: item.color)
                    .frame(width: 19, height: 19)
                    .padding(5)
            }
        }
    }

    private func rectangular(_ day: DayModel) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Label("Deadlines", systemImage: "calendar")
                .font(.headline)
                .widgetAccentable()
            if day.deadlines.isEmpty {
                Text("Nothing due soon").font(.caption)
            } else {
                ForEach(day.deadlines.prefix(2)) { item in
                    Text("\(day.relative(item.date)) · \(item.title)").font(.caption).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(day.deadlines.first?.url ?? Links.tasks)
    }
}

#Preview(as: .systemLarge) {
    UpcomingDeadlinesWidget()
} timeline: {
    DevSpaceEntry(date: .now, snapshot: .sample)
}
