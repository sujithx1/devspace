import WidgetKit

/// Every DevSpace widget refreshes now, then at each of the next two
/// midnights so Today and Overdue roll over without the app. The app and the
/// widget actions also reload timelines whenever data changes.
private func dayEntries<Entry>(_ make: (Date) -> Entry) -> Timeline<Entry> {
    let calendar = Calendar.current
    let now = Date()
    let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
    let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight) ?? midnight
    return Timeline(entries: [now, midnight, nextMidnight].map(make), policy: .after(nextMidnight))
}

// MARK: Static widgets (Productivity, Quick Capture, Deadlines)

struct DevSpaceEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    var day: DayModel? { snapshot.map { DayModel(date: date, snapshot: $0) } }
}

struct DevSpaceProvider: TimelineProvider {
    func placeholder(in context: Context) -> DevSpaceEntry {
        DevSpaceEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (DevSpaceEntry) -> Void) {
        let stored = DevSpaceShared.loadSnapshot()
        completion(DevSpaceEntry(date: .now, snapshot: context.isPreview ? (stored ?? .sample) : stored))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DevSpaceEntry>) -> Void) {
        let snapshot = DevSpaceShared.loadSnapshot()
        completion(dayEntries { DevSpaceEntry(date: $0, snapshot: snapshot) })
    }
}

// MARK: Tasks widget

struct TaskListEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let list: TaskListOption
    let project: WidgetSnapshot.Project?

    var day: DayModel? { snapshot.map { DayModel(date: date, snapshot: $0) } }
    var projectId: String? { project?.id }
    var title: String { project?.name ?? list.title }
    /// Remembers the page per list and project.
    var pageKey: String { "tasks.\(list.rawValue).\(project?.id ?? "all")" }
}

struct TaskListProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TaskListEntry {
        TaskListEntry(date: .now, snapshot: .sample, list: .today, project: nil)
    }

    func snapshot(for configuration: TaskListConfiguration, in context: Context) async -> TaskListEntry {
        let stored = DevSpaceShared.loadSnapshot()
        return entry(configuration, snapshot: context.isPreview ? (stored ?? .sample) : stored, date: .now)
    }

    func timeline(for configuration: TaskListConfiguration, in context: Context) async -> Timeline<TaskListEntry> {
        let snapshot = DevSpaceShared.loadSnapshot()
        return dayEntries { entry(configuration, snapshot: snapshot, date: $0) }
    }

    private func entry(_ configuration: TaskListConfiguration, snapshot: WidgetSnapshot?, date: Date) -> TaskListEntry {
        let project = configuration.project.flatMap { chosen in snapshot?.projects.first { $0.id == chosen.id } }
        return TaskListEntry(date: date, snapshot: snapshot, list: configuration.list, project: project)
    }
}

// MARK: Project widget

struct ProjectEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
    let project: WidgetSnapshot.Project?
    /// True when no project was chosen and the next one due is shown.
    let isAutomatic: Bool

    var day: DayModel? { snapshot.map { DayModel(date: date, snapshot: $0) } }
}

struct ProjectProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ProjectEntry {
        let sample = WidgetSnapshot.sample
        return ProjectEntry(date: .now, snapshot: sample, project: sample.projects.first, isAutomatic: false)
    }

    func snapshot(for configuration: ProjectConfiguration, in context: Context) async -> ProjectEntry {
        let stored = DevSpaceShared.loadSnapshot()
        let snapshot = context.isPreview ? (stored ?? .sample) : stored
        return entry(configuration, snapshot: snapshot, date: .now)
    }

    func timeline(for configuration: ProjectConfiguration, in context: Context) async -> Timeline<ProjectEntry> {
        let snapshot = DevSpaceShared.loadSnapshot()
        return dayEntries { entry(configuration, snapshot: snapshot, date: $0) }
    }

    private func entry(_ configuration: ProjectConfiguration, snapshot: WidgetSnapshot?, date: Date) -> ProjectEntry {
        let projects = snapshot?.projects ?? []
        if let chosen = configuration.project, let project = projects.first(where: { $0.id == chosen.id }) {
            return ProjectEntry(date: date, snapshot: snapshot, project: project, isAutomatic: false)
        }
        // Next project due, then the one with most open tasks.
        let automatic = projects
            .filter { $0.status != "completed" }
            .sorted { ($0.due ?? "9999", -$0.openTasks) < ($1.due ?? "9999", -$1.openTasks) }
            .first
        return ProjectEntry(date: date, snapshot: snapshot, project: automatic, isAutomatic: true)
    }
}

// MARK: Sample data

extension WidgetSnapshot {
    /// Example data for the widget gallery before the app has run.
    static var sample: WidgetSnapshot {
        let today = DevSpaceShared.iso(daysFromToday: 0)
        let yesterday = DevSpaceShared.iso(daysFromToday: -1)
        let tomorrow = DevSpaceShared.iso(daysFromToday: 1)
        let later = DevSpaceShared.iso(daysFromToday: 4)
        func ago(_ days: Double) -> Double { Date().addingTimeInterval(-days * 86_400).timeIntervalSince1970 * 1000 }
        return WidgetSnapshot(
            version: 2,
            generatedAt: Date().timeIntervalSince1970 * 1000,
            workspace: .init(name: "Personal", icon: "🚀"),
            tasks: [
                .init(id: "1", title: "Review pull request", due: today, time: "10:00", priority: "high", status: "in_progress", projectId: "p1", project: "Launch", projectColor: "violet"),
                .init(id: "2", title: "Fix flaky login test", due: yesterday, priority: "urgent", status: "todo", projectId: "p1", project: "Launch", projectColor: "violet"),
                .init(id: "3", title: "Write release notes", due: today, priority: "medium", status: "todo", projectId: "p1", project: "Launch", projectColor: "violet"),
                .init(id: "4", title: "Update dependencies", due: today, priority: "low", status: "todo"),
                .init(id: "5", title: "Morning standup", due: today, priority: "medium", status: "completed", completedAt: ago(0.05)),
                .init(id: "6", title: "Plan next sprint", due: tomorrow, priority: "urgent", status: "todo"),
                .init(id: "7", title: "Refactor auth flow", due: later, priority: "medium", status: "todo", projectId: "p1", project: "Launch", projectColor: "violet"),
                .init(id: "8", title: "Set up CI cache", priority: "medium", status: "completed", completedAt: ago(1)),
                .init(id: "9", title: "Triage issues", priority: "medium", status: "completed", completedAt: ago(2)),
                .init(id: "10", title: "Pair on API", priority: "medium", status: "completed", completedAt: ago(2.2)),
            ],
            projects: [
                .init(id: "p1", name: "Launch", due: later, color: "violet", status: "active", priority: "high", progress: 0.4, openTasks: 4, totalTasks: 7),
            ]
        )
    }
}
