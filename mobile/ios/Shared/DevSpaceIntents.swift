import AppIntents
import WidgetKit

/// Ticks or unticks a task straight from a widget, without opening the app.
struct ToggleTaskIntent: AppIntent {
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
        DevSpaceShared.setTask(taskId, completed: completed)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

/// Opens the app at a destination, e.g. `capture/task` or `open/tasks`.
/// Used by widget buttons, which (unlike links) work in every widget size.
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
