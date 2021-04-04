//
//  PropertyAnnotation.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import UIKit
import MapKit

protocol PropertyDataContainer {
    var coordinate: CLLocationCoordinate2D? { get }
    var address: String? { get }
    var numOfUnits: Int? { get }
}

class PropertyDataPointsList: PropertyDataContainer {

    /// List of points, guaranteed not empty
    private(set) var list: [PropertyDataPoint]
    lazy var annotation = PropertyAnnotation(self)

    required init?(_ points: [PropertyDataPoint]) {
        guard !points.isEmpty else { return nil }
        list = points
    }

    func append(point: PropertyDataPoint) {
        list.append(point)
    }

    var coordinate: CLLocationCoordinate2D? { list.lazy.compactMap({ $0.coordinate }).first }
    var address: String? { list.lazy.compactMap { $0.address }.first }
    var numOfUnits: Int? { list.lazy.compactMap { $0.numOfUnits }.first}
}

struct PropertyDataPoint: PropertyDataContainer {
    // Column to data in sheet based source, key value in json based source
    var rawData: [AnyHashable : AnyHashable]

    var coordinate: CLLocationCoordinate2D?
    var address: String?
    var numOfUnits: Int?

    var dataSourceItem: DataSourceItem?

    static func isSameProperty(_ lhs: PropertyDataPoint, _ rhs: PropertyDataPoint) -> Bool {
        return lhs.coordinate == rhs.coordinate || lhs.address == rhs.address
    }
}

extension CLLocationCoordinate2D: Equatable {
    static public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension PropertyDataContainer {
    var numOfUnitsLabel: String {
        numOfUnits == 1
            ? "Single Family"
            : "Multi Family: \(numOfUnits.map(String.init) ?? "unknown number of ") units"
    }
}

class PropertyAnnotation: MKPointAnnotation {
    var numOfUnits: Int?

    init?(_ dataPoints: PropertyDataPointsList) {
        numOfUnits = dataPoints.numOfUnits

        guard let coord = dataPoints.coordinate else { return nil }
        super.init()

        coordinate = coord
        title = dataPoints.address
        subtitle = dataPoints.numOfUnitsLabel
    }
}

extension PropertyAnnotation: VisualAnnotation {
    var iconName: String? {
        return numOfUnits ?? 0 > 1 ? "building.2.crop.circle" : "house.circle"
    }
    var color: UIColor {
        switch numOfUnits ?? 0 {
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
