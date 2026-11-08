import SwiftUI
import WidgetKit

@main
struct DevSpaceWidgets: WidgetBundle {
    var body: some Widget {
        TodayTasksWidget()
        ProjectWidget()
        ProductivityWidget()
        UpcomingDeadlinesWidget()
        QuickCaptureWidget()
        if #available(iOS 18.0, *) {
            NewTaskControl()
            TodayControl()
        }
    }
}
