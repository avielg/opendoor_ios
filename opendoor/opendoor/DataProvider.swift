//
//  DataProvider.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import Foundation
import MapKit

protocol DataPoint {
    var annotation: MKAnnotation { get }
}

protocol DataSource {
    var item: DataSourceItem { get }
    var points: [DataPoint] { get }

    // Configuration UI
    var configurations: [AnyHashable] { get }
    func content(for dataConfigIndex: Int, from contentConfig: UIListContentConfiguration) -> UIListContentConfiguration
}

class DataProvider {
    typealias DataSourcesHandler = ([DataSource]) -> Void

    static var shared = DataProvider()

    @Published var dataSources: [DataSource] = [] {
        didSet {
            for handler in dataSourceChangeHandlers {
                handler(dataSources)
            }
        }
    }

    var dataSourceChangeHandlers: [DataSourcesHandler] = []

    func handleDataSourceChange(_ handler: @escaping DataSourcesHandler) {
        dataSourceChangeHandlers.append(handler)
    }

    func add(source: DataSource) {
        dataSources.append(source)
    }

    func add(sources: [DataSource]) {
        dataSources.append(contentsOf: sources)
    }
}
