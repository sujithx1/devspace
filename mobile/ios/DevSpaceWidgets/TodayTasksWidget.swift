import SwiftUI
import WidgetKit

struct TodayTasksWidget: Widget {
    let kind = "TodayTasksWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevSpaceProvider()) { entry in
            TodayTasksView(entry: entry)
                .containerBackground(DS.background, for: .widget)
        }
        .configurationDisplayName("Today")
        .description("Today's tasks, what's overdue and what's next. Tick tasks off right here.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayTasksView: View {
    let entry: DevSpaceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let day = entry.day {
            switch family {
            case .systemSmall: small(day)
            case .systemMedium: medium(day)
            default: large(day)
            }
        } else {
            OpenAppPrompt()
        }
    }

    // Pending count and the next task.
    private func small(_ day: DayModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                SectionLabel(text: "Today", color: DS.accent)
                Spacer()
                ProgressRing(progress: day.progress, lineWidth: 3.5).frame(width: 18, height: 18)
            }
            Spacer(minLength: 4)
            Text("\(day.pending)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(day.overdue.isEmpty ? DS.primary : DS.danger)
                .contentTransition(.numericText())
            Text(day.pending == 1 ? "task to do" : "tasks to do")
                .font(.caption2)
                .foregroundStyle(DS.secondary)
            Spacer(minLength: 6)
            if let next = day.nextTask {
                Text(next.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.primary)
                    .lineLimit(2)
                if let detail = day.detail(for: next) {
                    Text(detail.text)
                        .font(.caption2)
                        .foregroundStyle(detail.isWarning ? DS.danger : DS.secondary)
                        .lineLimit(1)
                }
            } else {
                Label("All clear", systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.success)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(day.nextTask.map { Links.task($0.id) } ?? Links.tasks)
    }

    // Top three tasks beside the date and progress.
    private func medium(_ day: DayModel) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.date, format: .dateTime.weekday(.wide))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.accent)
                Text(entry.date, format: .dateTime.day())
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.primary)
                Spacer(minLength: 0)
                ZStack {
                    ProgressRing(progress: day.progress, lineWidth: 4)
                    Text("\(day.completedToday.count)/\(day.pending + day.completedToday.count)")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(DS.secondary)
                }
                .frame(width: 38, height: 38)
            }
            .frame(width: 64, alignment: .leading)

            VStack(alignment: .leading, spacing: 9) {
                let tasks = Array(day.agenda.prefix(3))
                if tasks.isEmpty {
                    Spacer()
                    Label("Nothing due today", systemImage: "sun.max.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DS.secondary)
                    Spacer()
                } else {
                    ForEach(tasks) { TaskRow(task: $0, day: day) }
                    Spacer(minLength: 0)
                    if day.agenda.count > 3 {
                        Text("+\(day.agenda.count - 3) more")
                            .font(.caption2)
                            .foregroundStyle(DS.tertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widgetURL(Links.tasks)
    }

    // Everything for today, progress, and what's coming up.
    private func large(_ day: DayModel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Today").font(.title3.weight(.bold)).foregroundStyle(DS.primary)
                    Text(entry.date, format: .dateTime.weekday(.wide).month().day())
                        .font(.caption)
                        .foregroundStyle(DS.secondary)
                }
                Spacer()
                Text("\(day.completedToday.count) of \(day.pending + day.completedToday.count) done")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.accent)
            }
            ProgressView(value: day.progress)
                .tint(DS.accent)

            let agenda = Array(day.agenda.prefix(day.upcoming.isEmpty ? 8 : 6))
            if agenda.isEmpty {
                Label("Nothing due today", systemImage: "sun.max.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.secondary)
                    .padding(.vertical, 6)
            } else {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(agenda) { TaskRow(task: $0, day: day) }
                }
            }

            if !day.upcoming.isEmpty {
                SectionLabel(text: "Coming up").padding(.top, 2)
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array(day.upcoming.prefix(agenda.isEmpty ? 5 : 3))) { TaskRow(task: $0, day: day) }
                }
            }
            Spacer(minLength: 0)
        }
        .widgetURL(Links.tasks)
    }
}

#Preview(as: .systemMedium) {
    TodayTasksWidget()
} timeline: {
    DevSpaceEntry(date: .now, snapshot: .sample)
}
