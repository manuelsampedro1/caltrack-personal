import SwiftUI
import WidgetKit

struct CaltrackWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct CaltrackWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CaltrackWidgetEntry {
        CaltrackWidgetEntry(date: .now, snapshot: .preview)
    }

    func getSnapshot(in context: Context, completion: @escaping (CaltrackWidgetEntry) -> Void) {
        completion(CaltrackWidgetEntry(
            date: .now,
            snapshot: context.isPreview ? .preview : WidgetSnapshotStore.load()
        ))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CaltrackWidgetEntry>) -> Void) {
        let now = Date.now
        let entry = CaltrackWidgetEntry(date: now, snapshot: WidgetSnapshotStore.load(now: now))
        let nextDay = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3_600)
        completion(Timeline(entries: [entry], policy: .after(nextDay)))
    }
}

struct CaltrackWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CaltrackWidgetEntry

    var body: some View {
        CaltrackWidgetContent(snapshot: entry.snapshot, family: family)
            .containerBackground(for: .widget) { WidgetPalette.canvas }
    }
}

struct CaltrackTodayWidget: Widget {
    static let kind = "CaltrackTodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: CaltrackWidgetProvider()) { entry in
            CaltrackWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Caltrack Hoy")
        .description("Calorías, proteína, fibra y accesos rápidos del día.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryInline,
            .accessoryCircular,
            .accessoryRectangular
        ])
    }
}

@main
struct CaltrackWidgetBundle: WidgetBundle {
    var body: some Widget {
        CaltrackTodayWidget()
    }
}
