//
//  PropertyDetailViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 2/26/21.
//

import UIKit

class PropertyDetailViewController: UIViewController {

    lazy var tableView = setupTableView()

    var data: PropertyDataPointsList? { didSet { tableView.reloadData() }}

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutTableView()
    }

    private func setupTableView() -> UITableView {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.dataSource = self
        table.delegate = self
        return table
    }

    private func layoutTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension PropertyDetailViewController: UITableViewDataSource {

    enum PropertyDetailCellType: Int, CaseIterable {
        case dataSource, address, numOfUnits, coordinate
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        data?.list.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PropertyDetailCellType.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let point = data?.list[indexPath.section]

        switch PropertyDetailCellType(rawValue: indexPath.row) {
        case .dataSource:
            cell.textLabel?.text = point?.dataSourceItem?.name
            cell.imageView?.image = UIImage(systemName: "tray.circle")//point?.dataSourceItem?.type.icon
        case .address:
            cell.textLabel?.text = point?.address
            cell.imageView?.image = UIImage(systemName: "location.circle")
        case .numOfUnits:
            cell.textLabel?.text = point?.numOfUnitsLabel
            cell.imageView?.image = data?.annotation?.iconName.flatMap(UIImage.init(systemName:))
        case .coordinate:
            cell.textLabel?.text = point?.coordinate.map { "\($0.latitude), \($0.longitude)" }
            cell.detailTextLabel?.text = cell.textLabel?.text?.isEmpty == false ? "Latitude, Longitude" : nil
            cell.imageView?.image = UIImage(systemName: "mappin.circle")
        default:
            break
        }

        cell.textLabel?.numberOfLines = 0

        return cell
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Tap a row to copy"
    }
}

extension PropertyDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            // Otherwise it doesn't render the selection UI (the gray background)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                tableView.deselectRow(at: indexPath, animated: true)
            }
        }
        guard let text = tableView.cellForRow(at: indexPath)?.textLabel?.text else { return }
        UIPasteboard.general.string = text
    }

}
