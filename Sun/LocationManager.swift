//
//  LocationManager.swift
//  LocationManager
//
//  Created by Izumu Mishima on 09/08/2021.
//

import Foundation
import CoreLocation

class Location: NSObject, CLLocationManagerDelegate, ObservableObject {
	var locationManager = CLLocationManager()
	@Published var location = CLLocation()
	
	override init() {
		super.init()
		locationManager.requestWhenInUseAuthorization()
		if CLLocationManager.locationServicesEnabled() {
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyBest
			locationManager.startUpdatingLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = manager.location else { return }
		self.location = location
		UserDefaults.standard.set(location.coordinate.latitude, forKey: "latitude")
		UserDefaults.standard.set(location.coordinate.longitude, forKey: "longitude")
		manager.stopUpdatingLocation()
	}
}


class WidgetLocationManager: NSObject, CLLocationManagerDelegate {
	var locationManager: CLLocationManager?
	private var handler: ((CLLocation, Bool) -> Void)?
	
	override init() {
		super.init()
		
		self.locationManager = CLLocationManager()
		self.locationManager!.delegate = self
		if self.locationManager!.authorizationStatus == .notDetermined {
			self.locationManager!.requestWhenInUseAuthorization()
		}
	}
	
	func fetchLocation(handler: @escaping (CLLocation, Bool) -> Void) {
		self.handler = handler
		self.locationManager?.requestLocation()
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		UserDefaults.standard.set(locations.last!.coordinate.latitude, forKey: "latitude")
		UserDefaults.standard.set(locations.last!.coordinate.longitude, forKey: "longitude")
		self.handler!(locations.last!, true)
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print(error)
		let latitude = UserDefaults.standard.double(forKey: "latitude")
		let longitude = UserDefaults.standard.double(forKey: "longitude")
		let location = CLLocation(latitude: latitude, longitude: longitude)
		handler?(location, false)
	}
}
