//
//  DataSourceItem+Display.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import UIKit

extension DataSourceItem.DataType {
    var icon: UIImage {
        switch self {
        case .airTable: return #imageLiteral(resourceName: "airtable-logo")
        case .fileCSV: return #imageLiteral(resourceName: "csv-logo")
        case .googleSheet: return #imageLiteral(resourceName: "gsheet-logo")
        case .postgres: return #imageLiteral(resourceName: "postgres-logo")
        }
    }
}
