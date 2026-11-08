import SwiftUI
import WidgetKit

/// Tasks: Today by default; "Edit Widget" switches to Upcoming, In Progress
/// or All, optionally for one project. Tasks can be ticked off, started,
/// pushed to tomorrow, overdue ones moved to today, and long lists paged,
/// all without opening the app.
struct TodayTasksWidget: Widget {
    let kind = "TodayTasksWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: TaskListConfiguration.self, provider: TaskListProvider()) { entry in
            TaskListView(entry: entry).devSpaceBackground()
        }
        .configurationDisplayName("Tasks")
        .description("Today's tasks, or any list you choose. Tick, start or reschedule tasks right here.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct TaskListView: View {
    let entry: TaskListEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let day = entry.day {
            switch family {
            case .systemSmall: small(day)
            case .systemMedium: medium(day)
            case .systemLarge, .systemExtraLarge: large(day)
            case .accessoryCircular: circular(day)
            case .accessoryRectangular: rectangular(day)
            default: inline(day)
            }
        } else {
            OpenAppPrompt()
        }
    }

    private var list: TaskListOption { entry.list }
    private var projectId: String? { entry.projectId }
    private var headerColor: Color { entry.project.map { DS.project($0.color) } ?? DS.accent }
    private var headerSymbol: String { entry.project == nil ? list.symbol : "square.stack.3d.up.fill" }
    private var addIntent: OpenDevSpaceIntent {
        OpenDevSpaceIntent(destination: Links.captureTask(projectId: projectId, due: list.captureDue))
    }

    private func overdueCount(_ day: DayModel) -> Int {
        list == .today ? day.overdue(projectId).count : 0
    }

    // MARK: Small: count, next task to tick off.

    private func small(_ day: DayModel) -> some View {
        let pending = day.pending(list, projectId)
        let next = day.focus(list, projectId)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                WidgetHeader(symbol: headerSymbol, title: entry.title, color: headerColor)
                Spacer(minLength: 4)
                if list == .today {
                    ProgressRing(progress: day.progress(projectId), lineWidth: 3.5).frame(width: 18, height: 18)
                }
            }
            Spacer(minLength: 2)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(pending)")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(overdueCount(day) > 0 ? DS.danger : DS.primary)
                    .contentTransition(.numericText())
                Text(list.countLabel(pending))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(DS.secondary)
            }
            Spacer(minLength: 4)
            if let next {
                HStack(alignment: .center, spacing: 2) {
                    TaskCheck(task: next, size: 18)
                    Link(destination: Links.task(next.id)) {
                        Text(next.title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(DS.primary)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.leading, -5)
            } else {
                Label("All clear", systemImage: "checkmark.seal.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.success)
            }
        }
        .widgetURL(Links.tasks)
    }

    // MARK: Medium: summary column and a page of tasks.

    private func medium(_ day: DayModel) -> some View {
        let page = Page(day.items(list, projectId), size: 3, key: "\(entry.pageKey).m")
        let pending = day.pending(list, projectId)
        let overdue = overdueCount(day)
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                WidgetHeader(symbol: headerSymbol, title: entry.title, color: headerColor)
                Spacer(minLength: 2)
                Text("\(pending)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.primary)
                    .contentTransition(.numericText())
                Text(list.countLabel(pending))
                    .font(.caption2)
                    .foregroundStyle(DS.secondary)
                if overdue > 0 {
                    Text("\(overdue) overdue")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DS.danger)
                }
                Spacer(minLength: 6)
                HStack(spacing: 6) {
                    IntentIconButton(systemName: "plus", label: "New task", intent: addIntent)
                    if overdue > 0 {
                        IntentIconButton(
                            systemName: "arrow.uturn.forward",
                            label: "Move \(overdue) overdue to today",
                            intent: RescheduleOverdueIntent(projectId: projectId),
                            tint: DS.danger
                        )
                    }
                }
            }
            .frame(width: 86, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                if page.items.isEmpty {
                    EmptyMessage(symbol: "checkmark.seal.fill", text: emptyText, color: DS.success)
                } else {
                    ForEach(page.items) { TaskRow(task: $0, day: day, showProject: projectId == nil) }
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        PagerButton(page: page)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .widgetURL(Links.tasks)
    }

    // MARK: Large: header, progress, overdue, focus card, then the list.

    private func large(_ day: DayModel) -> some View {
        let overdue = overdueCount(day)
        let focus = (list == .today || list == .inProgress) ? day.focus(list, projectId) : nil
        let rest = day.items(list, projectId).filter { $0.id != focus?.id }
        // Rows that fit under the header, banner and focus card.
        let size = focus == nil ? (overdue > 0 ? 6 : 7) : (overdue > 0 ? 3 : 4)
        let page = Page(rest, size: size, key: "\(entry.pageKey).l")
        let done = day.doneToday(projectId).count

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 1) {
                    WidgetHeader(symbol: headerSymbol, title: entry.title, color: headerColor)
                    Text(subtitle(day, done: done))
                        .font(.caption)
                        .foregroundStyle(DS.secondary)
                }
                Spacer()
                PagerButton(page: page)
                IntentIconButton(systemName: "plus", label: "New task", intent: addIntent)
            }
            if list == .today {
                ProgressBar(progress: day.progress(projectId), color: headerColor)
            }
            if overdue > 0 {
                OverdueBanner(count: overdue, projectId: projectId)
            }
            if let focus {
                FocusCard(task: focus, day: day, showProject: projectId == nil)
            }
            if page.items.isEmpty && focus == nil {
                EmptyMessage(symbol: "checkmark.seal.fill", text: emptyText, color: DS.success)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(page.items) { TaskRow(task: $0, day: day, showProject: projectId == nil) }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(Links.tasks)
    }

    private func subtitle(_ day: DayModel, done: Int) -> String {
        let date = entry.date.formatted(.dateTime.weekday(.wide).month().day())
        switch list {
        case .today:
            let total = done + day.todayOpen(projectId).count
            return total == 0 ? date : "\(date) · \(done) of \(total) done"
        default:
            return "\(day.pending(list, projectId)) \(list.countLabel(2))"
        }
    }

    private var emptyText: String {
        switch list {
        case .today: "Nothing left today"
        case .upcoming: "Nothing in the next two weeks"
        case .inProgress: "Nothing in progress"
        case .all: "No open tasks"
        }
    }

    // MARK: Lock Screen

    private func circular(_ day: DayModel) -> some View {
        let pending = day.pending(list, projectId)
        return Gauge(value: list == .today ? day.progress(projectId) : 0) {
            Image(systemName: list.symbol)
        } currentValueLabel: {
            Text("\(pending)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetURL(Links.tasks)
        .accessibilityLabel("\(pending) \(list.countLabel(pending))")
    }

    private func rectangular(_ day: DayModel) -> some View {
        let pending = day.pending(list, projectId)
        let open = day.items(list, projectId).filter { !$0.isCompleted }
        return VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Image(systemName: list.symbol)
                Text(entry.title).fontWeight(.semibold)
                Spacer(minLength: 2)
                Text("\(pending)").fontWeight(.semibold)
            }
            .font(.headline)
            .widgetAccentable()
            if open.isEmpty {
                Text("All clear").font(.caption)
            } else {
                ForEach(open.prefix(2)) { task in
                    Text(task.title).font(.caption).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(Links.tasks)
    }

    private func inline(_ day: DayModel) -> some View {
        let pending = day.pending(list, projectId)
        return Label(pending == 0 ? "All clear" : "\(pending) \(list.countLabel(pending))", systemImage: list.symbol)
            .widgetURL(Links.tasks)
    }
}

/// The task to work on now, with Start/Pause, Tomorrow and Done.
struct FocusCard: View {
    let task: WidgetSnapshot.Task
    let day: DayModel
    var showProject = true

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                SectionLabel(text: task.isInProgress ? "Now" : "Up next", color: task.isInProgress ? DS.warning : DS.accent)
                if let detail = day.detail(for: task, showProject: showProject) {
                    Text("· \(detail.text)")
                        .font(.caption2)
                        .foregroundStyle(detail.isWarning ? DS.danger : DS.secondary)
                        .lineLimit(1)
                }
            }
            Link(destination: Links.task(task.id)) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack(spacing: 6) {
                if task.isInProgress {
                    IntentCapsuleButton(
                        systemName: "pause.fill", label: "Pause",
                        intent: SetTaskStatusIntent(taskId: task.id, status: "todo"), tint: DS.warning
                    )
                } else {
                    IntentCapsuleButton(
                        systemName: "play.fill", label: "Start",
                        intent: SetTaskStatusIntent(taskId: task.id, status: "in_progress"), tint: DS.warning
                    )
                }
                IntentCapsuleButton(
                    systemName: "sunrise.fill", label: "Tomorrow",
                    intent: RescheduleTaskIntent(taskId: task.id, days: 1), tint: DS.secondary
                )
                Spacer(minLength: 0)
                IntentCapsuleButton(
                    systemName: "checkmark", label: "Done",
                    intent: SetTaskStatusIntent(taskId: task.id, status: "completed"), tint: DS.accent, filled: true
                )
            }
        }
        .padding(9)
        .background(DS.fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview(as: .systemLarge) {
    TodayTasksWidget()
} timeline: {
    TaskListEntry(date: .now, snapshot: .sample, list: .today, project: nil)
}
