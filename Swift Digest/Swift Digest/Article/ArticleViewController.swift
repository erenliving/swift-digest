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
	@IBOutlet var activityIndicator: UIActivityIndicatorView!
	@IBOutlet var bodyLabel: UILabel!
	
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
	
	deinit {
		// Clean up any hanging notification observers
		NotificationCenter.default.removeObserver(self)
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		
		setUpContent()
    }
	
	private func setUpContent() {
		navigationItem.title = article.title
		
		if article.hasThumbnail() {
			if let image = article.image {
				thumbnailImageView.image = image
			} else {
				activityIndicator.startAnimating()
				
				// Add observer to refresh the imageView when image downloads
				NotificationCenter.default.addObserver(self, selector: #selector(articleImageDidDownload(_:)), name: Article.ArticleImageDidDownloadNotification, object: article)
			}
		}
		
		bodyLabel.text = article.body
	}
	
	@objc private func articleImageDidDownload(_ sender: Notification) {
		guard let article = sender.object as? Article else {
			print("Error converting notification's object to Article")
			return
		}
		
		guard let image = article.image else {
			print("Error getting image from article")
			return
		}
		
		activityIndicator.stopAnimating()
		thumbnailImageView.image = image
		NotificationCenter.default.removeObserver(self, name: Article.ArticleImageDidDownloadNotification, object: article)
	}
}
