//
//  DataProvider.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import Foundation
import MapKit
import CryptoKit

struct Column: Hashable {
    enum Usage {
        case lat, lon, address, numOfUnits
        var icon: UIImage {
            switch self {
            case .lon: return UIImage(systemName: "arrow.up.arrow.down.square")!
            case .lat: return UIImage(systemName: "arrow.left.arrow.right.square")!
            case .address: return UIImage(systemName: "signpost.left")!
            case .numOfUnits: return UIImage(systemName: "number.square")!
            }
        }
        static func possibleUsage(for title: String) -> Usage? {
            let startOrEndWith: (String)->Regex = {
                return Regex(stringLiteral: "^(\($0))|(\($0))$")
            }
            switch title.lowercased() {
            case startOrEndWith("lat(itude)?"): return .lat
            case startOrEndWith("lon(g)?(itude)?"): return .lon
            case startOrEndWith("(street)?[\\s_-]?address"): return .address
            case startOrEndWith("num(ber)?[\\s_-]?of[\\s_-]?unit(s)?"): return .numOfUnits
            default: return nil
            }
        }
    }
    var title: String
    var usage: Usage?
    var icon: UIImage? { usage?.icon ?? UIImage(systemName: "questionmark.square.dashed")?.withAlphaComponent(0.5) }
}

protocol DataSource {
    typealias DataSourceHash = SHA512Digest
    var hash: DataSourceHash { get }

    var item: DataSourceItem { get }
    var points: [PropertyDataPoint] { get }

    // Configuration UI
    var configurations: [AnyHashable] { get }
    func content(for dataConfigIndex: Int, from contentConfig: UIListContentConfiguration) -> UIListContentConfiguration
}

class DataProvider {
    static var shared = DataProvider()

    @Published var dataSources: [DataSource] = []

    /// Collections of points from all `dataSources`, grouped
    /// by points which are representing the same property
    @Published var pointsLists: [PropertyDataPointsList] = []

    func add(source: DataSource) {
        merge(newDataSource: source)
        dataSources.append(source)
    }

    func add(sources: [DataSource]) {
        sources.forEach(merge(newDataSource:))
        dataSources.append(contentsOf: sources)
    }


    /// Merges given `newDataSource` into the existing `pointsLists`
    /// - Parameter newDataSource: new source with points to merge
    func merge(newDataSource: DataSource) {

        //TODO: This is dumb logic! Need to be better...

        let listsCopy = pointsLists
        var newPoints: [PropertyDataPointsList] = []
        for point in newDataSource.points {
            if
                let index = listsCopy
                    .map({ $0.list.first! })
                    .firstIndex(where: { PropertyDataPoint.isSameProperty(point, $0) })
            {
                // Merge with existing property list
                listsCopy[index].append(point: point)
            } else {
                // New property
                guard let list = PropertyDataPointsList([point]) else {
                    assertionFailure("Can't create list from point!")
                    continue
                }
                newPoints.append(list)
            }
        }

        if !newPoints.isEmpty {
            pointsLists.append(contentsOf: newPoints)
        }
    }
}
