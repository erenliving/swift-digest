//
//  ArticleViewController.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

import UIKit

class ArticleViewController: UIViewController {
	
	@IBOutlet var thumbnailImageView: UIImageView!
	@IBOutlet var bodyLabel: UILabel!
	
	private var _listing: Listing?
	var listing: Listing {
		get {
			guard let listing = _listing else {
				fatalError("Listing must be set before trying to get!")
			}
			
			return listing
		}
		
		set {
			_listing = newValue
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationItem.title = listing.title
		
		if listing.hasThumbnail(),
			let image = listing.image {
				thumbnailImageView.image = image
		}
		
		bodyLabel.text = listing.body
    }
}
