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
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            setupCollectionView()
        }
    }

    var dataSource: UICollectionViewDiffableDataSource<ListSection, ListCell>!

    enum ListSection { case main }

    enum ListCell: Hashable {
        case textView(label: String, value: String, valueChange: (String)->Void)
        case dynamicLabel(getter: ()->String)
        case textLabel(String)

        static func == (lhs: DataSourceConfigViewController.ListCell, rhs: DataSourceConfigViewController.ListCell) -> Bool {
            switch (lhs, rhs) {
            case (.textView(let l, let vl, _), .textView(let r, let vr, _)): return l == r && vl == vr
            case (.dynamicLabel(let l), .dynamicLabel(let r)): return l() == r()
            case (.textLabel(let l), .textLabel(let r)): return l == r
            default: return false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .dynamicLabel(let l): hasher.combine(l())
            case .textView(let l, let v, _): hasher.combine(l); hasher.combine(v)
            case .textLabel(let l): hasher.combine(l)
            }
        }
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            segue.identifier == "showTextView",
            let item = sender as? ListCell,
            case .textView(let text, value: let value, let valueChange) = item,
            let textVC = segue.destination as? TextViewController
        {
            textVC.navigationItem.title = text
            textVC.value = value
            textVC.handleDismissWithValue = valueChange
        }
    }

    var url: String = "" { didSet { updateUI() } }
    var query: String = "" { didSet { updateUI() } }
}


// MARK: - Update UI
extension DataSourceConfigViewController {
    fileprivate func updateUI() {
        var snapshot = NSDiffableDataSourceSnapshot<ListSection, ListCell>()
        snapshot.appendSections([.main])
        snapshot.appendItems(
            [
                .textView(label: "URL", value: url, valueChange: { [weak self] in self?.url = $0 }),
                .textView(label: "Query", value: query, valueChange: { [weak self] in self?.query = $0 }),
            ], toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: viewIfLoaded?.window != nil)
    }

    fileprivate func postgresConnection() -> PostgresData.Connection? {
        guard let url = URL(string: self.url) else { return nil }
        let connection = PostgresData.Connection(url: url, password: url.password.map { .md5Password(password:$0) } ?? .trust)
        return connection
    }

    fileprivate func postgresData(with connection: PostgresData.Connection) -> PostgresData? {
        guard !query.isEmpty else { return nil }
        return PostgresData(connection, query: query)
    }
}

// MARK: - Setup UI
extension DataSourceConfigViewController {
    fileprivate func setupCollectionView() {
        collectionView.delegate = self

        let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        collectionView.collectionViewLayout = listLayout

        dataSource = UICollectionViewDiffableDataSource<ListSection, ListCell>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: ListCell) -> UICollectionViewCell? in

            let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, ListCell> { (cell, indexPath, item) in
                var content = cell.defaultContentConfiguration()
                switch identifier {
                case .textView(let text, let value, _):
                    content.text = text
                    content.secondaryText = value
                case .dynamicLabel(getter: let getText):
                    content.text = getText()
                case .textLabel(let text):
                    content.text = text
                }
                content.secondaryTextProperties.font = UIFont(name: "Menlo Regular", size: 13) ?? content.secondaryTextProperties.font
                content.textProperties.font = .boldSystemFont(ofSize: content.textProperties.font.pointSize)
                cell.contentConfiguration = content
            }
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
        updateUI()
    }
}

extension DataSourceConfigViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = dataSource.snapshot().itemIdentifiers[indexPath.row]
        guard case .textView(_, _, _) = item else { return }
        performSegue(withIdentifier: "showTextView", sender: item)
    }
}
