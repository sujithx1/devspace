import AppIntents
import WidgetKit

/// Which tasks a Tasks widget shows. Chosen with "Edit Widget".
enum TaskListOption: String, AppEnum {
    case today, upcoming, inProgress, all

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "List"
    static var caseDisplayRepresentations: [TaskListOption: DisplayRepresentation] = [
        .today: DisplayRepresentation(title: "Today", image: .init(systemName: "star.fill")),
        .upcoming: DisplayRepresentation(title: "Upcoming", image: .init(systemName: "calendar")),
        .inProgress: DisplayRepresentation(title: "In Progress", image: .init(systemName: "circle.lefthalf.filled")),
        .all: DisplayRepresentation(title: "All Tasks", image: .init(systemName: "tray.full.fill")),
    ]

    var title: String {
        switch self {
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .inProgress: "In Progress"
        case .all: "All Tasks"
        }
    }

    var symbol: String {
        switch self {
        case .today: "star.fill"
        case .upcoming: "calendar"
        case .inProgress: "circle.lefthalf.filled"
        case .all: "tray.full.fill"
        }
    }

    /// "3 left today", "3 upcoming", "3 in progress", "3 open".
    func countLabel(_ n: Int) -> String {
        switch self {
        case .today: n == 0 ? "all done" : "left today"
        case .upcoming: "upcoming"
        case .inProgress: "in progress"
        case .all: "open"
        }
    }

    /// Due day for a task created from this list, for the capture link.
    var captureDue: String? {
        switch self {
        case .today, .inProgress: "today"
        case .upcoming: "tomorrow"
        case .all: nil
        }
    }
}

/// A project, as offered in widget settings. Read from the shared snapshot.
struct ProjectEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Project"
    static var defaultQuery = ProjectQuery()

    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct ProjectQuery: EntityQuery {
    func entities(for identifiers: [ProjectEntity.ID]) async throws -> [ProjectEntity] {
        all().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ProjectEntity] { all() }

    private func all() -> [ProjectEntity] {
        (DevSpaceShared.loadSnapshot()?.projects ?? []).map { ProjectEntity(id: $0.id, name: $0.name) }
    }
}

struct TaskListConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Tasks"
    static var description = IntentDescription("Choose which tasks the widget shows.")

    @Parameter(title: "Show", default: .today) var list: TaskListOption
    @Parameter(title: "Project") var project: ProjectEntity?

    init() {}

    init(list: TaskListOption, project: ProjectEntity? = nil) {
        self.list = list
        self.project = project
    }
}

struct ProjectConfiguration: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Project"
    static var description = IntentDescription("Choose the project to follow. If none is chosen, the next project due is shown.")

    @Parameter(title: "Project") var project: ProjectEntity?
}
