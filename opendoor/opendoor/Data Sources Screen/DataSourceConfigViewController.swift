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
            textView.isEditable = true
            textView.isScrollEnabled = false

            textView.layer.cornerRadius = 5
            textView.layer.borderColor = UIColor.gray.withAlphaComponent(0.5).cgColor
            textView.layer.borderWidth = 0.5
            textView.clipsToBounds = true
        }
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
    enum ListCell: Hashable { case textView(label: String, value: String) }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }

}


// MARK: - Update UI
extension DataSourceConfigViewController {
    fileprivate func updateUI() {
        var snapshot = NSDiffableDataSourceSnapshot<ListSection, ListCell>()
        snapshot.appendSections([.main])
        snapshot.appendItems(
            [
                .textView(label: "URL", value: ""),
                .textView(label: "Table", value: ""),
                .textView(label: "Columns", value: ""),
                .textView(label: "Query", value: "")
            ], toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: viewIfLoaded?.window != nil)
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

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextViewCell.reuseIdentifier, for: indexPath) as! TextViewCell

            switch identifier {
            case .textView(label: let text, value: let val):
                cell.label.text = text
                cell.textView.text = val
            }

            return cell

        }
        updateUI()
    }

}
