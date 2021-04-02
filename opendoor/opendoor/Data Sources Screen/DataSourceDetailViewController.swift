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

    var item: DataSourceItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(item != nil)

        title = item.name

        guard let navigationBar = self.navigationController?.navigationBar else { return }
        setupTitleImage(in: navigationBar)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        titleImageView?.removeFromSuperview()
    }

    func setupTitleImage(in navigationBar: UINavigationBar) {
        let imageView = UIImageView(image: item.type.icon)
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
