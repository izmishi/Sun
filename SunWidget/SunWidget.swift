//
//  SunWidget.swift
//  SunWidget
//
//  Created by Izumu Mishima on 10/08/2021.
//

import WidgetKit
import SwiftUI
import Intents

var widgetLocationManager = WidgetLocationManager()

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
		SimpleEntry(date: Date(), configuration: ConfigurationIntent(), location: CLLocation(), locationIsCurrent: false)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
		widgetLocationManager.fetchLocation() { location, success in
			let entry = SimpleEntry(date: Date(), configuration: configuration, location: location, locationIsCurrent: success)
			completion(entry)
		}
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        widgetLocationManager.fetchLocation() { location, success in
			var entries: [SimpleEntry] = []
			
			let currentDate = Date()
			for minuteOffset in 0 ..< 60 {
				let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
				let entry = SimpleEntry(date: entryDate, configuration: configuration, location: location, locationIsCurrent: success)
				entries.append(entry)
			}
			
			let timeline = Timeline(entries: entries, policy: .atEnd)
			completion(timeline)
		}
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
	let location: CLLocation
	let locationIsCurrent: Bool
}

struct SunWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
		ZStack(alignment: .topLeading) {
			SunGraphView(date: entry.date, location: entry.location, centredOnSun: entry.configuration.centredOnSun?.boolValue ?? false , showsSunriseset: entry.configuration.showsSunriseset?.boolValue ?? false, showsSunAngle: entry.configuration.showsSunAngle?.boolValue ?? false, showsTwilightTimes: false, showsTimeOfDay: entry.configuration.showsTimeOfDay?.boolValue ?? false, includesGoldenHour: entry.configuration.includesGoldenHour?.boolValue ?? false, forWidget: true)
			
			VStack(alignment: .leading) {
			Image(systemName: "location")
				.opacity(0.2)
				.symbolVariant(entry.locationIsCurrent ? .fill : .none)
				.padding()
			}
		}
		.colorScheme(.dark)
    }
}

//@main
struct SunWidget: Widget {
    let kind: String = "SunWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            SunWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Sun Widget")
        .description("This widget shows the position of the sun.")
    }
}

struct SunWidget_Previews: PreviewProvider {
    static var previews: some View {
		SunWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent(), location: previewLocation, locationIsCurrent: false))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
