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
}

// MARK: IBActions
extension AddressesViewController {
    @IBAction func actionShare(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "TODO!", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        present(alert, animated: true, completion: nil)
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
