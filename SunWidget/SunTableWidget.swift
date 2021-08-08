//
//  File.swift
//  Sun
//
//  Created by Izumu Mishima on 08/04/2022.
//

import WidgetKit
import SwiftUI
import Intents


struct TableProvider: IntentTimelineProvider {
	func placeholder(in context: Context) -> TableEntry {
		TableEntry(date: Date(), configuration: TableConfigurationIntent(), location: CLLocation(), locationIsCurrent: false)
	}
	
	func getSnapshot(for configuration: TableConfigurationIntent, in context: Context, completion: @escaping (TableEntry) -> ()) {
		widgetLocationManager.fetchLocation() { location, success in
			let entry = TableEntry(date: Date(), configuration: configuration, location: location, locationIsCurrent: success)
			completion(entry)
		}
	}
	
	func getTimeline(for configuration: TableConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
		widgetLocationManager.fetchLocation() { location, success in
			var entries: [TableEntry] = []
			
			let currentDate = Date()
			for minuteOffset in 0 ..< 60 {
				let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
				let entry = TableEntry(date: entryDate, configuration: configuration, location: location, locationIsCurrent: success)
				entries.append(entry)
			}
			
			let timeline = Timeline(entries: entries, policy: .atEnd)
			completion(timeline)
		}
	}
}

struct TableEntry: TimelineEntry {
	let date: Date
	let configuration: TableConfigurationIntent
	let location: CLLocation
	let locationIsCurrent: Bool
}

struct SunTableWidgetEntryView : View {
	var entry: TableProvider.Entry
	
	var body: some View {
		ZStack(alignment: .topLeading) {
			SunGraphView(date: entry.date, location: entry.location, centredOnSun: false, showsSunriseset: false, showsSunAngle: false, showsTwilightTimes: true, showsTimeOfDay: false, includesGoldenHour: entry.configuration.includesGoldenHour?.boolValue ?? false, forWidget: true)
			
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


struct SunTableWidget: Widget {
	let kind: String = "SunTableWidget"
	
	var body: some WidgetConfiguration {
		IntentConfiguration(kind: kind, intent: TableConfigurationIntent.self, provider: TableProvider()) { entry in
			SunTableWidgetEntryView(entry: entry)
		}
		.supportedFamilies([.systemMedium])
		.configurationDisplayName("Sun Twilight Times Widget")
		.description("This widget shows the times of each stage of twilight.")
	}
}

struct SunTableWidget_Previews: PreviewProvider {
	static var previews: some View {
		SunTableWidgetEntryView(entry: TableEntry(date: Date(), configuration: TableConfigurationIntent(), location: previewLocation, locationIsCurrent: false))
			.previewContext(WidgetPreviewContext(family: .systemMedium))
	}
}
