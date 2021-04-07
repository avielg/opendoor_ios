//
//  DataSourceConfigViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 4/5/21.
//

import UIKit

class TextViewCell: UICollectionViewListCell {
    static var reuseIdentifier: String = "TextViewCell"

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.text = ""

            textView.isEditable = true
            textView.isScrollEnabled = false

            textView.layer.cornerRadius = 5
            textView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
            textView.layer.borderWidth = 0.5
            textView.clipsToBounds = true

            textView.delegate = self
        }
    }

    var textDidChange: (String)->Void = { _ in }

    override func prepareForReuse() {
        super.prepareForReuse()
        textView.text = ""
    }
}

extension TextViewCell: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        textDidChange(textView.text)
    }
}

class SectionHeaderView: UICollectionReusableView {
    static var reuseIdentifier: String = "SectionHeaderView"

    @IBOutlet weak var label: UILabel!

}

class DataSourceConfigViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!

    var dataSource: UICollectionViewDiffableDataSource<ListSection, ListCell>!

    enum ListSection { case main }

    enum ListCell: Hashable {
        case textView(label: String, valueChange: (String)->Void)
        case dynamicLabel(getter: ()->String)

        static func == (lhs: DataSourceConfigViewController.ListCell, rhs: DataSourceConfigViewController.ListCell) -> Bool {
            switch (lhs, rhs) {
            case (.textView(let l, _), .textView(let r, _)): return l == r
            case (.dynamicLabel(let l), .dynamicLabel(let r)): return l() == r()
            default: return false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .dynamicLabel(let l): hasher.combine(l())
            case .textView(let l, _): hasher.combine(l)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }


    /// Connect and/or query the database
    @IBAction func actionSend(_ sender: UIBarButtonItem) {
        func alert(error: String) {
            let alert = UIAlertController(title: "Can't Connect", message: error, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        }
        guard let connection = postgresConnection() else {
            alert(error: "Make sure you enter a valid URL")
            return
        }

        guard let data = postgresData(with: connection) else {
            alert(error: "Make sure you add comma seperated columns (or empty for *), and table name")
            return
        }

        data.fetchData { points in
            DataProvider.shared.add(source: data)
            dismiss(animated: true, completion: nil)
        }
    }

    var url: String = ""
    var table: String = ""
    var columns: String = ""
    var query: String = ""

    var inputSummary: String { "\(url)\n\nSELECT\n\(columns)\nFROM \(table)\n\(query)" }
}


// MARK: - Update UI
extension DataSourceConfigViewController {
    fileprivate func updateUI() {
        var snapshot = NSDiffableDataSourceSnapshot<ListSection, ListCell>()
        snapshot.appendSections([.main])
        snapshot.appendItems(
            [
                .textView(label: "URL", valueChange: { self.url = $0 }),
                .textView(label: "Table", valueChange: { self.table = $0 }),
                .textView(label: "Columns", valueChange: { self.columns = $0 }),
                .textView(label: "Query", valueChange: { self.query = $0 }),
                .dynamicLabel(getter: { self.inputSummary })
            ], toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: viewIfLoaded?.window != nil)
    }

    fileprivate func postgresConnection() -> PostgresData.Connection? {
        guard let url = URL(string: self.url) else { return nil }
        let connection = PostgresData.Connection(url: url, password: url.password.map { .md5Password(password:$0) } ?? .trust)
        return connection
    }

    fileprivate func postgresData(with connection: PostgresData.Connection) -> PostgresData? {
        let columnsStr = columns
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "*")) // we add it later
        let columnsValues = columnsStr
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .map { Column(title: $0, usage: Column.Usage.possibleUsage(for: $0)) }
        guard
            columnsValues.count > 0 /* explicit columns */ || columnsStr.isEmpty /* will be `*` */,
            !table.isEmpty
        else { return nil }

        let item = DataSourceItem(name: "Postgres DB: \(connection.database) (\(table))", note: "Imported \(Date())", type: .postgres)
        return PostgresData(connection, columns: columnsValues, table: table, query: query, item: item)
    }
}

// MARK: - Setup UI
extension DataSourceConfigViewController {
    fileprivate func setupCollectionView() {
        let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        collectionView.collectionViewLayout = listLayout

        dataSource = UICollectionViewDiffableDataSource<ListSection, ListCell>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: ListCell) -> UICollectionViewCell? in
            switch identifier {
            case .textView(label: let text, valueChange: let handler):
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextViewCell.reuseIdentifier, for: indexPath) as! TextViewCell
                cell.label.text = text
                cell.textDidChange = handler
                return cell
            case .dynamicLabel(_):
                let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ListCell> { (cell, indexPath, item) in
                    guard case .dynamicLabel(getter: let getText) = item else { return }
                    var content = cell.defaultContentConfiguration()
                    content.text = getText()
                    cell.contentConfiguration = content
                }
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
            }
        }
        updateUI()
    }

}
