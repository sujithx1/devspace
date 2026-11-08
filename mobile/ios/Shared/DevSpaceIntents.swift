import AppIntents
import WidgetKit

// Actions that widgets and controls run without opening the app. Each one
// changes the shared snapshot (so every widget updates at once) and queues the
// change for the app, which saves it the next time it runs.

/// Asks every DevSpace widget to redraw, not just the one tapped.
///
/// iOS pauses reloads while a widget's action runs, then reloads that widget.
/// A reload request that arrives after the pause races with that reload, and
/// the tapped widget can end up showing the state from before the tap. So the
/// action waits briefly for the request to land while reloads are paused.
private func reloadWidgets() async {
    WidgetCenter.shared.reloadAllTimelines()
    try? await Task.sleep(for: .milliseconds(250))
}

/// Ticks or unticks a task. Widget checkboxes use it with a `Toggle`, which
/// flips at once while this runs. The new state is passed in explicitly rather
/// than left for the system to fill in.
struct SetTaskCompletedIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Task"
    static var isDiscoverable = false

    @Parameter(title: "Task ID") var taskId: String
    @Parameter(title: "Completed") var completed: Bool

    init() {}

    init(taskId: String, completed: Bool) {
        self.taskId = taskId
        self.completed = completed
    }

    func perform() async throws -> some IntentResult {
        DevSpaceShared.change(taskId, [.completed(completed)])
        await reloadWidgets()
        return .result()
    }
}

/// Starts or pauses a task (In Progress ⇄ To Do).
struct SetTaskStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Task Status"
    static var isDiscoverable = false

    @Parameter(title: "Task ID") var taskId: String
    /// `todo`, `in_progress` or `completed`.
    @Parameter(title: "Status") var status: String

    init() {}

    init(taskId: String, status: String) {
        self.taskId = taskId
        self.status = status
    }

    func perform() async throws -> some IntentResult {
        DevSpaceShared.change(taskId, [.status(status)])
        await reloadWidgets()
        return .result()
    }
}

/// Moves a task's due date to a day relative to today (0 = today, 1 = tomorrow).
struct RescheduleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Reschedule Task"
    static var isDiscoverable = false

    @Parameter(title: "Task ID") var taskId: String
    @Parameter(title: "Days from today") var days: Int

    init() {}

    init(taskId: String, days: Int) {
        self.taskId = taskId
        self.days = days
    }

    func perform() async throws -> some IntentResult {
        DevSpaceShared.change(taskId, [.due(DevSpaceShared.iso(daysFromToday: days))])
        await reloadWidgets()
        return .result()
    }
}

/// Moves every overdue open task (optionally only one project's) to today.
struct RescheduleOverdueIntent: AppIntent {
    static var title: LocalizedStringResource = "Move Overdue Tasks to Today"
    static var isDiscoverable = false

    /// Empty means every project.
    @Parameter(title: "Project ID") var projectId: String

    init() {}

    init(projectId: String?) {
        self.projectId = projectId ?? ""
    }

    func perform() async throws -> some IntentResult {
        let today = DevSpaceShared.iso(.now)
        let overdue = DevSpaceShared.loadSnapshot()?.tasks.filter {
            !$0.isCompleted && ($0.due ?? "9999") < today && (projectId.isEmpty || $0.projectId == projectId)
        } ?? []
        for task in overdue {
            DevSpaceShared.change(task.id, [.due(today)])
        }
        await reloadWidgets()
        return .result()
    }
}

/// Shows the next page of a widget's list, wrapping back to the first.
struct NextPageIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Page"
    static var isDiscoverable = false

    @Parameter(title: "Page Key") var pageKey: String
    @Parameter(title: "Page Count") var pageCount: Int

    init() {}

    init(pageKey: String, pageCount: Int) {
        self.pageKey = pageKey
        self.pageCount = pageCount
    }

    func perform() async throws -> some IntentResult {
        let next = (DevSpaceShared.page(pageKey) + 1) % max(pageCount, 1)
        DevSpaceShared.setPage(pageKey, next)
        await reloadWidgets()
        return .result()
    }
}

/// Opens the app at a destination, e.g. `capture/task` or `open/tasks`.
/// Used by widget buttons and controls.
struct OpenDevSpaceIntent: AppIntent {
    static var title: LocalizedStringResource = "Open DevSpace"
    static var isDiscoverable = false
    static var openAppWhenRun = true

    @Parameter(title: "Destination") var destination: String

    init() {}

    init(destination: String) {
        self.destination = destination
    }

    func perform() async throws -> some IntentResult {
        DevSpaceShared.enqueueURL(destination)
        return .result()
    }
}
