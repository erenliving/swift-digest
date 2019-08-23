//
//  ListingCollectionViewCell.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

import UIKit

protocol ArticleCollectionViewCellDelegate: class {
	func cellArticleFetchingThumbnail(_ cell: ArticleCollectionViewCell, article: Article)
}

class ArticleCollectionViewCell: UICollectionViewCell {
	
	static let reuseIdentifier = "ArticleCollectionViewCell"

	@IBOutlet var thumbnailImageView: UIImageView!
	@IBOutlet var dimmingView: UIView!
	@IBOutlet var titleLabel: UILabel!
	
	weak var delegate: ArticleCollectionViewCellDelegate?
	
	private var _article: Article?
	 var article: Article {
		get {
			guard let article = _article else {
				fatalError("Article must be set before trying to get!")
			}
			
			return article
		}
		
		set {
			_article = newValue
		}
	}
	
	func setContent(forArticle article: Article) {
		self.article = article
		
		titleLabel.text = article.title
		
		// TODO: spinner.stopAnimating()
		
		if let image = article.image {
			thumbnailImageView.image = image
		} else if article.hasThumbnail() {
			delegate?.cellArticleFetchingThumbnail(self, article: article)
			
			// TODO: spinner.startAnimating()
			
			article.fetchThumbnail()
		} else {
			thumbnailImageView.image = nil
		}
	}
}
