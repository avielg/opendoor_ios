//
//  AddressesViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 2/20/21.
//

import UIKit
import MapKit

enum AddressesError: Error {
    case missingValue(MKAnnotation)
    case failedExportingFile
}

class AddressesViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var addresses: [MKAnnotation] = [] {
        didSet {
            self.navigationItem.title = "\(addresses.count) Addresses"
        }
    }

    internal func exportToExcel(result: @escaping (Result<URL, Error>)->()) {
        let rows: [ExcelRow] = addresses.compactMap {
            guard
                let name = $0.title as? String,
                let address = $0.subtitle as? String
            else {
                result(.failure(AddressesError.missingValue($0)))
                return nil
            }
            return ExcelRow([ExcelCell(address), ExcelCell(name)])
        }
        let sheet = ExcelSheet(rows, name: "Properties")
        let name = "philly_\(addresses.count)_addresses"
        ExcelExport.export([sheet], fileName: name) { url in
            guard let path = url else {
                result(.failure(AddressesError.failedExportingFile))
                return
            }
            result(.success(path))
        }
    }

    private func shareFile(_ url: URL, from item: UIBarButtonItem) {
        let excelData = UIDocumentInteractionController(url: url)
        excelData.presentOpenInMenu(from: item, animated: true)
    }

    private func saveFile(_ url: URL, from item: UIBarButtonItem) {
        let controller = UIDocumentPickerViewController(forExporting: [url])
        present(controller, animated: true, completion: nil)
    }
}

// MARK: IBActions
extension AddressesViewController {
    @IBAction func actionShare(_ sender: UIBarButtonItem) {
        exportToExcel {
            guard case .success(let path) = $0 else { return }
            self.shareFile(path, from: sender)
        }
    }

    @IBAction func actionSave(_ sender: UIBarButtonItem) {
        exportToExcel {
            guard case .success(let path) = $0 else { return }
            self.saveFile(path, from: sender)
        }
    }
}

extension AddressesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = addresses[indexPath.row].title ?? "No Name"
        cell.detailTextLabel?.text = addresses[indexPath.row].subtitle ?? "No Address"
        return cell
    }
}
