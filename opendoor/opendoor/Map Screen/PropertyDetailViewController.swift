//
//  PropertyDetailViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 2/26/21.
//

import UIKit

class PropertyDetailViewController: UIViewController {

    lazy var tableView = setupTableView()

    var data: [String] = [] { didSet { tableView.reloadData() }}

    override func viewDidLoad() {
        super.viewDidLoad()
        layoutTableView()
    }

    private func setupTableView() -> UITableView {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}



