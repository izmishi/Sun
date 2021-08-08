//
//  Custom Styles.swift
//  Custom Styles
//
//  Created by Izumu Mishima on 10/08/2021.
//

import SwiftUI


struct SimpleButtonStyle: ToggleStyle {
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
			.frame(maxHeight: 3)
			.padding()
//			.background(Color(uiColor: .systemFill))
			.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
//			.cornerRadius(8)
			.onTapGesture { configuration.isOn.toggle() }
			.foregroundColor(configuration.isOn ? .accentColor : .gray)
	}
}


extension Text {
	func sunrisesetStyle() -> Text {
		return self
			.foregroundColor(.white)
			.font(.alternateNumerals(style: .subheadline))
			.bold()
	}
}

extension UIImage {
	func tinted(color: UIColor) -> UIImage? {
		let image = self.withRenderingMode(.alwaysTemplate)
		let imageView = UIImageView(image: image)
		imageView.tintColor = color
		
		UIGraphicsBeginImageContext(image.size)
		if let context = UIGraphicsGetCurrentContext() {
			imageView.layer.render(in: context)
			let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			return tintedImage
		} else {
			return self
		}
	}
}
