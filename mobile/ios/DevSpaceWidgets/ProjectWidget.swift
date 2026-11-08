import SwiftUI
import WidgetKit

/// One project: progress, what's left, tick tasks off and add new ones.
/// "Edit Widget" picks the project; otherwise the next one due is shown.
struct ProjectWidget: Widget {
    let kind = "ProjectWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ProjectConfiguration.self, provider: ProjectProvider()) { entry in
            ProjectWidgetView(entry: entry).devSpaceBackground()
        }
        .configurationDisplayName("Project")
        .description("Follow a project's progress and work through its tasks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ProjectWidgetView: View {
    let entry: ProjectEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let day = entry.day {
            if let project = entry.project {
                switch family {
                case .systemSmall: small(project, day)
                case .systemMedium: medium(project, day)
                default: large(project, day)
                }
            } else {
                VStack(spacing: 8) {
                    EmptyMessage(symbol: "square.stack.3d.up", text: "No projects yet")
                    IntentCapsuleButton(
                        systemName: "plus", label: "New Project",
                        intent: OpenDevSpaceIntent(destination: "capture/project"), filled: true
                    )
                }
                .widgetURL(Links.projects)
            }
        } else {
            OpenAppPrompt()
        }
    }

    private func tasks(_ project: WidgetSnapshot.Project, _ day: DayModel) -> [WidgetSnapshot.Task] {
        day.open(project.id) + day.doneToday(project.id)
    }

    /// Progress from the snapshot, adjusted for tasks ticked on a widget since.
    private func progress(_ project: WidgetSnapshot.Project, _ day: DayModel) -> (done: Int, total: Int, value: Double) {
        let open = day.open(project.id).count
        let total = max(project.totalTasks ?? project.openTasks, open)
        let done = max(0, total - open)
        let value = project.status == "completed" ? 1 : (total == 0 ? 0 : Double(done) / Double(total))
        return (done, total, value)
    }

    private func dueLabel(_ project: WidgetSnapshot.Project, _ day: DayModel) -> (text: String, isLate: Bool)? {
        guard let due = project.due, let date = DayModel.parse(due) else { return nil }
        return ("Due \(day.relative(date))", due < day.today)
    }

    private var addIntent: (String) -> OpenDevSpaceIntent {
        { OpenDevSpaceIntent(destination: Links.captureTask(projectId: $0)) }
    }

    // MARK: Small: ring and what's left.

    private func small(_ project: WidgetSnapshot.Project, _ day: DayModel) -> some View {
        let color = DS.project(project.color)
        let p = progress(project, day)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                ZStack {
                    ProgressRing(progress: p.value, lineWidth: 6, color: color)
                    Text("\(Int((p.value * 100).rounded()))%")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.primary)
                }
                .frame(width: 50, height: 50)
                Spacer()
                IntentIconButton(systemName: "plus", label: "New task in \(project.name)", intent: addIntent(project.id), tint: color, size: 26)
            }
            Spacer(minLength: 0)
            Text(project.name)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DS.primary)
                .lineLimit(2)
            Text(p.total - p.done == 0 ? "All tasks done" : "\(p.total - p.done) open · \(p.done) done")
                .font(.caption2)
                .foregroundStyle(DS.secondary)
            if let due = dueLabel(project, day) {
                Text(due.text)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(due.isLate ? DS.danger : color)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(Links.project(project.id))
    }

    // MARK: Medium: summary and a page of tasks.

    private func medium(_ project: WidgetSnapshot.Project, _ day: DayModel) -> some View {
        let color = DS.project(project.color)
        let p = progress(project, day)
        let page = Page(tasks(project, day), size: 3, key: "project.\(project.id).m")
        return HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Link(destination: Links.project(project.id)) {
                    Text(project.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(DS.primary)
                        .lineLimit(2)
                }
                ZStack {
                    ProgressRing(progress: p.value, lineWidth: 5, color: color)
                    Text("\(Int((p.value * 100).rounded()))%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(DS.primary)
                }
                .frame(width: 42, height: 42)
                Text("\(p.done) of \(p.total) done").font(.caption2).foregroundStyle(DS.secondary)
                if let due = dueLabel(project, day) {
                    Text(due.text).font(.caption2.weight(.semibold)).foregroundStyle(due.isLate ? DS.danger : color)
                }
                Spacer(minLength: 0)
                IntentIconButton(systemName: "plus", label: "New task in \(project.name)", intent: addIntent(project.id), tint: color)
            }
            .frame(width: 92, alignment: .leading)

            VStack(alignment: .leading, spacing: 5) {
                if page.items.isEmpty {
                    EmptyMessage(symbol: "checkmark.seal.fill", text: "No open tasks", color: DS.success)
                } else {
                    ForEach(page.items) { TaskRow(task: $0, day: day, showProject: false) }
                    Spacer(minLength: 0)
                    HStack {
                        Spacer()
                        PagerButton(page: page)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .widgetURL(Links.project(project.id))
    }

    // MARK: Large: header, progress, overdue, tasks.

    private func large(_ project: WidgetSnapshot.Project, _ day: DayModel) -> some View {
        let color = DS.project(project.color)
        let p = progress(project, day)
        let overdue = day.overdue(project.id).count
        let page = Page(tasks(project, day), size: overdue > 0 ? 6 : 7, key: "project.\(project.id).l")
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Circle().fill(color).frame(width: 10, height: 10).widgetAccentable()
                VStack(alignment: .leading, spacing: 0) {
                    Link(destination: Links.project(project.id)) {
                        Text(project.name).font(.headline).foregroundStyle(DS.primary).lineLimit(1)
                    }
                    Text(largeSubtitle(project, day, p))
                        .font(.caption)
                        .foregroundStyle(DS.secondary)
                        .lineLimit(1)
                }
                Spacer()
                PagerButton(page: page)
                IntentIconButton(systemName: "plus", label: "New task in \(project.name)", intent: addIntent(project.id), tint: color)
            }
            ProgressBar(progress: p.value, color: color, height: 6)
            if overdue > 0 {
                OverdueBanner(count: overdue, projectId: project.id)
            }
            if page.items.isEmpty {
                EmptyMessage(symbol: "checkmark.seal.fill", text: "Every task is done", color: DS.success)
            } else {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(page.items) { TaskRow(task: $0, day: day, showProject: false) }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(Links.project(project.id))
    }

    private func largeSubtitle(_ project: WidgetSnapshot.Project, _ day: DayModel, _ p: (done: Int, total: Int, value: Double)) -> String {
        var parts = ["\(p.done) of \(p.total) done"]
        if let due = dueLabel(project, day) { parts.append(due.text) }
        return parts.joined(separator: " · ")
    }
}

#Preview(as: .systemMedium) {
    ProjectWidget()
} timeline: {
    ProjectEntry(date: .now, snapshot: .sample, project: WidgetSnapshot.sample.projects.first, isAutomatic: false)
}
