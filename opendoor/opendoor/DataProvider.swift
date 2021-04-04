//
//  DataProvider.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import Foundation
import MapKit
import CryptoKit

protocol DataPoint {
    var annotation: MKAnnotation { get }
}

protocol DataSource {
    typealias DataSourceHash = SHA512Digest
    var hash: DataSourceHash { get }

    var item: DataSourceItem { get }
    var points: [DataPoint] { get }

    // Configuration UI
    var configurations: [AnyHashable] { get }
    func content(for dataConfigIndex: Int, from contentConfig: UIListContentConfiguration) -> UIListContentConfiguration
}

class DataProvider {
    static var shared = DataProvider()

    @Published var dataSources: [DataSource] = []

    func add(source: DataSource) {
        dataSources.append(source)
    }

    func add(sources: [DataSource]) {
        dataSources.append(contentsOf: sources)
    }
}
