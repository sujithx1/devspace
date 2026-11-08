import Foundation

/// Mirrors `lib/features/widgets/widget_snapshot.dart` (version 2).
/// Fields added after version 1 are optional so older snapshots still decode.
struct WidgetSnapshot: Codable {
    var version: Int
    var generatedAt: Double
    var workspace: Workspace?
    var tasks: [Task]
    var projects: [Project]

    struct Workspace: Codable {
        var name: String
        var icon: String
    }

    struct Task: Codable, Identifiable, Hashable {
        var id: String
        var title: String
        /// `YYYY-MM-DD`, local calendar day.
        var due: String?
        /// `HH:mm`.
        var time: String?
        var priority: String
        /// `todo`, `in_progress` or `completed`.
        var status: String
        /// Epoch milliseconds.
        var completedAt: Double?
        var projectId: String?
        var project: String?
        var projectColor: String?
        var repeats: Bool?

        var isCompleted: Bool { status == "completed" }
        var isInProgress: Bool { status == "in_progress" }
        var isUrgent: Bool { priority == "urgent" || priority == "high" }
        var priorityRank: Int { ["low": 0, "medium": 1, "high": 2, "urgent": 3][priority] ?? 1 }
        var completedDate: Date? { completedAt.map { Date(timeIntervalSince1970: $0 / 1000) } }
    }

    struct Project: Codable, Identifiable, Hashable {
        var id: String
        var name: String
        var due: String?
        var color: String
        var status: String
        var priority: String
        var progress: Double
        var openTasks: Int
        var totalTasks: Int?

        var isUrgent: Bool { priority == "urgent" || priority == "high" }
    }
}
