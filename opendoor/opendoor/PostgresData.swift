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
    var configurations: [AnyHashable] { columns ?? [] }
    func content(for dataConfigIndex: Int, from contentConfig: UIListContentConfiguration) -> UIListContentConfiguration {
        var contentConfig = contentConfig
        if
            configurations.count > dataConfigIndex,
            let col = configurations[dataConfigIndex] as? Column
        {
            contentConfig.text = col.title
            contentConfig.image = col.icon
        }
        return contentConfig
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

        init?(url: URL, user: String? = nil, password: Credential) {
            if let host = url.host { self.host = host }
            if let port = url.port { self.port = port }

            if !url.lastPathComponent.isEmpty { self.database = url.lastPathComponent }

            if let user = user { self.user = user }
            else if let user = url.user { self.user = user }

            self.credential = password
        }
    }

    var connection: Connection
    var columns: [Column]? = nil
    var query: String

    convenience init(_ connection: Connection, query: String, note: String = "Imported \(Date())") {
        let item = DataSourceItem(name: "Postgres: \(connection.database)", note: note, type: .postgres)
        self.init(connection, query: query, item: item)
    }

    required init(_ connection: Connection, query: String, item: DataSourceItem) {
        self.connection = connection
        self.query = query
        self.item = item

        let hashStr = connection.urlWithoutAuth.absoluteURL.dataRepresentation
        self.hash = SHA512.hash(data: hashStr)

        points = []
    }
    
    func fetchData(handle: ([PropertyDataPoint])-> Void) throws {
        var configuration = PostgresClientKit.ConnectionConfiguration()
        configuration.host = connection.host
        configuration.port = connection.port
        configuration.database = connection.database
        configuration.user = connection.user
        configuration.credential = connection.credential.postgresClientValue
        configuration.applicationName = "opendoor"
        
        let connection = try PostgresClientKit.Connection(configuration: configuration)
        defer { connection.close() }
        
        let statement = try connection.prepareStatement(text: query)
        defer { statement.close() }
        
        let cursor = try statement.execute(parameterValues: [], retrieveColumnMetadata: true)
        defer { cursor.close() }
        
        // Get columns from query result
        if let columnsData = cursor.columns {
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
                case .address: address = try rowValues[col.offset].optionalString()
                case .lat: lat = try rowValues[col.offset].optionalDouble()
                case .lon: lon = try rowValues[col.offset].optionalDouble()
                case .numOfUnits: numOfUnits = try rowValues[col.offset].optionalInt()
                case .none: break
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
    }
}

extension PostgresClientKit.PostgresError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .cleartextPasswordCredentialRequired: return "The Postgres server requires a clear text password for authentication."
        case .connectionClosed: return "An attempt was made to operate on a closed connection."
        case .connectionPoolClosed: return "An attempt was made to operate on a closed connection pool."
        case .cursorClosed: return "An attempt was made to operate on a closed cursor."
        case .invalidParameterValue(let name, let value, let allowedValues): return "The Postgres server has a parameter set to an incompatible value: \(value) (name: \(name), allowed values: \(allowedValues)."
        case .invalidUsernameString: return "The specified username does not meet the SCRAM-SHA-256 requirements for a username."
        case .invalidPasswordString: return "The specified password does not meet the SCRAM-SHA-256 requirements for a password."
        case .md5PasswordCredentialRequired: return "The Postgres server requires a md5 password for authentication."
        case .scramSHA256CredentialRequired: return "The Postgres server requires a scram SHA256 for authentication."
        case .serverError(let description): return "The Postgres server reported an internal error or returned an invalid response: \(description)."
        case .socketError(let cause): return "A network error occurred in communicating with the Postgres server: \(cause.localizedDescription)."
        case .sqlError(let notice): return "The Postgres server reported a SQL error: \(notice.message ?? "")."
        case .sslError(let cause): return "An error occurred in establishing SSL/TLS encryption: \(cause.localizedDescription)."
        case .sslNotSupported: return "The Postgres server does not support SSL/TLS."
        case .statementClosed: return "An attempt was made to operate on a closed statement."
        case .timedOutAcquiringConnection: return "The request for a connection failed because a connection was not allocated before the request timed out."
        case .tooManyRequestsForConnections: return "The request for a connection failed because the request backlog was too large."
        case .trustCredentialRequired: return "The Postgres server requires no credintials (\"trust\") for authentication."
        case .unsupportedAuthenticationType(let authenticationType): return "The following authentication type required by the Postgres server is not supported: \(authenticationType)."
        case .valueConversionError(let value, let type): return "The value: \(value), could not be converted to the requested type: \(type)."
        case .valueIsNil: return "The value is null."
        }
    }
}

extension PostgresData: OpenDoorURLProvider {
    var url: URL? {
        return OpenDoorURLScheme.postgresUrl(
            dbUrl: connection.urlWithoutAuth.absoluteString,
            query: query)
    }
}
