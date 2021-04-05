//
//  DataSourceItem.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import Foundation


struct DataSourceItem: Hashable {
    enum DataType {
        case fileCSV, airTable, googleSheet, postgres
    }

    let name: String
    let note: String
    let type: DataType
}
