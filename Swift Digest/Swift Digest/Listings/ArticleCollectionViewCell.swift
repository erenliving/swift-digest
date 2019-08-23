//
//  ListingCollectionViewCell.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

import UIKit

class ArticleCollectionViewCell: UICollectionViewCell {
	
	static let reuseIdentifier = "ArticleCollectionViewCell"

	@IBOutlet var thumbnailImageView: UIImageView!
	@IBOutlet var dimmingView: UIView!
	@IBOutlet var titleLabel: UILabel!
	
	override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
}
