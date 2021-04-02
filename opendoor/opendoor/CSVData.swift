//
//  CSVData.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import Foundation
import MapKit

struct PropertyDataPoint: DataPoint {
    var annotation: MKAnnotation
}

class CSVData: DataSource {

    var item: DataSourceItem
    var points: [DataPoint] = []

    var rawData: [[String]]


    /// Creates a CSV type data source from a url of a csv file.
    /// - Parameters:
    ///   - item: The item with meta info about the data source
    ///   - url: File path URL of the csv file
    ///   - titleLinesCount: Number of lines that are titles or column titles
    ///                      (anything that is not the actual data) to drop.
    required init?(_ item: DataSourceItem, url: URL, titleLinesCount: Int) {
        self.item = item

        rawData = Parser.parseCSV(at: url) ?? []

        print("GEO: \(rawData.count) places")

        rawData
            .dropFirst(titleLinesCount)
            .compactMap(PropertyAnnotation.init)
            .map(PropertyDataPoint.init(annotation:))
            .forEach { points.append($0) }
        print("MAP: \(points.count) annotations parsed from places")
    }
}
