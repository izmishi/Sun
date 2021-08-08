//
//  Alternate Numeral Glyphs.swift
//  Sun
//
//  Created by Izumu Mishima on 07/04/2022.
//

import SwiftUI

// Enable the use of the alternate 4,6, and 9 glyphs for better legibility, particularly at small sizes

extension Font.TextStyle {
	var uiKitVariant: UIFont.TextStyle {
		switch self {
		case .largeTitle:
			return .largeTitle
		case .title:
			return .title1
		case .title2:
			return .title2
		case .title3:
			return .title3
		case .headline:
			return .headline
		case .subheadline:
			return .subheadline
		case .body:
			return .body
		case .callout:
			return .callout
		case .caption:
			return .caption1
		case .caption2:
			return .caption2
		case .footnote:
			return .footnote
		@unknown default:
			return .body
		}
	}
}

func alternativeNumeralFont(style: Font.TextStyle = .body, size: CGFloat = .nan) -> UIFont {
	var pointSize = size
	if size.isNaN {
		pointSize = UIFont.preferredFont(forTextStyle: style.uiKitVariant).pointSize
	}
	let fontDescriptor = UIFontDescriptor
		.preferredFontDescriptor(withTextStyle: style.uiKitVariant)
		.addingAttributes([
			UIFontDescriptor.AttributeName.featureSettings: [
				[UIFontDescriptor.FeatureKey.type: 	kStylisticAlternativesType,
				 UIFontDescriptor.FeatureKey.selector: kStylisticAltOneOnSelector]
				,
				[UIFontDescriptor.FeatureKey.type: kStylisticAlternativesType,
				 UIFontDescriptor.FeatureKey.selector: kStylisticAltTwoOnSelector]
			]
		])
	
	
	return UIFont(descriptor: fontDescriptor, size: pointSize)
}

public extension Font {
	init(uiFont: UIFont) {
		self = Font(uiFont as CTFont)
	}
	static func alternateNumerals(style: Font.TextStyle = .body, size: CGFloat = .nan) -> Font {
		Font(uiFont: alternativeNumeralFont(style: style, size: size))
	}
}
