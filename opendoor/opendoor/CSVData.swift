//
//  CSVData.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import Foundation
import MapKit
import CryptoKit

class CSVData: DataSource {
    var hash: DataSourceHash

    var item: DataSourceItem
    var points: [PropertyDataPoint] = []

    var rawData: [[String]]
    var titleLinesCount = 0

    var columns: [Column] = []
    var configurations: [AnyHashable] { return columns }

    func content(for dataConfigIndex: Int, from contentConfig: UIListContentConfiguration) -> UIListContentConfiguration {
        guard columns.count > dataConfigIndex else { return contentConfig }
        let column = columns[dataConfigIndex]
        var contentConfig = contentConfig
        contentConfig.image = column.icon
        contentConfig.imageProperties.maximumSize.height = 20
        contentConfig.text = column.title

        let contentRows = rawData.dropFirst(titleLinesCount) // remove title
        let exampleRows = contentRows
            .lazy                                       // don't iterate all rows
            .filter {$0.count > dataConfigIndex }       // rows with value for the column
            .map { $0[dataConfigIndex] }                // get the value
            .filter{ !$0.isEmpty }                      // drop if empty string
            .prefix(3)                                  // first (or less) 3 rows
        contentConfig.secondaryText = exampleRows.joined(separator: "\n") + "..."
        return contentConfig
    }

    /// Creates a CSV type data source from a url of a csv file.
    /// - Parameters:
    ///   - item: The item with meta info about the data source
    ///   - url: File path URL of the csv file
    ///   - titleLinesCount: Number of lines that are titles or column titles
    ///                      (anything that is not the actual data) to drop.
    required init?(_ item: DataSourceItem, url: URL, hash: DataSourceHash, titleLinesCount: Int) {
        self.hash = hash
        self.item = item

        rawData = Parser.parseCSV(at: url) ?? []
        self.titleLinesCount = titleLinesCount

        columns = rawData.first?.map { Column(title: $0, usage: Column.Usage.possibleUsage(for: $0)) } ?? []

        print("GEO: \(rawData.count) places")

        let latIndex: Int? = columns.firstIndex { $0.usage == .lat }
        let lonIndex: Int? = columns.firstIndex { $0.usage == .lon }
        let addressIndex: Int? = columns.firstIndex { $0.usage == .address }
        let numOfUnitsIndex: Int? = columns.firstIndex { $0.usage == .numOfUnits }

        rawData
            .dropFirst(self.titleLinesCount)
            .compactMap { data -> PropertyDataPoint in
                let coord: CLLocationCoordinate2D?
                if let latIndex = latIndex, let lonIndex = lonIndex, let lat = Double(data[latIndex]),
                   let lon = Double(data[lonIndex]) {
                    coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                } else {
                    coord = nil
                }

                return PropertyDataPoint(
                    rawData: [:],
                    coordinate: coord,
                    address: addressIndex.map { i in data[i] },
                    numOfUnits: numOfUnitsIndex.map { i in data[i] }.flatMap { Int($0) },
                    dataSourceItem: item
                )
            }
            .forEach { points.append($0) }
        print("MAP: \(points.count) annotations parsed from places")
    }
}

struct Regex: ExpressibleByStringLiteral, Equatable {

    fileprivate let expression: NSRegularExpression

    init(stringLiteral: String) {
        do {
            self.expression = try NSRegularExpression(pattern: stringLiteral, options: [])
        } catch {
            print("Failed to parse (stringLiteral) as a regular expression")
            self.expression = try! NSRegularExpression(pattern: ".*", options: [])
        }
    }

    fileprivate func match(_ input: String) -> Bool {
        let result = expression.rangeOfFirstMatch(
            in: input,
            options: [],
            range: NSRange(input.startIndex..., in: input))
        return !NSEqualRanges(result, NSMakeRange(NSNotFound, 0))
    }
}

extension Regex {
    static func ~=(pattern: Regex, value: String) -> Bool {
        return pattern.match(value)
    }
}

extension UIImage {
  func withAlphaComponent(_ alpha: CGFloat) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }

    draw(at: .zero, blendMode: .normal, alpha: alpha)
    return UIGraphicsGetImageFromCurrentImageContext()
  }
}
