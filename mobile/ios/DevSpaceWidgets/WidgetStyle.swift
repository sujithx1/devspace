import SwiftUI
import WidgetKit

/// The app's colours (lib/app/theme/colors.dart), resolved for light and dark.
enum DS {
    static let accent = Color(light: 0x5B57E0, dark: 0x7C78FF)
    static let background = Color(light: 0xFFFFFF, dark: 0x17171B)
    static let primary = Color(light: 0x16161D, dark: 0xF2F2F5)
    static let secondary = Color(light: 0x6B6B76, dark: 0x9E9EA8)
    static let tertiary = Color(light: 0xA2A2AC, dark: 0x62626C)
    static let fill = Color(light: 0xEDEDF0, dark: 0x26262C)
    static let success = Color(light: 0x2FA866, dark: 0x3CC47C)
    static let warning = Color(light: 0xE59A1A, dark: 0xF0AE3A)
    static let danger = Color(light: 0xE5484D, dark: 0xFF6369)

    static func priority(_ priority: String) -> Color {
        switch priority {
        case "urgent": return danger
        case "high": return warning
        default: return tertiary
        }
    }

    /// Project colours, by the names the app stores.
    static func project(_ name: String?) -> Color {
        switch name {
        case "emerald": return Color(light: 0x1F9D6B, dark: 0x3CC48C)
        case "amber": return Color(light: 0xD98B0B, dark: 0xF0AE3A)
        case "rose": return Color(light: 0xE0456B, dark: 0xFF6B8E)
        case "sky": return Color(light: 0x1E8FD8, dark: 0x4FB3F7)
        case "violet": return Color(light: 0x9A4DE0, dark: 0xB57CFF)
        case "zinc": return Color(light: 0x71717A, dark: 0xA1A1AA)
        default: return accent
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Deep links into the app (see lib/features/widgets/deep_links.dart).
enum Links {
    static func task(_ id: String) -> URL { URL(string: "devspace://open/tasks/task/\(id)")! }
    static func project(_ id: String) -> URL { URL(string: "devspace://project/\(id)")! }
    static let tasks = URL(string: "devspace://open/tasks")!
    static let home = URL(string: "devspace://open/home")!
    static let projects = URL(string: "devspace://open/projects")!
}

/// Tappable round checkbox that completes the task in place.
struct TaskCheckbox: View {
    let task: WidgetSnapshot.Task
    var size: CGFloat = 18

    var body: some View {
        Button(intent: ToggleTaskIntent(taskId: task.id, completed: !task.isCompleted)) {
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(task.isCompleted ? DS.accent : (task.isUrgent ? DS.priority(task.priority) : DS.tertiary))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(task.isCompleted ? "Mark \(task.title) as not done" : "Complete \(task.title)")
    }
}

struct ProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat = 5
    var color: Color = DS.accent

    var body: some View {
        ZStack {
            Circle().stroke(DS.fill, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}

/// One task: checkbox, then a link to the task with its details.
struct TaskRow: View {
    let task: WidgetSnapshot.Task
    let day: DayModel
    var showDetail = true

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            TaskCheckbox(task: task)
            Link(destination: Links.task(task.id)) {
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundStyle(task.isCompleted ? DS.tertiary : DS.primary)
                            .strikethrough(task.isCompleted, color: DS.tertiary)
                            .lineLimit(1)
                        if showDetail, let detail = day.detail(for: task) {
                            Text(detail.text)
                                .font(.caption2)
                                .foregroundStyle(detail.isWarning ? DS.danger : DS.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                    if task.isUrgent && !task.isCompleted {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(DS.priority(task.priority))
                    }
                }
            }
        }
    }
}

/// Day-of-month badge for deadlines.
struct DateBadge: View {
    let date: Date
    var color: Color = DS.accent

    var body: some View {
        VStack(spacing: -1) {
            Text(date, format: .dateTime.weekday(.abbreviated))
                .font(.system(size: 8, weight: .bold))
                .textCase(.uppercase)
            Text(date, format: .dateTime.day())
                .font(.system(size: 15, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(color)
        .frame(width: 32, height: 32)
        .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

struct SectionLabel: View {
    let text: String
    var color: Color = DS.secondary

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

/// Shown when the app hasn't written any data yet.
struct OpenAppPrompt: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.title3.weight(.semibold))
                .foregroundStyle(DS.accent)
            Text("Open DevSpace to get started")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(DS.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(Links.home)
    }
}
