//
//  SunGraphView.swift
//  SunGraphView
//
//  Created by Izumu Mishima on 08/08/2021.
//

import SwiftUI
import CoreLocation
import Ephemeris
import Sunlight


extension Twilight: Identifiable {
	public var id: Double { self.degrees }
}

extension Date {
	func advancedBy(_ n: Int, _ component: Calendar.Component) -> Date? {
		return Calendar.current.date(byAdding: component, value: n, to: self)
	}
}

extension HorizontalAlignment {
	enum TwilightDateAlignment: AlignmentID {
		static func defaultValue(in d: ViewDimensions) -> CGFloat {
			d[.trailing]
		}
	}
	
	static let twilightDateAlignment = HorizontalAlignment(TwilightDateAlignment.self)
}

struct SunGraphView: View {
	@Environment(\.horizontalSizeClass) var horizontalSizeClass
	@Environment(\.sizeCategory) var sizeCategory // Updates the size category so that the alternate numerals respond to dynamic type changes
	
	var date: Date
	var location: CLLocation
	var centredOnSun: Bool
	var showsSunriseset: Bool
	var showsSunAngle: Bool
	var showsTwilightTimes: Bool
	var showsTimeOfDay: Bool
	var includesGoldenHour: Bool
	var forWidget: Bool
	
	var latitude: Double { location.coordinate.latitude }
	var longitude: Double { location.coordinate.longitude }
	
	var geographicLocation: GeographicLocation { GeographicLocation(longitude: location.coordinate.longitude, latitude: location.coordinate.latitude)
	}
	
	private var sunSinAltitude: Double {
		Sun.sinAltitude(forDate: date.toJ2000Date(), location: geographicLocation)
	}
	
	private var sunAltitude: Double { asin(sunSinAltitude) }
	private var sunAltitudeDegrees: Double { sunAltitude * 180 / .pi }
	
	var dateStart: Date {
		return Calendar.autoupdatingCurrent.startOfDay(for: date.advancedBy(-12, .hour) ?? date)
		//		return centredOnSun ? date.addingTimeInterval(-43200) : Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: date) ?? date
	}
	
	
	var baseSkyColour: Color {
		colour(forSinValue: sunSinAltitude)
	}
	
	var yesterday: Date { return date.advancedBy(-1, .day) ?? date.advanced(by: -86400) }
	var today: Date { date }
	var tomorrow: Date { date.advancedBy(1, .day) ?? date.advanced(by: 86400) }
	
	
	var sunriseSunset: (sunset0: Date?, sunrise0: Date?, sunset1: Date?, sunrise1: Date?, sunset2: Date?) {
		let y = SunlightCalculator(date: yesterday, latitude: latitude, longitude: longitude)
		let s = SunlightCalculator(date: date, latitude: latitude, longitude: longitude)
		let t = SunlightCalculator(date: tomorrow, latitude: latitude, longitude: longitude)
		
		return (y.calculate(.dusk, twilight: .official), s.calculate(.dawn, twilight: .official), s.calculate(.dusk, twilight: .official), t.calculate(.dawn, twilight: .official), t.calculate(.dusk, twilight: .official))
	}
	
