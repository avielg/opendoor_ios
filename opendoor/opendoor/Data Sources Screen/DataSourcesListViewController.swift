//
//  DataSourcesListViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import UIKit
import UniformTypeIdentifiers
import Combine
import CryptoKit

class DataSourcesListViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var barButtonItemAdd: UIBarButtonItem!

    var dataSource: UICollectionViewDiffableDataSource<ListSection, DataSourceItem>!

    var cancellable: AnyCancellable?
    var data = DataProvider.shared.dataSources {
        didSet {
            updateUI()
        }
    }
//    [
//        DataSourceItem(name: "Contacts", note: "Used for single units\nDoes not contain contact data like phone or email.", type: .airTable),
//        DataSourceItem(name: "Multi-Unit Properties", note: "Buildings where we talked to people", type: .airTable),
//        DataSourceItem(name: "Odin CSV", note: "All Oding units, cross referenced with AirTable data", type: .fileCSV),
//        DataSourceItem(name: "Master SOS List", note: "All places to canvass, includes who didn't answer or don't want to talk", type: .googleSheet)
//    ]

    enum ListSection { case main }

    let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, DataSourceItem> { (cell, indexPath, item) in
        var content = cell.defaultContentConfiguration()
        content.image = item.type.icon
        content.imageProperties.maximumSize.height = 20
        content.text = item.name
        content.secondaryText = item.note
        cell.contentConfiguration = content
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupAddMenu()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        for selected in collectionView.indexPathsForSelectedItems ?? [] {
            collectionView.deselectItem(at: selected, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == "showDataSource",
            let detailVC = segue.destination as? DataSourceDetailViewController,
            let item = sender as? DataSourceItem
        {
            detailVC.data = data.first { $0.item == item }
        }
    }
}

// MARK: - Update UI
extension DataSourcesListViewController {
    fileprivate func updateUI() {
        var snapshot = NSDiffableDataSourceSnapshot<ListSection, DataSourceItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(data.map { $0.item }, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: viewIfLoaded?.window != nil)
    }
}

// MARK: - Setup UI
extension DataSourcesListViewController {
    fileprivate func setupCollectionView() {
        let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        collectionView.collectionViewLayout = listLayout
        collectionView.delegate = self

        dataSource = UICollectionViewDiffableDataSource<ListSection, DataSourceItem>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: DataSourceItem) -> UICollectionViewCell? in
            let cell = collectionView.dequeueConfiguredReusableCell(using: self.cellRegistration,
                                                                    for: indexPath,
                                                                    item: identifier)
            cell.accessories = [.disclosureIndicator()]
            return cell
        }
        cancellable = DataProvider.shared.$dataSources.assign(to: \.data, on: self)
    }

    fileprivate func setupAddMenu() {
        let addCSVHandler: UIActionHandler = { _ in
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.commaSeparatedText], asCopy: true)
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
        let connectPostgresHandler: UIActionHandler = { _ in
            self.performSegue(withIdentifier: "dataSourceConfig", sender: self)
        }

        barButtonItemAdd.menu = UIMenu(title: "", children: [
            UIAction(title: "Import CSV File", image: DataSourceItem.DataType.fileCSV.icon, handler: addCSVHandler),
            UIAction(title: "Connect Postgres", image: DataSourceItem.DataType.googleSheet.icon, handler: connectPostgresHandler)
        ])
    }
}

// MARK: - DocumentPicker Delegate
extension DataSourcesListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        func errorAlert(message: String) {
            let controller = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            self.present(controller, animated: true, completion: nil)
        }

        var dataSources = [CSVData]()

        for url in urls {
            guard
                FileManager.default.fileExists(atPath: url.path)
            else {
                errorAlert(message: "Can't find file at path, did you move or delete it?")
                continue
            }

            let fileData: Data
            do {
                fileData = try Data(contentsOf: url)
            } catch {
                errorAlert(message: error.localizedDescription)
                continue
            }

            let hash = SHA512.hash(data: fileData)
            guard
                !DataProvider.shared.dataSources.contains(where: { source in source.hash == hash })
            else {
                errorAlert(message: "Same data source already exists. Did you already add this file?")
                continue
            }

            guard
                let csvData = CSVData(
                    DataSourceItem(name: url.lastPathComponent, note: "Imported \(Date())", type: .fileCSV),
                    url: url,
                    hash: hash,
                    titleLinesCount: 1)
            else {
                errorAlert(message: "Can't parse file, is it a valid CSV file?")
                continue
            }
            dataSources.append(csvData)
        }

        if !dataSources.isEmpty {
            DataProvider.shared.add(sources: dataSources)
        }
    }
}

// MARK: - CollectionView Delegate
extension DataSourcesListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedItem = dataSource.itemIdentifier(for: indexPath) else {
            collectionView.deselectItem(at: indexPath, animated: true)
            return
        }
        performSegue(withIdentifier: "showDataSource", sender: selectedItem)
    }
}
