//
//  ContentView.swift
//  Sun
//
//  Created by Izumu Mishima on 08/08/2021.
//

import SwiftUI
import CoreLocation

extension HorizontalAlignment {
	enum LabelAlignment: AlignmentID {
		static func defaultValue(in d: ViewDimensions) -> CGFloat {
			d[.trailing]
		}
	}
	
	
	enum LabelIconAlignment: AlignmentID {
		static func defaultValue(in d: ViewDimensions) -> CGFloat {
			d[.leading]
		}
	}
	
	
	
	static let labelAlignment = HorizontalAlignment(LabelAlignment.self)
	static let labelIconAlignment = HorizontalAlignment(LabelIconAlignment.self)
}

struct ContentView: View {
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	
	@StateObject private var location = Location()
	
	@State private var showingSettings = false
	@AppStorage("centredOnSun") private var centredOnSun = true
	@AppStorage("showsSunriseset") private var showsSunriseset = true
	@AppStorage("showsSunAngle") private var showsSunAngle = true
	@AppStorage("showsTimeOfDay") private var showsTimeOfDay = true
	@AppStorage("showsTwilightTimes") private var showsTwilightTimes = true
	@AppStorage("includesGoldenHour") private var includesGoldenHour = true
	@AppStorage("useCurrentDate") private var useCurrentDate = true
	@State private var selectedDate = Date.now
	
//	private
	
	
	let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
	
    var body: some View {
		TimelineView(.periodic(from: Date.now, by: 1)) { timeline in
		
		ZStack(alignment: .topLeading) {
				let dateToShow: Date = useCurrentDate ? timeline.date : selectedDate
			SunGraphView(date: dateToShow, location: location.location, centredOnSun: centredOnSun, showsSunriseset: showsSunriseset, showsSunAngle: showsSunAngle, showsTwilightTimes: showsTwilightTimes, showsTimeOfDay: showsTimeOfDay, includesGoldenHour: includesGoldenHour, forWidget: false)
					.animation(.default, value: centredOnSun)
					.animation(.default, value: showsSunAngle)
					.animation(.default, value: showsTwilightTimes)
					.onTapGesture {
						showsTwilightTimes.toggle()
					}
					.gesture(DragGesture(minimumDistance: 30)
						.onEnded({ value in
							let morning = dateToShow.timeIntervalSince(Calendar.current.startOfDay(for: dateToShow)) < 43200
							if value.translation.width < 0 {
								// left
								centredOnSun = !morning
							}
							
							if value.translation.width > 0 {
								// right
								centredOnSun = morning
							}
						
						}))
				
				VStack(alignment: .leading) {
					HStack {
						Group {
							if horizontalSizeClass == .compact {
								Menu {
									toggleGroup()
										.labelStyle(.titleOnly)
								} label: {
									Label("Show settings", systemImage: "gear")
										.frame(maxHeight: 3)
										.padding()
										.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
								}

								
								Spacer()
								
								Toggle(isOn: $useCurrentDate) {
									Label("Use current date and time", systemImage: "clock.fill")
								}
								.toggleStyle(SimpleButtonStyle())
							} else {
								Spacer()
								
								toggleGroup()
									.toggleStyle(SimpleButtonStyle())
							}
						}
						.labelStyle(.iconOnly)
						
						
						let dateBinding = Binding {
							useCurrentDate ? timeline.date : selectedDate
						} set: { newValue in
							useCurrentDate = false
							selectedDate = newValue
						}
						
						
						DatePicker("Select date and time", selection: dateBinding)
							.datePickerStyle(.compact)
							.labelsHidden()
							.font(.alternateNumerals())
					}
					
					if showingSettings {
						VStack(alignment: .labelAlignment) {
							toggleGroup()
						}
						.labelStyle(.titleOnly)
						.padding()
						.background(.ultraThinMaterial)
						.cornerRadius(16)
					}
				}
				.padding()
				.animation(.default, value: showingSettings)
			}
			
		}
		.preferredColorScheme(.dark)
		.tint(.accentColor)
    }
	
	
	func toggleGroup() -> some View  {
		Group {
			Toggle(isOn: $centredOnSun) {
				Label {
					Text("Centre on Sun")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.leading] }
				} icon: {
					Image(systemName: "scope")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.trailing] }
				}
			}
			Toggle(isOn: $showsSunriseset) {
				
				Label {
					Text("Sunrise and sunset times")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.leading] }
				} icon: {
					Image(systemName: "sun.and.horizon.fill")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.trailing] }
				}
			}
			Toggle(isOn: $showsSunAngle) {
				
				Label {
					Text("Show the sun altitude")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.leading] }
				} icon: {
					Image(systemName: "sun.max.fill")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.trailing] }
				}
			}
			Toggle(isOn: $showsTimeOfDay) {
				
				Label {
					Text("Show the twilight name")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.leading] }
				} icon: {
					Image(systemName: "sun.haze.fill")
					//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.trailing] }
				}
			}
			Toggle(isOn: $showsTwilightTimes) {
				Label {
					Text("Show the twilight times")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.leading] }
				} icon: {
					Image(systemName: "tablecells")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.trailing] }
				}
			}
			Toggle(isOn: $includesGoldenHour) {
				Label {
					Text("Include golden hour")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.leading] }
				} icon: {
					Image(systemName: "camera.fill")
					//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.trailing] }
				}
			}
			Toggle(isOn: $useCurrentDate) {
				Label {
					Text("Use current date and time")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.leading] }
				} icon: {
					Image(systemName: "clock.fill")
//						.alignmentGuide(.labelAlignment) { d in d[HorizontalAlignment.trailing] }
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
		ContentView()
			.previewInterfaceOrientation(.portrait)
    }
}

