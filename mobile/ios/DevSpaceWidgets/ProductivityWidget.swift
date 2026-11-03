import SwiftUI
import WidgetKit

struct ProductivityWidget: Widget {
    let kind = "ProductivityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevSpaceProvider()) { entry in
            ProductivityView(entry: entry)
                .containerBackground(DS.background, for: .widget)
        }
        .configurationDisplayName("Productivity")
        .description("What you finished today and how your week is going.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ProductivityView: View {
    let entry: DevSpaceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let day = entry.day {
            Group {
                switch family {
                case .systemSmall: small(day)
                case .systemMedium: medium(day)
                default: large(day)
                }
            }
            .widgetURL(Links.tasks)
        } else {
            OpenAppPrompt()
        }
    }

    private func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }

    private func ring(_ day: DayModel, size: CGFloat, line: CGFloat) -> some View {
        ZStack {
            ProgressRing(progress: day.progress, lineWidth: line)
            VStack(spacing: -2) {
                Text(percent(day.progress))
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.primary)
                Text("today")
                    .font(.system(size: size * 0.11, weight: .medium))
                    .foregroundStyle(DS.secondary)
            }
        }
        .frame(width: size, height: size)
    }

    private func stat(_ value: Int, _ label: String, color: Color = DS.primary) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
            Text(label)
                .font(.caption2)
                .foregroundStyle(DS.secondary)
                .lineLimit(1)
        }
    }

    private func weekBars(_ day: DayModel, height: CGFloat, showCounts: Bool = false) -> some View {
        let counts = day.weekCompletions
        let peak = max(counts.max() ?? 0, 1)
        let labels = ["M", "T", "W", "T", "F", "S", "S"]
        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                VStack(spacing: 3) {
                    if showCounts {
                        Text(counts[i] > 0 ? "\(counts[i])" : " ")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundStyle(DS.secondary)
                    }
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(i == day.todayIndex ? DS.accent : DS.accent.opacity(i < day.todayIndex ? 0.35 : 0.12))
                        .frame(height: 4 + (height - 4) * CGFloat(counts[i]) / CGFloat(peak))
                    Text(labels[i])
                        .font(.system(size: 9, weight: i == day.todayIndex ? .bold : .medium))
                        .foregroundStyle(i == day.todayIndex ? DS.accent : DS.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Completed this week: \(counts.map(String.init).joined(separator: ", "))")
    }

    private func small(_ day: DayModel) -> some View {
        VStack(spacing: 8) {
            ring(day, size: 78, line: 8)
            HStack(spacing: 10) {
                Label("\(day.completedToday.count)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(DS.success)
                Label("\(day.pending)", systemImage: "circle")
                    .foregroundStyle(day.overdue.isEmpty ? DS.secondary : DS.danger)
            }
            .font(.caption.weight(.semibold))
            .labelStyle(CompactLabel())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func medium(_ day: DayModel) -> some View {
        HStack(spacing: 16) {
            ring(day, size: 84, line: 8)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    stat(day.completedToday.count, "Done today", color: DS.success)
                    stat(day.pending, "To do", color: day.overdue.isEmpty ? DS.primary : DS.danger)
                    stat(day.completedThisWeek, "This week")
                }
                weekBars(day, height: 26)
            }
        }
    }

    private func large(_ day: DayModel) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Productivity").font(.title3.weight(.bold)).foregroundStyle(DS.primary)
                Spacer()
                Text("This week").font(.caption.weight(.semibold)).foregroundStyle(DS.secondary)
            }
            HStack(spacing: 18) {
                ring(day, size: 104, line: 10)
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 18) {
                        stat(day.completedToday.count, "Done today", color: DS.success)
                        stat(day.pending, "Left today", color: day.overdue.isEmpty ? DS.primary : DS.danger)
                    }
                    HStack(spacing: 18) {
                        stat(day.completedThisWeek, "Done this week")
                        stat(day.overdue.count, "Overdue", color: day.overdue.isEmpty ? DS.primary : DS.danger)
                    }
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    SectionLabel(text: "Completed per day")
                    Spacer()
                    Text("\(percent(day.weekRate)) of this week's tasks done")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DS.accent)
                }
                weekBars(day, height: 70, showCounts: true)
            }
            Spacer(minLength: 0)
        }
    }
}

/// Icon and number close together.
private struct CompactLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
            configuration.title
        }
    }
}

#Preview(as: .systemMedium) {
    ProductivityWidget()
} timeline: {
    DevSpaceEntry(date: .now, snapshot: .sample)
}
