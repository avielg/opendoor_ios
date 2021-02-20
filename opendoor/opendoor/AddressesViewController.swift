//
//  AddressesViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 2/20/21.
//

import UIKit
import MapKit

class AddressesViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!

    var addresses: [MKAnnotation] = [] {
        didSet {
            self.navigationItem.title = "\(addresses.count) Addresses"
        }
    }

    internal func presentShare(from item: UIBarButtonItem, then: @escaping ()->()) {
        let rows: [ExcelRow] = addresses.compactMap {
            guard
                let name = $0.title as? String,
                let address = $0.subtitle as? String
            else {
                print("Error: No values in \($0)")
                return nil
            }
            return ExcelRow([ExcelCell(address), ExcelCell(name)])
        }
        let sheet = ExcelSheet(rows, name: "Properties")
        let name = "philly_\(addresses.count)_addresses.xls"
        ExcelExport.export([sheet], fileName: name) { url in
            guard let path = url else { return }
            self.shareData(path, from: item)
            then()
        }
    }

    private func shareData(_ dataPathToShare: URL, from item: UIBarButtonItem) {
        let excelData = UIDocumentInteractionController(url: dataPathToShare)
        excelData.presentOptionsMenu(from: item, animated: true)
    }
}

// MARK: IBActions
extension AddressesViewController {
    @IBAction func actionShare(_ sender: UIBarButtonItem) {
        sender.isEnabled = false // avoid "abuse" clicking
        presentShare(from: sender) { sender.isEnabled = true }
    }
}

extension AddressesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = addresses[indexPath.row].subtitle ?? "No Address"
        cell.detailTextLabel?.text = addresses[indexPath.row].title ?? "No Name"
        return cell
    }
}
