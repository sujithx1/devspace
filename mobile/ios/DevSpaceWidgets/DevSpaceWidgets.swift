import SwiftUI
import WidgetKit

@main
struct DevSpaceWidgets: WidgetBundle {
    var body: some Widget {
        TodayTasksWidget()
        ProductivityWidget()
        QuickCaptureWidget()
        UpcomingDeadlinesWidget()
    }
}
