import WidgetKit

struct DevSpaceEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?

    var day: DayModel? { snapshot.map { DayModel(date: date, snapshot: $0) } }
}

/// One timeline for every DevSpace widget: now, then each of the next two
/// midnights so Today and Overdue roll over without the app. The app also
/// reloads the timelines whenever its data changes.
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
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight) ?? midnight
        let entries = [now, midnight, nextMidnight].map { DevSpaceEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(nextMidnight)))
    }
}

extension WidgetSnapshot {
    /// Example data for the widget gallery before the app has run.
    static var sample: WidgetSnapshot {
        let today = DayModel.iso(.now)
        let tomorrow = DayModel.iso(Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now)
        let later = DayModel.iso(Calendar.current.date(byAdding: .day, value: 4, to: .now) ?? .now)
        let doneAt = Date().addingTimeInterval(-3600).timeIntervalSince1970 * 1000
        return WidgetSnapshot(
            version: 1,
            generatedAt: Date().timeIntervalSince1970 * 1000,
            workspace: .init(name: "Personal", icon: "🚀"),
            tasks: [
                .init(id: "1", title: "Review pull request", due: today, time: "10:00", priority: "high", status: "todo", project: "Launch", projectColor: "indigo"),
                .init(id: "2", title: "Write release notes", due: today, priority: "medium", status: "in_progress", project: "Launch", projectColor: "indigo"),
                .init(id: "3", title: "Update dependencies", due: today, priority: "low", status: "todo"),
                .init(id: "4", title: "Morning standup", due: today, priority: "medium", status: "completed", completedAt: doneAt),
                .init(id: "5", title: "Plan next sprint", due: tomorrow, priority: "urgent", status: "todo"),
                .init(id: "6", title: "Refactor auth flow", due: later, priority: "medium", status: "todo"),
            ],
            projects: [
                .init(id: "p1", name: "Launch", due: later, color: "violet", status: "active", priority: "high", progress: 0.4, openTasks: 3),
            ]
        )
    }
}
