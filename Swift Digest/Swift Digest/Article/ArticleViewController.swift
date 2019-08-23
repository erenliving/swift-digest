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

    override func viewDidLoad() {
        super.viewDidLoad()
		
		navigationItem.title = article.title
		
		if article.hasThumbnail(),
			let image = article.image {
				thumbnailImageView.image = image
		}
		
		bodyLabel.text = article.body
    }
}
