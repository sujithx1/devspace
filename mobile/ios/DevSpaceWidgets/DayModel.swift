import SwiftUI

/// What the widgets show for one calendar day, derived from the snapshot.
/// Mirrors the app's task logic (lib/features/tasks/task_logic.dart) so a
/// widget stays correct after midnight even if the app hasn't run.
struct DayModel {
    typealias Task = WidgetSnapshot.Task

    let date: Date
    let snapshot: WidgetSnapshot
    private let calendar = Calendar.current
    private let today: String

    init(date: Date, snapshot: WidgetSnapshot) {
        self.date = date
        self.snapshot = snapshot
        self.today = DayModel.iso(date)
    }

    static func iso(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func parse(_ iso: String) -> Date? {
        let parts = iso.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return Calendar.current.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    private var open: [Task] { snapshot.tasks.filter { !$0.isCompleted } }

    var overdue: [Task] { sorted(open.filter { ($0.due ?? "9999") < today }) }
    var dueToday: [Task] { sorted(open.filter { $0.due == today }) }
    var completedToday: [Task] {
        snapshot.tasks.filter { t in t.isCompleted && t.completedDate.map { calendar.isDate($0, inSameDayAs: date) } == true }
    }

    /// Overdue first, then today's, then what's already done today.
    var agenda: [Task] { overdue + dueToday + completedToday }
    var pending: Int { overdue.count + dueToday.count }
    var nextTask: Task? { (overdue + dueToday).first }

    /// Share of today's work done, 0–1.
    var progress: Double {
        let total = pending + completedToday.count
        return total == 0 ? 0 : Double(completedToday.count) / Double(total)
    }

    /// Open tasks due in the next seven days, soonest first.
    var upcoming: [Task] {
        let horizon = DayModel.iso(calendar.date(byAdding: .day, value: 7, to: date) ?? date)
        return sorted(open.filter { guard let due = $0.due else { return false }; return due > today && due <= horizon })
    }

    // MARK: Week

    private var weekStart: Date {
        let weekday = calendar.component(.weekday, from: date) // Sunday = 1
        let offset = (weekday + 5) % 7 // days since Monday
        return calendar.startOfDay(for: calendar.date(byAdding: .day, value: -offset, to: date) ?? date)
    }

    /// Completions per day this week, Monday first.
    var weekCompletions: [Int] {
        var days = Array(repeating: 0, count: 7)
        for t in snapshot.tasks {
            guard t.isCompleted, let done = t.completedDate else { continue }
            let index = calendar.dateComponents([.day], from: weekStart, to: calendar.startOfDay(for: done)).day ?? -1
            if (0..<7).contains(index) { days[index] += 1 }
        }
        return days
    }

    var completedThisWeek: Int { weekCompletions.reduce(0, +) }
    var todayIndex: Int { (calendar.component(.weekday, from: date) + 5) % 7 }

    /// Done this week vs. done plus still due by Sunday (including overdue).
    var weekRate: Double {
        let sunday = DayModel.iso(calendar.date(byAdding: .day, value: 6, to: weekStart) ?? date)
        let remaining = open.filter { ($0.due ?? "9999") <= sunday }.count
        let total = completedThisWeek + remaining
        return total == 0 ? 0 : Double(completedThisWeek) / Double(total)
    }

    // MARK: Deadlines

    struct Deadline: Identifiable {
        let id: String
        let title: String
        let date: Date
        let subtitle: String
        let isProject: Bool
        let isUrgent: Bool
        let isOverdue: Bool
        let color: Color
        let url: URL
    }

    /// Overdue and upcoming task deadlines (two weeks) and project deadlines.
    var deadlines: [Deadline] {
        let horizon = DayModel.iso(calendar.date(byAdding: .day, value: 14, to: date) ?? date)
        let tasks: [Deadline] = open.compactMap { t in
            guard let due = t.due, due <= horizon, let day = DayModel.parse(due) else { return nil }
            return Deadline(
                id: t.id, title: t.title, date: day, subtitle: t.project ?? "Task",
                isProject: false, isUrgent: t.isUrgent, isOverdue: due < today,
                color: due < today ? DS.danger : DS.accent, url: Links.task(t.id)
            )
        }
        let projects: [Deadline] = snapshot.projects.compactMap { p in
            guard let due = p.due, let day = DayModel.parse(due) else { return nil }
            return Deadline(
                id: p.id, title: p.name, date: day,
                subtitle: p.openTasks == 0 ? "Project" : "Project · \(p.openTasks) open",
                isProject: true, isUrgent: p.isUrgent, isOverdue: due < today,
                color: DS.project(p.color), url: Links.project(p.id)
            )
        }
        // Same day: projects before tasks.
        return (tasks + projects).sorted { ($0.date, $0.isProject ? 0 : 1) < ($1.date, $1.isProject ? 0 : 1) }
    }

    /// "Today", "Tomorrow", "Yesterday", "Fri" or "Nov 12".
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

    /// Secondary line for a task row: overdue age, time, or project.
    func detail(for task: Task) -> (text: String, isWarning: Bool)? {
        if !task.isCompleted, let due = task.due, due < today, let day = DayModel.parse(due) {
            return ("Overdue · \(relative(day))", true)
        }
        var parts: [String] = []
        if let time = task.time, let label = DayModel.timeLabel(time) { parts.append(label) }
        if let due = task.due, due != today, let day = DayModel.parse(due) { parts.insert(relative(day), at: 0) }
        if let project = task.project { parts.append(project) }
        return parts.isEmpty ? nil : (parts.joined(separator: " · "), false)
    }

    static func timeLabel(_ hhmm: String) -> String? {
        let p = hhmm.split(separator: ":").compactMap { Int($0) }
        guard p.count == 2, let d = Calendar.current.date(from: DateComponents(hour: p[0], minute: p[1])) else { return nil }
        return d.formatted(date: .omitted, time: .shortened)
    }

    /// Overdue before due, timed before untimed, then by priority.
    private func sorted(_ tasks: [Task]) -> [Task] {
        tasks.sorted { a, b in
            if a.due != b.due { return (a.due ?? "9999") < (b.due ?? "9999") }
            if a.time != b.time { return (a.time ?? "99:99") < (b.time ?? "99:99") }
            return a.priorityRank > b.priorityRank
        }
    }
}
