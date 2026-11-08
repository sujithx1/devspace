import AppIntents
import SwiftUI
import WidgetKit

/// "New Task" for Control Center, the Lock Screen and the Action button.
@available(iOS 18.0, *)
struct NewTaskControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "tech.magadh.devspace.NewTaskControl") {
            ControlWidgetButton(action: OpenDevSpaceIntent(destination: Links.captureTask(due: "today"))) {
                Label("New Task", systemImage: "plus.circle.fill")
            }
        }
        .displayName("New Task")
        .description("Add a task to DevSpace.")
    }
}

/// Opens today's tasks.
@available(iOS 18.0, *)
struct TodayControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: "tech.magadh.devspace.TodayControl") {
            ControlWidgetButton(action: OpenDevSpaceIntent(destination: "open/tasks")) {
                Label("Today", systemImage: "star.fill")
            }
        }
        .displayName("Today's Tasks")
        .description("Open your tasks for today in DevSpace.")
    }
}
