import Foundation

/// Storage shared by the app and its widgets through the App Group.
///
/// The app writes a JSON snapshot (see `WidgetSnapshot`) for the widgets to
/// render. Widgets and Shortcuts queue actions (tick a task, open a link)
/// that the app applies the next time it runs.
enum DevSpaceShared {
    static let appGroup = "group.tech.magadh.devspace"
    static let urlScheme = "devspace"

    private static let snapshotKey = "widget.snapshot.v1"
    private static let actionsKey = "widget.pendingActions.v1"

    /// Posted in-process when an action is queued, so a running app can apply it at once.
    static let actionsQueued = Notification.Name("tech.magadh.devspace.actionsQueued")

    static var defaults: UserDefaults { UserDefaults(suiteName: appGroup) ?? .standard }

    // MARK: Snapshot

    static func saveSnapshotJSON(_ json: String) {
        defaults.set(json, forKey: snapshotKey)
    }

    static func loadSnapshot() -> WidgetSnapshot? {
        guard let json = defaults.string(forKey: snapshotKey), let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func saveSnapshot(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot), let json = String(data: data, encoding: .utf8) else { return }
        saveSnapshotJSON(json)
    }

    // MARK: Pending actions

    static func enqueue(_ action: [String: Any]) {
        var actions = pendingActions()
        actions.append(action)
        if let data = try? JSONSerialization.data(withJSONObject: actions) {
            defaults.set(data, forKey: actionsKey)
        }
        NotificationCenter.default.post(name: actionsQueued, object: nil)
    }

    static func enqueueURL(_ path: String) {
        enqueue(["type": "url", "url": "\(urlScheme)://\(path)"])
    }

    /// Removes and returns the queue as a JSON array string.
    static func takeActionsJSON() -> String {
        let data = defaults.data(forKey: actionsKey) ?? Data("[]".utf8)
        defaults.removeObject(forKey: actionsKey)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static func pendingActions() -> [[String: Any]] {
        guard let data = defaults.data(forKey: actionsKey),
              let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else { return [] }
        return list
    }

    /// Ticks or unticks a task from a widget: updates the snapshot so the
    /// widget reflects it immediately, and queues the change for the app.
    static func setTask(_ id: String, completed: Bool) {
        if var snapshot = loadSnapshot(), let index = snapshot.tasks.firstIndex(where: { $0.id == id }) {
            snapshot.tasks[index].status = completed ? "completed" : "todo"
            snapshot.tasks[index].completedAt = completed ? Date().timeIntervalSince1970 * 1000 : nil
            saveSnapshot(snapshot)
        }
        enqueue(["type": "complete", "taskId": id, "completed": completed])
    }
}
