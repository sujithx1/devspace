import AppIntents
import SwiftUI
import WidgetKit

/// The app's colours (lib/app/theme/colors.dart), resolved for light and dark.
enum DS {
    static let accent = Color(light: 0x5B57E0, dark: 0x7C78FF)
    static let background = Color(light: 0xFFFFFF, dark: 0x17171B)
    static let primary = Color(light: 0x16161D, dark: 0xF2F2F5)
    static let secondary = Color(light: 0x6B6B76, dark: 0x9E9EA8)
    static let tertiary = Color(light: 0xA2A2AC, dark: 0x62626C)
    static let fill = Color(light: 0xF0F0F3, dark: 0x25252B)
    static let success = Color(light: 0x2FA866, dark: 0x3CC47C)
    static let warning = Color(light: 0xE59A1A, dark: 0xF0AE3A)
    static let danger = Color(light: 0xE5484D, dark: 0xFF6369)

    static func priority(_ priority: String) -> Color {
        switch priority {
        case "urgent": danger
        case "high": warning
        default: tertiary
        }
    }

    /// Project colours, by the names the app stores.
    static func project(_ name: String?) -> Color {
        switch name {
        case "emerald": Color(light: 0x1F9D6B, dark: 0x3CC48C)
        case "amber": Color(light: 0xD98B0B, dark: 0xF0AE3A)
        case "rose": Color(light: 0xE0456B, dark: 0xFF6B8E)
        case "sky": Color(light: 0x1E8FD8, dark: 0x4FB3F7)
        case "violet": Color(light: 0x9A4DE0, dark: 0xB57CFF)
        case "zinc": Color(light: 0x71717A, dark: 0xA1A1AA)
        default: accent
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

    /// Path for `OpenDevSpaceIntent` that opens the New Task sheet.
    static func captureTask(projectId: String? = nil, due: String? = nil) -> String {
        var query: [String] = []
        if let projectId { query.append("project=\(projectId)") }
        if let due { query.append("due=\(due)") }
        return "capture/task" + (query.isEmpty ? "" : "?" + query.joined(separator: "&"))
    }
}

// MARK: Background

extension View {
    /// The widget background; Lock Screen widgets use the system's.
    func devSpaceBackground() -> some View { modifier(DevSpaceBackground()) }
}

private struct DevSpaceBackground: ViewModifier {
    @Environment(\.widgetFamily) private var family

    func body(content: Content) -> some View {
        switch family {
        case .accessoryCircular, .accessoryRectangular, .accessoryInline:
            content.containerBackground(for: .widget) { Color.clear }
        default:
            content.containerBackground(for: .widget) { DS.background }
        }
    }
}

// MARK: Checkbox

/// Round checkbox. The ring takes the priority colour for High and Urgent and
/// is half filled when the task is in progress.
struct CheckToggleStyle: ToggleStyle {
    var tint: Color
    var inProgress: Bool
    var size: CGFloat

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if configuration.isOn {
                Circle().fill(DS.accent).widgetAccentable()
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Circle().strokeBorder(tint, lineWidth: 1.6)
                if inProgress {
                    HalfCircle().fill(tint).padding(size * 0.2)
                }
            }
        }
        .frame(width: size, height: size)
        // A finger-sized hit area around a small circle.
        .padding(5)
        .contentShape(Rectangle())
    }
}

