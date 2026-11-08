import Foundation

/// Storage shared by the app and its widgets through the App Group.
///
/// The app writes a JSON snapshot (see `WidgetSnapshot`) for the widgets to
/// render. Widgets, controls and Shortcuts change tasks without opening the
/// app: each change is applied to the snapshot straight away, so every widget
/// shows it, and queued for the app, which saves it to its database the next
/// time it runs.
enum DevSpaceShared {
    static let appGroup = "group.tech.magadh.devspace"
    static let urlScheme = "devspace"

    private static let snapshotKey = "widget.snapshot.v1"
    /// One key per queued action, so the widget and the app never overwrite
    /// each other's queue (UserDefaults has no atomic read-modify-write).
    private static let actionPrefix = "widget.action."
    /// Version 1 kept the whole queue in a single array.
    private static let legacyActionsKey = "widget.pendingActions.v1"
    private static let pagePrefix = "widget.page."

    /// Posted in-process when an action is queued, so a running app can apply it at once.
    static let actionsQueued = Notification.Name("tech.magadh.devspace.actionsQueued")

    static var defaults: UserDefaults { UserDefaults(suiteName: appGroup) ?? .standard }

    // MARK: Dates

    static func iso(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func iso(daysFromToday days: Int) -> String {
        iso(Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now)
    }

    // MARK: Snapshot

    /// Saves the app's snapshot. Changes made on a widget that the app hasn't
    /// applied yet are layered back on, so a widget never flips back.
    static func saveSnapshotJSON(_ json: String) {
        let pending = pendingActions()
        guard !pending.isEmpty, let data = json.data(using: .utf8),
              var snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            defaults.set(json, forKey: snapshotKey)
            return
        }
        pending.forEach { apply($0, to: &snapshot) }
        saveSnapshot(snapshot)
    }

    static func loadSnapshot() -> WidgetSnapshot? {
        guard let json = defaults.string(forKey: snapshotKey), let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func saveSnapshot(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot), let json = String(data: data, encoding: .utf8) else { return }
        defaults.set(json, forKey: snapshotKey)
    }

    // MARK: Task changes

    enum TaskChange {
        case completed(Bool)
        /// `todo`, `in_progress` or `completed`.
        case status(String)
        /// New due day, `YYYY-MM-DD`.
        case due(String)
    }

    /// Changes a task from outside the app: updates the snapshot now and
    /// queues the change for the app's database.
    static func change(_ taskId: String, _ changes: [TaskChange]) {
        var action: [String: Any] = ["type": "update", "taskId": taskId, "at": Date().timeIntervalSince1970 * 1000]
        for change in changes {
            switch change {
            case .completed(let done): action["status"] = done ? "completed" : "todo"
            case .status(let status): action["status"] = status
            case .due(let due): action["due"] = due
            }
        }
        if var snapshot = loadSnapshot() {
            apply(action, to: &snapshot)
            saveSnapshot(snapshot)
        }
        enqueue(action)
    }

    /// Applies one queued action to a snapshot (see `change`).
    static func apply(_ action: [String: Any], to snapshot: inout WidgetSnapshot) {
        guard let id = action["taskId"] as? String,
              let i = snapshot.tasks.firstIndex(where: { $0.id == id }) else { return }
        var status = action["status"] as? String
        if action["type"] as? String == "complete" {
            status = (action["completed"] as? Bool ?? true) ? "completed" : "todo"
        }
        if let status {
            let at = action["at"] as? Double ?? Date().timeIntervalSince1970 * 1000
            snapshot.tasks[i].completedAt = status == "completed" ? (snapshot.tasks[i].completedAt ?? at) : nil
            snapshot.tasks[i].status = status
        }
        if let due = action["due"] as? String {
            snapshot.tasks[i].due = due
        }
    }

    // MARK: Action queue

    static func enqueue(_ action: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: action) else { return }
        let ms = Int64(Date().timeIntervalSince1970 * 1000)
        defaults.set(data, forKey: "\(actionPrefix)\(String(format: "%015lld", ms)).\(UUID().uuidString)")
        NotificationCenter.default.post(name: actionsQueued, object: nil)
    }

    static func enqueueURL(_ path: String) {
        enqueue(["type": "url", "url": "\(urlScheme)://\(path)"])
    }

    /// Queued actions, oldest first, without removing them.
    static func pendingActions() -> [[String: Any]] {
        actionEntries().map(\.action)
    }

    /// Removes and returns the queue as a JSON array string.
    static func takeActionsJSON() -> String {
        let entries = actionEntries()
        entries.forEach { defaults.removeObject(forKey: $0.key) }
        let data = (try? JSONSerialization.data(withJSONObject: entries.map(\.action))) ?? Data("[]".utf8)
        return String(data: data, encoding: .utf8) ?? "[]"
    }

    private static func actionEntries() -> [(key: String, action: [String: Any])] {
        var entries: [(key: String, action: [String: Any])] = []
        if let data = defaults.data(forKey: legacyActionsKey),
           let list = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            entries += list.map { (legacyActionsKey, $0) }
        }
        let keys = defaults.dictionaryRepresentation().keys.filter { $0.hasPrefix(actionPrefix) }.sorted()
        for key in keys {
            if let data = defaults.data(forKey: key),
               let action = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                entries.append((key, action))
            }
        }
        return entries
    }

    // MARK: Widget paging

    static func page(_ key: String) -> Int { defaults.integer(forKey: pagePrefix + key) }

    static func setPage(_ key: String, _ page: Int) { defaults.set(page, forKey: pagePrefix + key) }
}
