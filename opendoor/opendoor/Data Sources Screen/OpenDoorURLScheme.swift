//
//  OpenDoorURLScheme.swift
//  opendoor
//
//  Created by Aviel Gross on 4/24/21.
//

import Foundation

protocol OpenDoorURLProvider {
    var url: URL? { get }
}

private extension String {
    var asBase64: String? {
        let utf8str = data(using: .utf8)
        return utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
    }

    var fromBase64: String? {
        return
            Data(base64Encoded: self, options: Data.Base64DecodingOptions(rawValue: 0))
            .flatMap({ String(data: $0, encoding: .utf8) })
    }

    var escapedEncoded: String? {
        return self
            .asBase64?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    var unescapedDecoded: String? {
        return self.removingPercentEncoding?.fromBase64
    }
}


struct OpenDoorURLScheme {
    enum Host: String { case add = "add" }
    enum Path: String { case postgres = "/postgres" }

    static func url(host: Host, path: Path, query: [URLQueryItem]) -> URL? {
        var comps = URLComponents()
        comps.scheme = "opendoor"
        comps.host = host.rawValue
        comps.path = path.rawValue
        comps.queryItems = query
        return comps.url
    }
}

extension OpenDoorURLScheme {
    static func postgresUrl(dbUrl: String, query: String) -> URL? {
        guard
            let encodedDbUrl = dbUrl.escapedEncoded,
            let encodedQuery = query.escapedEncoded
        else {
            return nil
        }

        return OpenDoorURLScheme.url(
            host: .add,
            path: .postgres,
            query: [
                .init(name: "url", value: encodedDbUrl),
                .init(name: "query", value: encodedQuery)
            ]
        )
    }

    static func postgresDbUrlAndQuery(from url: URL) -> (String, String)? {
        let items: [(String,String)] = url
            .query?
            .components(separatedBy: "&")
            .map { $0.components(separatedBy: "=") }
            .compactMap { $0.count == 2 ? ($0[0],$0[1]) : nil }
            ?? []

        let find: (String)->String? = { key in
            items
                .first(where: { $0.0 == key })
                .map({ $0.1 })
        }

        if let dbUrl = find("url")?.unescapedDecoded, let query = find("query")?.unescapedDecoded {
            return (dbUrl, query)
        }
        return nil
    }
}
