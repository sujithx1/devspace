import SwiftUI
import WidgetKit

struct ProductivityWidget: Widget {
    let kind = "ProductivityWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevSpaceProvider()) { entry in
            ProductivityView(entry: entry).devSpaceBackground()
        }
        .configurationDisplayName("Productivity")
        .description("Today's progress, your streak and how your weeks are going.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular])
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
                case .accessoryCircular: circular(day)
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
            ProgressRing(progress: day.progress(), lineWidth: line)
            VStack(spacing: -2) {
                Text(percent(day.progress()))
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.primary)
                    .contentTransition(.numericText())
                Text("today")
                    .font(.system(size: size * 0.11, weight: .medium))
                    .foregroundStyle(DS.secondary)
            }
        }
        .frame(width: size, height: size)
    }

    private func streakChip(_ day: DayModel) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
            Text(day.streak == 1 ? "1 day" : "\(day.streak) days")
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(day.streak > 0 ? DS.warning : DS.tertiary)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background((day.streak > 0 ? DS.warning : DS.tertiary).opacity(0.14), in: Capsule())
        .accessibilityLabel("Streak: \(day.streak) days")
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
                        .widgetAccentable()
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

    /// Completions per day as a grid, one column per week.
    private func heatmap(_ day: DayModel, weeks: Int) -> some View {
        let grid = day.heatmap(weeks: weeks)
        let peak = max(grid.flatMap { $0.compactMap { $0 } }.max() ?? 0, 1)
        return HStack(alignment: .top, spacing: 3) {
            ForEach(Array(grid.enumerated()), id: \.offset) { _, week in
                VStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { d in
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(cellColor(week[d], peak: peak))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tasks completed over the last \(weeks) weeks")
    }

    private func cellColor(_ count: Int?, peak: Int) -> Color {
        guard let count else { return .clear }
        guard count > 0 else { return DS.fill }
        return DS.accent.opacity(0.3 + 0.7 * Double(count) / Double(peak))
    }

    private func small(_ day: DayModel) -> some View {
        VStack(spacing: 8) {
            ring(day, size: 76, line: 8)
            HStack(spacing: 8) {
                Label("\(day.doneToday().count)", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(DS.success)
                streakChip(day)
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
                    stat(day.doneToday().count, "Done today", color: DS.success)
                    stat(day.todayOpen().count, "Left", color: day.overdue().isEmpty ? DS.primary : DS.danger)
                    stat(day.completedThisWeek, "This week")
                }
                weekBars(day, height: 26)
            }
        }
    }

    private func large(_ day: DayModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                WidgetHeader(symbol: "chart.bar.fill", title: "Productivity")
                Spacer()
                streakChip(day)
            }
            HStack(spacing: 18) {
                ring(day, size: 92, line: 9)
                Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
                    GridRow {
                        stat(day.doneToday().count, "Done today", color: DS.success)
                        stat(day.todayOpen().count, "Left today", color: day.overdue().isEmpty ? DS.primary : DS.danger)
                    }
                    GridRow {
                        stat(day.completedThisWeek, "This week")
                        stat(day.overdue().count, "Overdue", color: day.overdue().isEmpty ? DS.primary : DS.danger)
                    }
                }
            }
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "This week")
                    weekBars(day, height: 58, showCounts: true)
                    Text("\(percent(day.weekRate)) of this week's tasks done")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(DS.accent)
                }
                VStack(alignment: .leading, spacing: 6) {
                    SectionLabel(text: "12 weeks")
                    heatmap(day, weeks: 12)
                }
                .frame(width: 128)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func circular(_ day: DayModel) -> some View {
        Gauge(value: day.progress()) {
            Image(systemName: "checkmark")
        } currentValueLabel: {
            Text("\(day.doneToday().count)")
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .accessibilityLabel("\(day.doneToday().count) done today")
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

#Preview(as: .systemLarge) {
    ProductivityWidget()
} timeline: {
    DevSpaceEntry(date: .now, snapshot: .sample)
}