	var twilights: [Twilight] {
		var temp: [Twilight] = [.official, .civil, .nautical, .astronomical]
		if includesGoldenHour {
			temp.insert(.custom(6), at: 0)
		}
		return temp
	}

	
	var body: some View {
		ZStack(alignment: .bottom) {
			if !(forWidget && showsTwilightTimes) {
				GeometryReader { geometry in
				// MARK: Canvas
				Canvas { context, size in
					let dayWidth = size.width / 3
					let y0 = size.height * 0.5
					let yMax = size.height * 0.35 // amplitude of sin wave
					
					// Create a copy of the context for the text
					let textContext = context
					
					// Flip the context so that +y is up
					context.scaleBy(x: 1, y: -1)
					context.translateBy(x: 0, y: -size.height)
					
					// Ground Path
					// A rectangle that blocks the fill color of the sun below the horizon
					let groundPath = Path(CGRect(x: 0, y: y0, width: size.width, height: size.height / 2))
					
					// Create a copy of the context to clip drawings at the horizon
					var maskedContext = context
					maskedContext.clip(to: groundPath)
					
					// Create a copy of the context for the sun
					let sunContext = context
					
					context.blendMode = .destinationAtop
					
					// Horizon Path
					var horizonPath = Path()
					horizonPath.move(to: CGPoint(x: 0, y: y0))
					horizonPath.addLine(to: CGPoint(x: size.width, y: y0))
					
					let timeStep = 86400.0 / Double(dayWidth)
					var sunPathPath = Path()
					
					
					for i in 0...Int(3 * dayWidth) {
						let time = dateStart.addingTimeInterval(Double(i) * timeStep).toJ2000Date()
						
						let sunSin = Sun.sinAltitude(forDate: time, location: geographicLocation)
						let point = CGPoint(x: CGFloat(i), y: y0 + CGFloat(sunSin) * yMax)
						
						if i == 0 {
							sunPathPath.move(to: point)
						} else {
							sunPathPath.addLine(to: point)
						}
					}
					
					// Midnight line
					if centredOnSun {
						var midnightPath = Path()
						let midnight = Calendar.current.startOfDay(for: dateStart.addingTimeInterval(86400))
						let midnightX = dayWidth * midnight.timeIntervalSince(dateStart) / 86400
						midnightPath.move(to: CGPoint(x: midnightX, y: 0))
						midnightPath.addLine(to: CGPoint(x: midnightX, y: size.height))
						
						context.stroke(midnightPath, with: .color(.white.opacity(0.25)), lineWidth: 1)
					}
					
					// Draw the sun
					let sunCentre = CGPoint(x: dayWidth * date.timeIntervalSince(dateStart) / 86400.0, y: y0 + sunSinAltitude * yMax)
					
					// Angular diameter of the sun is actually ~0.5º
					let sunDiameter: CGFloat = yMax * sin(.pi * 3 / 180)
					let sunPath = Path(ellipseIn: CGRect(origin: sunCentre, size: CGSize(width: sunDiameter, height: sunDiameter)).offsetBy(dx: -sunDiameter / 2, dy: -sunDiameter / 2))
					
					// Draw the horizon
					context.stroke(horizonPath, with: .color(.white.opacity(0.25)), lineWidth: 1)
					
					// Draw the sun path
					context.stroke(sunPathPath, with: .color(.white.opacity(0.2)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
					maskedContext.stroke(sunPathPath, with: .color(.white.opacity(0.4)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
					
					
					
					
					// MARK: Aura
					
					if sunAltitude > -20 {
						let normalisedHeight = geometry.size.height
						
						let normalisedY0 = 400 * y0 / normalisedHeight
						let normalisedSunCentreY = 400 * (2 * y0 - sunCentre.y) / normalisedHeight
						
						var imageWidth: CGFloat = normalisedHeight * 0.5 + 50 * min(0, normalisedY0 - normalisedSunCentreY)
						
						
						imageWidth = max(0, imageWidth)
						var brightness: Double = 0.5 + abs(Double(normalisedY0 - normalisedSunCentreY)) / 30
						brightness = max(0, min(1, brightness))
						
						var imageAura = maskedContext.resolve(Image("aura"))
						var imageAura2 = maskedContext.resolve(Image("aura 2"))
						
						
						let a = Color(red: 1, green: brightness, blue: pow(brightness, 2), opacity: 0.75 * (normalisedSunCentreY < normalisedY0 ? 1 : 1 - 10 * (normalisedSunCentreY / normalisedY0 - 1)))
						let aSize = CGSize(width: imageWidth, height: imageWidth)
						let aRect = CGRect(origin: CGPoint(x: sunCentre.x - aSize.width / 2, y: sunCentre.y - aSize.height / 2), size: aSize)
//						var aImage = maskedContext.resolve(Image("aura 2"))
						imageAura2.shading = .color(a)
						maskedContext.draw(imageAura2, in: aRect)
						
						let b = Color(red: 1, green: brightness, blue: brightness + 0.1, opacity: normalisedSunCentreY < normalisedY0 ? 1 : 1 - 10 * (normalisedSunCentreY / normalisedY0 - 1))
						let bSize = CGSize(width: imageWidth / 2, height: imageWidth / 2)
						let bRect = CGRect(origin: CGPoint(x: sunCentre.x - bSize.width / 2, y: sunCentre.y - bSize.height / 2), size: bSize)
//						var bImage = maskedContext.resolve(Image("aura"))
						imageAura.shading = .color(b)
						maskedContext.draw(imageAura, in: bRect)
						
						
						var x = -(normalisedY0 - normalisedSunCentreY - normalisedHeight * 0.05) / (normalisedHeight * 0.05)
						let y = x
						x = x > 1 ? 1 - abs(x - 1) : x
						x *= 1.5
						
						
						
						let c = Color(red: 1, green: 0.8, blue: 1 - (y - 0.4), opacity: 0.2 * x)
						let cSize = CGSize(width: normalisedHeight, height: normalisedY0 - normalisedSunCentreY + imageWidth / 3 + 10)
						let cRect = CGRect(origin: CGPoint(x: sunCentre.x - cSize.width / 2, y: y0 - cSize.height * 0.6), size: cSize)
//						var cImage = maskedContext.resolve(Image("aura 2"))
						imageAura2.shading = .color(c)
						maskedContext.draw(imageAura2, in: cRect)
						
						
						let d = Color(red: 1, green: 0.9 + 0.5 * max(0, 1.2 - sunSinAltitude), blue: 0.7 + max(0, 1.2 - sunSinAltitude), opacity: max(0, 0.2 - 2 * abs(sunSinAltitude - 0.2)))
						let dSize = CGSize(width: 1.5 * normalisedHeight, height: normalisedY0 - normalisedSunCentreY + imageWidth / 3)
						let dRect = CGRect(origin: CGPoint(x: sunCentre.x - dSize.width / 2, y: y0 - dSize.height / 2), size: dSize)
//						var dImage = maskedContext.resolve(Image("aura"))
						imageAura.shading = .color(d)
						maskedContext.draw(imageAura, in: dRect)
						
						
						
						let e = Color(red: 1, green: 0.9, blue: 0.8, opacity: 2 * x - 2)
						let eSize = CGSize(width: 2 * 400, height: 4 * (normalisedY0 - normalisedSunCentreY + imageWidth / 3 + 30))
						let eRect = CGRect(origin: CGPoint(x: sunCentre.x - eSize.width / 2, y: y0 - eSize.height / 2), size: eSize)
//						var eImage = maskedContext.resolve(Image("aura"))
						imageAura.shading = .color(e)
						maskedContext.draw(imageAura, in: eRect)
						
					}
					
					
					
					
					if showsSunriseset {
						// Show the sunrise and sunset times
						if let sunset = sunriseSunset.sunset0 {
							textContext.draw(timeText(for: sunset).sunrisesetStyle(), at: CGPoint(x: dayWidth * sunset.timeIntervalSince(dateStart) / 86400.0, y: y0), anchor: .top)
						}
						if let sunrise = sunriseSunset.sunrise0 {
							textContext.draw(timeText(for: sunrise).sunrisesetStyle(), at: CGPoint(x: dayWidth * sunrise.timeIntervalSince(dateStart) / 86400.0, y: y0), anchor: .bottom)
						}
						if let sunset = sunriseSunset.sunset1 {
							textContext.draw(timeText(for: sunset).sunrisesetStyle(), at: CGPoint(x: dayWidth * sunset.timeIntervalSince(dateStart) / 86400.0, y: y0), anchor: .top)
						}
						if let sunrise = sunriseSunset.sunrise1 {
							textContext.draw(timeText(for: sunrise).sunrisesetStyle(), at: CGPoint(x: dayWidth * sunrise.timeIntervalSince(dateStart) / 86400.0, y: y0), anchor: .bottom)
						}
						if let sunset = sunriseSunset.sunset2 {
							textContext.draw(timeText(for: sunset).sunrisesetStyle(), at: CGPoint(x: dayWidth * sunset.timeIntervalSince(dateStart) / 86400.0, y: y0), anchor: .top)
						}
					}
					
					
					
					
					// Draw the sun fill
					sunContext.fill(sunPath, with: .color(baseSkyColour))
					maskedContext.fill(sunPath, with: .color(.white))
					
					// Draw the sun outline
					sunContext.stroke(sunPath, with: .color(.white), lineWidth: 2)
				}
				.frame(width: 3 * geometry.size.width)
//				.frame(maxHeight: .infinity)
//				.frame(height: 1*geometry.size.height)
				.offset(x: (centredOnSun ? geometry.size.width * 0.5 - date.timeIntervalSince(dateStart) * Double(geometry.size.width) / 86400.0 : -Calendar.autoupdatingCurrent.startOfDay(for: date).timeIntervalSince(dateStart) * Double(geometry.size.width) / 86400.0) , y: 0)
				.ignoresSafeArea()
			}
			}
			// MARK: VStack
			VStack(alignment: .leading) {
				if !forWidget {
					Spacer()
				}
				if showsSunAngle {
					Text("\(sunAltitudeDegrees, specifier: "%.1f")°")
						.font(.alternateNumerals(style: .callout).lowercaseSmallCaps())
						.frame(maxWidth: .infinity, alignment: forWidget ? .trailing : .leading)
				}
				if forWidget {
					Spacer()
				}
				if showsTimeOfDay {
					Text(timeOfDayString(for: sunAltitude))
						.font(.alternateNumerals(style: .callout).lowercaseSmallCaps())
						.frame(maxWidth: .infinity, alignment: .leading)
				}
				
				Group {
				if showsTwilightTimes {
						VStack(alignment: .twilightDateAlignment) {
							let currentDayCalculator = SunlightCalculator(date: date, latitude: latitude, longitude: longitude)
							let morning = date.timeIntervalSince(Calendar.current.startOfDay(for: date)) < 43200
							let adjacentDay = morning ? date.advancedBy(-1, .day) ?? date.advanced(by: -86400) : date.advancedBy(1, .day) ?? date.advanced(by: 86400)
							let adjacentDayCalculator = SunlightCalculator(date: adjacentDay, latitude: latitude, longitude: longitude)
							
							if !forWidget {
								dateText(for: adjacentDay)
									.opacity(0.8)
									.font(.alternateNumerals(style: .callout).smallCaps())
									.alignmentGuide(.twilightDateAlignment) { d in d[HorizontalAlignment.trailing] }
							}
							
							HStack(alignment: .bottom) {
								VStack(alignment: .leading) {
									if includesGoldenHour {
										Text("Golden Hour")
									}
									Text("Official")
									Text("Civil")
									Text("Nautical")
									Text("Astronomical")
								}
								.font(.alternateNumerals(style: .callout).smallCaps())
								
								
								Spacer(minLength: 0)
								
								HStack(alignment: .bottom) {
									if morning && !forWidget {
										VStack(alignment: .trailing) {
											Text("Dusk").font(.alternateNumerals(style: .callout).smallCaps())
												.alignmentGuide(.twilightDateAlignment) { d in d[HorizontalAlignment.trailing] }
											ForEach(twilights) { twilight in
												timeText(for: adjacentDayCalculator.calculate(.dusk, twilight: twilight))
													.font(.alternateNumerals())
													.monospacedDigit()
											}
										}
										.frame(maxWidth: .infinity, alignment: .trailing)
									}
									
									
									VStack(alignment: .trailing) {
										Text("Dawn").font(.alternateNumerals(style: .callout).smallCaps())
										ForEach(twilights) { twilight in
											timeText(for: currentDayCalculator.calculate(.dawn, twilight: twilight))
												.font(.alternateNumerals())
												.monospacedDigit()
										}
									}
									.frame(maxWidth: .infinity, alignment: .trailing)
									
									VStack(alignment: .trailing) {
										Text("Dusk").font(.alternateNumerals(style: .callout).smallCaps())
										ForEach(twilights) { twilight in
											timeText(for: currentDayCalculator.calculate(.dusk, twilight: twilight))
												.font(.alternateNumerals())
												.monospacedDigit()
										}
									}
									.frame(maxWidth: .infinity, alignment: .trailing)
									
									if !morning && !forWidget {
										VStack(alignment: .trailing) {
											Text("Dawn").font(.alternateNumerals(style: .callout).smallCaps())
												.alignmentGuide(.twilightDateAlignment) { d in d[HorizontalAlignment.trailing] }
											ForEach(twilights) { twilight in
												timeText(for: adjacentDayCalculator.calculate(.dawn, twilight: twilight))
													.font(.alternateNumerals())
													.monospacedDigit()
											}
										}
										.frame(maxWidth: .infinity, alignment: .trailing)
									}
									
									if horizontalSizeClass == .regular {
										Spacer()
											.frame(maxWidth: .infinity)
									}
								}
								.frame(maxWidth: .infinity)
								
								if horizontalSizeClass == .regular {
									Spacer()
										.frame(maxWidth: .infinity)
								}
							}
						}
					}
				}
//				.padding(8)
//				.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
				.transition(.move(edge: .bottom).combined(with: .opacity))
			}
			.padding(forWidget ? .all : .horizontal)
			.font(.alternateNumerals(style: .callout))
		}
		.background(baseSkyColour)
	}
	
	func timeText(for date: Date?) -> Text {
		guard let date = date else { return Text("-") }
		return Text(date, style: .time)
	}
	
	func dateText(for date: Date?) -> Text {
		guard let date = date else { return Text("-") }
		return Text(date, format: Date.FormatStyle(date: .numeric))
	}
	
	func colour(forSinValue sinValue: Double) -> Color {
		let x = 2.0
		let min = 2.5
		let b: CGFloat = sinValue >= 0 ? 1 : sinValue < -1/min ? 0 : CGFloat(pow(min, x) * pow(sinValue + 1/min, x))
		let g: CGFloat = b >= 1 ? 0.8 : b * 0.8
		let r: CGFloat = sinValue > 0.1 ? 0 : (sinValue < 0 ? g / 2 : CGFloat(abs(sin(Double.pi * (sinValue + 1) / 2))) * 0.4)
		return Color(red: r, green: g, blue: b)
	}
	
	func timeOfDayString(for altitude: Double) -> String {
		// in radians
		switch altitude {
		case _ where altitude > 0:
			if includesGoldenHour && altitude <= .pi * 6 / 180 {
				return "Golden Hour"
			}
			return "Day"
		case _ where altitude > .pi * -6 / 180 :
			return "Civil Twilight"
		case _ where altitude > .pi * -12 / 180 :
			return "Nautical Twilight"
		case _ where altitude > .pi * -18 / 180 :
			return "Astronomical Twilight"
		default:
			return "Night"
		}
	}
}

struct SunGraphView_Previews: PreviewProvider {
	static var previews: some View {
		SunGraphView(date: .now, location: previewLocation, centredOnSun: true, showsSunriseset: true, showsSunAngle: true, showsTwilightTimes: true, showsTimeOfDay: true, includesGoldenHour: true, forWidget: false)
	}
}
