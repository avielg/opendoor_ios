//
//  PostgresData.swift
//  opendoor
//
//  Created by Aviel Gross on 4/4/21.
//

import Foundation
import PostgresClientKit
import MapKit
import CryptoKit

class PostgresData: DataSource {

    var hash: DataSourceHash

    var item: DataSourceItem
    var points: [PropertyDataPoint]

    // Configuration UI
    var configurations: [AnyHashable] = [] // TODO
    func content(for dataConfigIndex: Int, from contentConfig: UIListContentConfiguration) -> UIListContentConfiguration {
        return contentConfig // TODO
    }


    struct Connection {
        public enum Credential {
            case trust
            case cleartextPassword(password: String)
            case md5Password(password: String)
            case scramSHA256(password: String)

            var postgresClientValue: PostgresClientKit.Credential {
                switch self {
                case .trust: return .trust
                case .cleartextPassword(password: let pass): return .cleartextPassword(password: pass)
                case .md5Password(password: let pass): return .md5Password(password: pass)
                case .scramSHA256(password: let pass): return .scramSHA256(password: pass)
                }
            }
        }

        private(set) var host = "localhost"
        private(set) var port = 5432
        private(set) var ssl = true
        private(set) var database = "postgres"
        private(set) var user = ""
        private(set) var credential = Credential.trust

        var urlWithoutAuth: URL {
            var comps = URLComponents()
            comps.host = host
            comps.port = port
            comps.path = "/" + database
            comps.scheme = "postgres"
            return comps.url! // init takes URL so we must be able to re-compose it
        }

        init?(url: URL) {
            let credential: Credential
            if let pass = url.password, !pass.isEmpty {
                let md5pattern: Regex = "^[a-fA-F0-9]{32}$"
                let sha256pattern: Regex = "^[A-Fa-f0-9]{64}$"
                switch pass {
                case md5pattern: credential = .md5Password(password: pass)
                case sha256pattern: credential = .scramSHA256(password: pass)
                default: credential = .cleartextPassword(password: pass)
                }
            } else {
                credential = .trust
            }
            self.init(url: url, password: credential)
        }

        init?(url: URL, password: Credential) {
            if let host = url.host { self.host = host }
            if let port = url.port { self.port = port }

            if !url.lastPathComponent.isEmpty { self.database = url.lastPathComponent }

            if let user = url.user { self.user = user }

            self.credential = password
        }
    }

    var connection: Connection
    var columns: [Column]?
    var table: String
    var query: String

    required init(_ connection: Connection, columns: [Column]?, table: String, query: String, item: DataSourceItem) {
        self.connection = connection
        self.columns = columns?.isEmpty == true ? nil : columns
        self.table = table
        self.query = query
        self.item = item

        let hashStr = connection.urlWithoutAuth.absoluteURL.dataRepresentation
        self.hash = SHA512.hash(data: hashStr)

        points = []
    }

    func fetchData(handle: ([PropertyDataPoint])-> Void) {
        do {
            var configuration = PostgresClientKit.ConnectionConfiguration()
            configuration.host = connection.host
            configuration.port = connection.port
            configuration.database = connection.database
            configuration.user = connection.user
            configuration.credential = connection.credential.postgresClientValue
            configuration.applicationName = "opendoor"

            let connection = try PostgresClientKit.Connection(configuration: configuration)
            defer { connection.close() }

            let columnsQuery = columns?.map{ $0.title }.joined(separator: ", ") ?? "*"
            let text = """
                SELECT \(columnsQuery) FROM \(table)
                \(query)
            """
            let statement = try connection.prepareStatement(text: text)
            defer { statement.close() }

            let cursor = try statement.execute(parameterValues: [], retrieveColumnMetadata: columnsQuery == "*")
            defer { cursor.close() }

            // Get columns from query result if not provided with the query
            if columnsQuery == "*", let columnsData = cursor.columns {
                self.columns = columnsData.map {
                    Column(title: $0.name, usage: Column.Usage.possibleUsage(for: $0.name))
                }
            }

            var result = [PropertyDataPoint]()

            for row in cursor {
                var lat: Double?
                var lon: Double?
                var address: String?
                var numOfUnits: Int?

                var rawDict = [String: String]()

                let rowValues = try row.get().columns

                for col in self.columns!.enumerated() {
                    rawDict[col.element.title] = try rowValues[col.offset].optionalString()

                    switch col.element.usage {
                    case .address:
                        address = try rowValues[col.offset].optionalString()
                    case .lat:
                        lat = try rowValues[col.offset].optionalDouble()
                    case .lon:
                        lon = try rowValues[col.offset].optionalDouble()
                    case .numOfUnits:
                        numOfUnits = try rowValues[col.offset].optionalInt()
                    case .none:
                        break
                    }
                }

                var coord: CLLocationCoordinate2D? = nil
                if let lat = lat, let lon = lon {
                    coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }

                let point = PropertyDataPoint(rawData: rawDict, coordinate: coord, address: address, numOfUnits: numOfUnits, dataSourceItem: self.item)
                result.append(point)
            }
            points = result
            handle(points)
        } catch {
            print(error) // better error handling goes here
            handle([])
        }

    }

}
