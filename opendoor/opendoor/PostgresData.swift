//
//  PostgresData.swift
//  opendoor
//
//  Created by Aviel Gross on 4/4/21.
//

import Foundation
import PostgresClientKit

class PostgresData {

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

        var host = "localhost"
        var port = 5432
        var ssl = true
        var database = "postgres"
        var user = ""
        var credential = Credential.trust

        init?(url: URL) {
            if let host = url.host { self.host = host }
            if let port = url.port { self.port = port }

            if !url.lastPathComponent.isEmpty { self.database = url.lastPathComponent }

            if let user = url.user { self.user = user }

            if let pass = url.password, !pass.isEmpty {
                let md5pattern: Regex = "^[a-fA-F0-9]{32}$"
                let sha256pattern: Regex = "^[A-Fa-f0-9]{64}$"
                switch pass {
                case md5pattern: self.credential = .md5Password(password: pass)
                case sha256pattern: self.credential = .scramSHA256(password: pass)
                default: self.credential = .cleartextPassword(password: pass)
                }
            }
        }
    }

    var connection: Connection
    var columns: [Column]?
    var table: String
    var query: String

    required init(_ connection: Connection, columns: [Column]?, table: String, query: String) {
        self.connection = connection
        self.columns = columns
        self.table = table
        self.query = query
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

            let cursor = try statement.execute(parameterValues: [])
            defer { cursor.close() }

            for row in cursor {
                let columns = try row.get().columns
                print(columns)
            }
        } catch {
            print(error) // better error handling goes here
        }

    }

}
