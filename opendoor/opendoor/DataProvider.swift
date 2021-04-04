//
//  DataProvider.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import Foundation
import MapKit
import CryptoKit


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
