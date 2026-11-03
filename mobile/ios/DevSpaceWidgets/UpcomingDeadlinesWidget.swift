import SwiftUI
import WidgetKit

struct UpcomingDeadlinesWidget: Widget {
    let kind = "UpcomingDeadlinesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DevSpaceProvider()) { entry in
            UpcomingDeadlinesView(entry: entry)
                .containerBackground(DS.background, for: .widget)
        }
        .configurationDisplayName("Deadlines")
        .description("Upcoming task and project deadlines, with priorities.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct UpcomingDeadlinesView: View {
    let entry: DevSpaceEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let day = entry.day {
            switch family {
            case .systemSmall: small(day)
            case .systemMedium: list(day, limit: 3, title: false)
            default: list(day, limit: 7, title: true)
            }
        } else {
            OpenAppPrompt()
        }
    }

    private func small(_ day: DayModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionLabel(text: "Next deadline", color: DS.accent)
            Spacer(minLength: 6)
            if let next = day.deadlines.first {
                DateBadge(date: next.date, color: next.color)
                Spacer(minLength: 6)
                Text(next.title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.primary)
                    .lineLimit(2)
                HStack(spacing: 4) {
                    if next.isUrgent {
                        Image(systemName: "flag.fill").font(.system(size: 8)).foregroundStyle(DS.warning)
                    }
                    Text(next.isOverdue ? "Overdue" : day.relative(next.date))
                        .foregroundStyle(next.isOverdue ? DS.danger : DS.secondary)
                    if next.isProject { Text("· Project").foregroundStyle(DS.secondary) }
                }
                .font(.caption2)
            } else {
                Spacer()
                Label("No deadlines", systemImage: "calendar")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(DS.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(day.deadlines.first?.url ?? Links.tasks)
    }

    private func list(_ day: DayModel, limit: Int, title: Bool) -> some View {
        let items = Array(day.deadlines.prefix(limit))
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                if title {
                    Text("Deadlines").font(.title3.weight(.bold)).foregroundStyle(DS.primary)
                } else {
                    SectionLabel(text: "Deadlines", color: DS.accent)
                }
                Spacer()
                if day.deadlines.count > limit {
                    Text("+\(day.deadlines.count - limit) more").font(.caption2).foregroundStyle(DS.tertiary)
                }
            }
            if items.isEmpty {
                Spacer()
                Label("Nothing due in the next two weeks", systemImage: "calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(items) { item in
                    Link(destination: item.url) {
                        HStack(spacing: 10) {
                            DateBadge(date: item.date, color: item.color)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.title)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(DS.primary)
                                    .lineLimit(1)
                                HStack(spacing: 4) {
                                    Text(item.isOverdue ? "Overdue" : day.relative(item.date))
                                        .foregroundStyle(item.isOverdue ? DS.danger : DS.secondary)
                                    Text("· \(item.subtitle)").foregroundStyle(DS.secondary).lineLimit(1)
                                }
                                .font(.caption2)
                            }
                            Spacer(minLength: 0)
                            if item.isUrgent {
                                Image(systemName: "flag.fill").font(.system(size: 10)).foregroundStyle(DS.warning)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .widgetURL(Links.tasks)
    }
}

#Preview(as: .systemMedium) {
    UpcomingDeadlinesWidget()
} timeline: {
    DevSpaceEntry(date: .now, snapshot: .sample)
}
