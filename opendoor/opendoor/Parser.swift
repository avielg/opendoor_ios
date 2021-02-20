//
//  Parser.swift
//  opendoor
//
//  Created by Aviel Gross on 2/20/21.
//

import Foundation

// Mostly from: https://stackoverflow.com/a/59697231/2242359
class Parser {

    static func openCSV(fileName:String, fileType: String) -> String? {
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
        else { return nil }
        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            return contents
        } catch {
            print("File Read Error for file \(filepath)\nError: \(error)")
            return nil
        }
    }

    private static func getValues(for line: String) -> [String]? {
        guard line != "" else { return nil }

        var values: [String] = []

        if line.range(of: "\"") != nil {
            var textToScan = line
            var value: String?
            var textScanner = Scanner(string: textToScan)
            while !textScanner.isAtEnd {
                if (textScanner.string as NSString).substring(to: 1) == "\"" {


                    textScanner.currentIndex = textScanner.string.index(after: textScanner.currentIndex)

                    value = textScanner.scanUpToString("\"")
                    textScanner.currentIndex = textScanner.string.index(after: textScanner.currentIndex)
                } else {
                    value = textScanner.scanUpToString(",")
                }

                values.append(value ?? "") // some cells are empty, adding ""

                if !textScanner.isAtEnd{
                    let indexPlusOne = textScanner.string.index(after: textScanner.currentIndex)

                    textToScan = String(textScanner.string[indexPlusOne...])
                } else {
                    textToScan = ""
                }
                textScanner = Scanner(string: textToScan)
            }

            // For a line without double quotes, we can simply separate the string
            // by using the delimiter (e.g. comma)
        } else {
            values = line.components(separatedBy: ",")
        }

        // Put the values into the tuple and add it to the items array
        return values

    }

    static func parseCSV(named name: String) -> [[String]]? {
        return openCSV(fileName: name, fileType: "csv")?
            .components(separatedBy: NSCharacterSet.newlines)
            .compactMap(getValues(for:))
    }

}
