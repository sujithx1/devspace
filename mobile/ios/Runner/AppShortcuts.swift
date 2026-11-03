import AppIntents

/// Opens DevSpace ready to add a task. Available in Shortcuts, Siri and Spotlight.
struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Opens DevSpace with a new task ready to type.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        DevSpaceShared.enqueueURL("capture/task")
        return .result()
    }
}

/// Opens DevSpace on today's tasks.
struct ShowTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Show Today"
    static var description = IntentDescription("Opens your tasks for today in DevSpace.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        DevSpaceShared.enqueueURL("open/tasks")
        return .result()
    }
}

struct DevSpaceShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddTaskIntent(),
            phrases: ["Add a task in \(.applicationName)", "New \(.applicationName) task"],
            shortTitle: "Add Task",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: ShowTodayIntent(),
            phrases: ["Show today in \(.applicationName)", "What's due in \(.applicationName)"],
            shortTitle: "Today",
            systemImageName: "sun.max"
        )
    }
}
