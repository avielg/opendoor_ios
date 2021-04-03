//
//  DataSourceDetailViewController.swift
//  opendoor
//
//  Created by Aviel Gross on 4/2/21.
//

import UIKit

class DataSourceDetailViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    weak var titleImageView: UIImageView?

    var data: DataSource!

    var dataSource: UICollectionViewDiffableDataSource<ListSection, AnyHashable>!

    enum ListSection { case main }

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(data != nil)

        title = data.item.name

        setupCollectionView()

        guard let navigationBar = self.navigationController?.navigationBar else { return }
        setupTitleImage(in: navigationBar)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        titleImageView?.removeFromSuperview()
    }

}

// MARK: - Update UI
extension DataSourceDetailViewController {
    fileprivate func updateUI() {
        var snapshot = NSDiffableDataSourceSnapshot<ListSection, AnyHashable>()
        snapshot.appendSections([.main])
        snapshot.appendItems(data.configurations, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: viewIfLoaded?.window != nil)
    }
}

// MARK: - Setup UI
extension DataSourceDetailViewController {
    fileprivate func setupCollectionView() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, AnyHashable> { (cell, indexPath, column) in
            cell.contentConfiguration = self.data.content(
                for: indexPath.row,
                from: cell.defaultContentConfiguration()
            )
        }

        let layoutConfig = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let listLayout = UICollectionViewCompositionalLayout.list(using: layoutConfig)
        collectionView.collectionViewLayout = listLayout
//        collectionView.delegate = self

        dataSource = UICollectionViewDiffableDataSource<ListSection, AnyHashable>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: AnyHashable) -> UICollectionViewCell? in
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration,
                                                                for: indexPath,
                                                                item: identifier)
        }
        updateUI()
    }

    fileprivate func setupTitleImage(in navigationBar: UINavigationBar) {
        let imageView = UIImageView(image: data.item.type.icon)
        imageView.contentMode = .scaleAspectFit

        navigationBar.addSubview(imageView)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.rightAnchor.constraint(equalTo: navigationBar.rightAnchor, constant: -16),
            imageView.bottomAnchor.constraint(equalTo: navigationBar.bottomAnchor, constant: -12),
            imageView.heightAnchor.constraint(equalToConstant: 40),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        ])

        titleImageView = imageView
    }
}
