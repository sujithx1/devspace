import SwiftUI

/// What the widgets show for one calendar day, derived from the snapshot.
/// Mirrors the app's task logic (lib/features/tasks/task_logic.dart) so a
/// widget stays correct after midnight even if the app hasn't run.
struct DayModel {
    typealias Task = WidgetSnapshot.Task

    let date: Date
    let snapshot: WidgetSnapshot
    let today: String
    private let calendar = Calendar.current

    init(date: Date, snapshot: WidgetSnapshot) {
        self.date = date
        self.snapshot = snapshot
        self.today = DevSpaceShared.iso(date)
    }

    static func parse(_ iso: String) -> Date? {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    // MARK: Lists

    private func scoped(_ projectId: String?) -> [Task] {
        guard let projectId else { return snapshot.tasks }
        return snapshot.tasks.filter { $0.projectId == projectId }
    }

    func open(_ projectId: String? = nil) -> [Task] { sorted(scoped(projectId).filter { !$0.isCompleted }) }
    func overdue(_ projectId: String? = nil) -> [Task] { open(projectId).filter { ($0.due ?? "9999") < today } }
    func dueToday(_ projectId: String? = nil) -> [Task] { open(projectId).filter { $0.due == today } }
    func inProgress(_ projectId: String? = nil) -> [Task] { open(projectId).filter(\.isInProgress) }

    /// Finished today, most recent first.
    func doneToday(_ projectId: String? = nil) -> [Task] {
        scoped(projectId)
            .filter { $0.isCompleted && $0.completedDate.map { calendar.isDate($0, inSameDayAs: date) } == true }
            .sorted { ($0.completedAt ?? 0) > ($1.completedAt ?? 0) }
    }

    /// Open tasks due in the next [days] days, soonest first.
    func upcoming(_ projectId: String? = nil, days: Int = 14) -> [Task] {
        let horizon = DevSpaceShared.iso(calendar.date(byAdding: .day, value: days, to: date) ?? date)
        return open(projectId).filter { guard let due = $0.due else { return false }; return due > today && due <= horizon }
    }

    /// Today's work: overdue, due today and undated tasks already started.
    func todayOpen(_ projectId: String? = nil) -> [Task] {
        open(projectId).filter { ($0.due.map { $0 <= today } ?? false) || ($0.due == nil && $0.isInProgress) }
    }

    /// The tasks a list shows. Today keeps what's been done today at the end
    /// so it can be unticked.
    func items(_ list: TaskListOption, _ projectId: String? = nil) -> [Task] {
        switch list {
        case .today: return todayOpen(projectId) + doneToday(projectId)
        case .upcoming: return upcoming(projectId)
        case .inProgress: return inProgress(projectId)
        case .all: return open(projectId)
        }
    }

    func pending(_ list: TaskListOption, _ projectId: String? = nil) -> Int {
        items(list, projectId).filter { !$0.isCompleted }.count
    }

    /// Share of today's work done, 0–1.
    func progress(_ projectId: String? = nil) -> Double {
        let done = doneToday(projectId).count
        let total = done + todayOpen(projectId).count
        return total == 0 ? 0 : Double(done) / Double(total)
    }

    /// What to work on now: a started task, else the most pressing open one.
    func focus(_ list: TaskListOption, _ projectId: String? = nil) -> Task? {
        let candidates = items(list, projectId).filter { !$0.isCompleted }
        return candidates.first(where: \.isInProgress) ?? candidates.first
    }

    // MARK: History

    /// Completions per calendar day, keyed by start of day.
    private var completionsByDay: [Date: Int] {
        var counts: [Date: Int] = [:]
        for t in snapshot.tasks where t.isCompleted {
            if let done = t.completedDate { counts[calendar.startOfDay(for: done), default: 0] += 1 }
        }
        return counts
    }

    private var weekStart: Date {
        let offset = (calendar.component(.weekday, from: date) + 5) % 7 // days since Monday
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: -offset, to: date) ?? date)
    }

    var todayIndex: Int { (calendar.component(.weekday, from: date) + 5) % 7 }

    /// Completions per day this week, Monday first.
    var weekCompletions: [Int] {
        let counts = completionsByDay
        return (0..<7).map { counts[calendar.date(byAdding: .day, value: $0, to: weekStart) ?? weekStart] ?? 0 }
    }

    var completedThisWeek: Int { weekCompletions.reduce(0, +) }

    /// Done this week vs. done plus still due by Sunday (including overdue).
    var weekRate: Double {
        let sunday = DevSpaceShared.iso(calendar.date(byAdding: .day, value: 6, to: weekStart) ?? date)
        let remaining = open().filter { ($0.due ?? "9999") <= sunday }.count
        let total = completedThisWeek + remaining
        return total == 0 ? 0 : Double(completedThisWeek) / Double(total)
    }

    /// Consecutive days with at least one completion, ending today (or
    /// yesterday, so a streak isn't lost before today's first task).
    var streak: Int {
        let counts = completionsByDay
        var day = calendar.startOfDay(for: date)
        if counts[day] == nil { day = calendar.date(byAdding: .day, value: -1, to: day) ?? day }
        var streak = 0
        while counts[day] != nil {
            streak += 1
            day = calendar.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }

    /// Completions for the last [weeks] weeks: one column per week (oldest
    /// first), Monday to Sunday; future days are nil.
    func heatmap(weeks: Int) -> [[Int?]] {
        let counts = completionsByDay
        let startOfToday = calendar.startOfDay(for: date)
        return (0..<weeks).map { w in
            let monday = calendar.date(byAdding: .day, value: -7 * (weeks - 1 - w), to: weekStart) ?? weekStart
            return (0..<7).map { d in
                let day = calendar.date(byAdding: .day, value: d, to: monday) ?? monday
                return day > startOfToday ? nil : (counts[day] ?? 0)
            }
        }
    }

    // MARK: Deadlines

    struct Deadline: Identifiable {
        let id: String
        let title: String
        let date: Date
        let subtitle: String
        let isUrgent: Bool
        let isOverdue: Bool
        let color: Color
        let url: URL
        /// Set for task deadlines, which can be ticked off.
        let task: Task?
        /// Set for project deadlines.
        let project: WidgetSnapshot.Project?
    }

    /// Overdue and upcoming task deadlines (two weeks) and project deadlines.
    var deadlines: [Deadline] {
        let horizon = DevSpaceShared.iso(calendar.date(byAdding: .day, value: 14, to: date) ?? date)
        let tasks: [Deadline] = open().compactMap { t in
            guard let due = t.due, due <= horizon, let day = DayModel.parse(due) else { return nil }
            return Deadline(
                id: t.id, title: t.title, date: day, subtitle: t.project ?? "",
                isUrgent: t.isUrgent, isOverdue: due < today,
                color: due < today ? DS.danger : DS.accent, url: Links.task(t.id), task: t, project: nil
            )
        }
        let projects: [Deadline] = snapshot.projects.compactMap { p in
            guard p.status != "completed", let due = p.due, due <= horizon, let day = DayModel.parse(due) else { return nil }
            return Deadline(
                id: p.id, title: p.name, date: day,
                subtitle: p.openTasks == 0 ? "Project" : "Project · \(p.openTasks) open",
                isUrgent: p.isUrgent, isOverdue: due < today,
                color: DS.project(p.color), url: Links.project(p.id), task: nil, project: p
            )
        }
        // Same day: projects before tasks.
        return (tasks + projects).sorted { ($0.date, $0.project == nil ? 1 : 0) < ($1.date, $1.project == nil ? 1 : 0) }
    }

    // MARK: Labels

    /// "Today", "Tomorrow", "Yesterday", "Friday", "3 days ago" or "Nov 12".
    func relative(_ day: Date) -> String {
        let diff = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: day)).day ?? 0
        switch diff {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        case 2..<7: return day.formatted(.dateTime.weekday(.wide))
        case ..<0: return "\(-diff) days ago"
        default: return day.formatted(.dateTime.month(.abbreviated).day())
        }
    }

    /// Secondary line for a task row: overdue age, day, time and project.
    func detail(for task: Task, showProject: Bool = true) -> (text: String, isWarning: Bool)? {
        if !task.isCompleted, let due = task.due, due < today, let day = DayModel.parse(due) {
            return ("Overdue · \(relative(day))", true)
        }
        var parts: [String] = []
        if task.isInProgress { parts.append("In progress") }
        if let due = task.due, due != today, let day = DayModel.parse(due) { parts.append(relative(day)) }
        if let time = task.time, let label = DayModel.timeLabel(time) { parts.append(label) }
        if showProject, let project = task.project { parts.append(project) }
        return parts.isEmpty ? nil : (parts.joined(separator: " · "), false)
    }

    static func timeLabel(_ hhmm: String) -> String? {
        let p = hhmm.split(separator: ":").compactMap { Int($0) }
        guard p.count == 2, let d = Calendar.current.date(from: DateComponents(hour: p[0], minute: p[1])) else { return nil }
        return d.formatted(date: .omitted, time: .shortened)
    }

    /// In progress first, then by due date and time (undated last), then priority.
    private func sorted(_ tasks: [Task]) -> [Task] {
        tasks.sorted { a, b in
            if a.isInProgress != b.isInProgress { return a.isInProgress }
            if a.due != b.due { return (a.due ?? "9999") < (b.due ?? "9999") }
            if a.time != b.time { return (a.time ?? "99:99") < (b.time ?? "99:99") }
            return a.priorityRank > b.priorityRank
        }
    }
}

/// One page of a widget's list, advanced by `NextPageIntent`.
struct Page<Item> {
    let items: [Item]
    let index: Int
    let count: Int
    let total: Int
    let key: String
    let size: Int

    init(_ all: [Item], size: Int, key: String) {
        self.size = max(size, 1)
        self.key = key
        total = all.count
        count = max(1, Int((Double(all.count) / Double(self.size)).rounded(.up)))
        index = DevSpaceShared.page(key) % count
        items = Array(all.dropFirst(index * self.size).prefix(self.size))
    }

    var isPaged: Bool { count > 1 }
    var rangeLabel: String { "\(index * size + 1)–\(index * size + items.count) of \(total)" }
}
