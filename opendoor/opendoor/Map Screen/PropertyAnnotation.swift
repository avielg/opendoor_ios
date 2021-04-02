//
//  PropertyAnnotation.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import UIKit
import MapKit

class PropertyAnnotation: MKPointAnnotation {
    var property: [String]

    var numOfUnits: Int { return Int(property[4]) ?? 1 }

    init?(_ data: [String]) {
        property = data
        super.init()

        guard
            data.count > 3,
            let lat = Double(data[2]),
            let lon = Double(data[3])
        else {
            return nil
        }
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        title = data[0] // address
        subtitle = numOfUnits == 1 ? "Single Family" : "Multi Family: \(numOfUnits) units"
    }
}

extension PropertyAnnotation: VisualAnnotation {
    var iconName: String? {
        return numOfUnits > 1 ? "building.2.crop.circle" : "house.circle"
    }
    var color: UIColor {
        switch numOfUnits {
        case ...1: return .systemGray
        case 2...4: return .systemYellow
        case 5...9: return .systemOrange
        case 10...: return .systemRed
        default:
            assertionFailure()
            return .systemGray
        }
    }
}
