//
//  ListingsViewController.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

import UIKit

class ListingsViewController: UIViewController {

	@IBOutlet var listingsCollectionView: UICollectionView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		listingsCollectionView.delegate = self
	}
}

extension ListingsViewController: UICollectionViewDelegate {
	
}