private struct HalfCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        p.move(to: center)
        p.addArc(center: center, radius: min(rect.width, rect.height) / 2, startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// Ticks a task off in place. The system flips it at once, then runs the intent.
struct TaskCheck: View {
    let task: WidgetSnapshot.Task
    var size: CGFloat = 19

    var body: some View {
        Toggle(isOn: task.isCompleted, intent: SetTaskCompletedIntent(taskId: task.id, completed: !task.isCompleted)) {
            Text(task.title)
        }
        .toggleStyle(CheckToggleStyle(
            tint: task.isUrgent ? DS.priority(task.priority) : DS.tertiary,
            inProgress: task.isInProgress,
            size: size
        ))
        .accessibilityLabel(task.isCompleted ? "Mark \(task.title) as not done" : "Complete \(task.title)")
    }
}

/// Checkbox, then the task (opens it in the app) with its details.
struct TaskRow: View {
    let task: WidgetSnapshot.Task
    let day: DayModel
    var showDetail = true
    var showProject = true

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            TaskCheck(task: task)
            Link(destination: Links.task(task.id)) {
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundStyle(task.isCompleted ? DS.tertiary : DS.primary)
                            .strikethrough(task.isCompleted, color: DS.tertiary)
                            .lineLimit(1)
                        if showDetail, !task.isCompleted, let detail = day.detail(for: task, showProject: showProject) {
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

// MARK: Buttons

/// Small round icon button that runs an intent.
struct IntentIconButton<Intent: AppIntent>: View {
    let systemName: String
    let label: String
    let intent: Intent
    var tint: Color = DS.accent
    var size: CGFloat = 28

    var body: some View {
        Button(intent: intent) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(tint.opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Capsule button with an icon and a short label.
struct IntentCapsuleButton<Intent: AppIntent>: View {
    let systemName: String
    let label: String
    let intent: Intent
    var tint: Color = DS.accent
    var filled = false

    var body: some View {
        Button(intent: intent) {
            HStack(spacing: 4) {
                Image(systemName: systemName).font(.system(size: 10, weight: .bold))
                Text(label).font(.caption2.weight(.semibold)).lineLimit(1)
            }
            .foregroundStyle(filled ? .white : tint)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(filled ? tint : tint.opacity(0.14), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// "1–4 of 9 ⌄": shows the next page of a list.
struct PagerButton<Item>: View {
    let page: Page<Item>

    var body: some View {
        if page.isPaged {
            Button(intent: NextPageIntent(pageKey: page.key, pageCount: page.count)) {
                HStack(spacing: 4) {
                    Text(page.rangeLabel)
                    Image(systemName: page.index + 1 == page.count ? "arrow.counterclockwise" : "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                }
                .font(.caption2.weight(.medium))
                .foregroundStyle(DS.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(DS.fill, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Show more tasks")
        }
    }
}

/// Red strip offering to move overdue tasks to today.
struct OverdueBanner: View {
    let count: Int
    let projectId: String?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle.fill").font(.caption)
            Text("\(count) overdue").font(.caption.weight(.semibold))
            Spacer(minLength: 4)
            IntentCapsuleButton(
                systemName: "arrow.uturn.forward",
                label: "Move to Today",
                intent: RescheduleOverdueIntent(projectId: projectId),
                tint: DS.danger,
                filled: true
            )
        }
        .foregroundStyle(DS.danger)
        .padding(.leading, 9)
        .padding(.trailing, 4)
        .padding(.vertical, 4)
        .background(DS.danger.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: Shapes and labels

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
                .widgetAccentable()
        }
    }
}

struct ProgressBar: View {
    let progress: Double
    var color: Color = DS.accent
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(DS.fill)
                Capsule().fill(color)
                    .frame(width: max(height, geo.size.width * max(0, min(1, progress))))
                    .opacity(progress > 0 ? 1 : 0)
                    .widgetAccentable()
            }
        }
        .frame(height: height)
    }
}

/// Day-of-month badge for deadlines.
struct DateBadge: View {
    let date: Date
    var color: Color = DS.accent
    var size: CGFloat = 32

    var body: some View {
        VStack(spacing: -1) {
            Text(date, format: .dateTime.weekday(.abbreviated))
                .font(.system(size: size * 0.25, weight: .bold))
                .textCase(.uppercase)
            Text(date, format: .dateTime.day())
                .font(.system(size: size * 0.47, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(color)
        .frame(width: size, height: size)
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

/// Icon and title at the top of a list widget.
struct WidgetHeader: View {
    let symbol: String
    let title: String
    var color: Color = DS.accent

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 10, weight: .bold))
            Text(title).font(.caption.weight(.bold)).lineLimit(1)
        }
        .foregroundStyle(color)
        .widgetAccentable()
    }
}

/// Centered message for an empty list.
struct EmptyMessage: View {
    let symbol: String
    let text: String
    var color: Color = DS.secondary

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: symbol).font(.title3)
            Text(text).font(.caption.weight(.medium)).multilineTextAlignment(.center)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
