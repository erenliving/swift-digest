//
//  Models.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

import UIKit

struct ListingService: Codable {
	var data: ListingPageService
	
	struct ListingPageService: Codable {
		var after: String
		var before: String?
		var children: [ArticleService]
		var dist: Int
		
		struct ArticleService: Codable {
			var data: Article
		}
	}
}

struct ListingPage: Codable {
	var after: String
	var before: String?
	var articles: [Article]
	var recordCount: Int
}

extension ListingPage {
	init(from service: ListingService) {
		self.after = service.data.after
		self.before = service.data.before
		self.recordCount = service.data.dist
		
		self.articles = service.data.children.map { (articleService) -> Article in
			return articleService.data
		}
	}
}

class Article: Codable {
	
	static let ArticleImageDidDownloadNotification = Notification.Name(rawValue: "ArticleImageDidDownloadNotification")
	
	enum CodingKeys: String, CodingKey {
//		case author
		case body = "selftext"
//		case created
		case createdUTC = "created_utc"
		case id
//		case numComments = "num_comments"
		case title
		case thumbnail
		case thumbnailHeight = "thumbnail_height"
		case thumbnailWidth = "thumbnail_width"
	}
	
//	var author: String
	var body: String
//	var created: Double
	var createdUTC: Double
	var id: String
	var image: UIImage?
//	var numComments: Int
	var title: String
	var thumbnail: String?
	var thumbnailHeight: Double?
	var thumbnailWidth: Double?
	
	// MARK: Thumbnails
	
	func hasThumbnail() -> Bool {
		if let thumbnail = thumbnail,
			let thumbnailHeight = thumbnailHeight,
			let thumbnailWidth = thumbnailWidth {
			return !thumbnail.isEmpty && thumbnailHeight > 0 && thumbnailWidth > 0
		}
		
		return false
	}
	
	func fetchThumbnail() {
		// Check that the image is nil and there is an actual thumbnail to download
		guard image == nil,
			hasThumbnail(),
			let thumbnail = self.thumbnail else { return }
		
		guard let url = URL(string: thumbnail) else {
			assertionFailure("Could not create thumbnail URL!")
			return
		}
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = "GET"
		
		let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			if let error = error {
				print("Thumbnail request failed! URL: \(url), Error: \(error)")
				return
			}
			
			guard let data = data,
				let response = response else {
					print("Error parsing thumbnail data and response!")
					return
			}
			
			if let httpResponse = response as? HTTPURLResponse {
				let statusCode = httpResponse.statusCode
				guard 200...299 ~= statusCode else {
					print("Error non-2xx thumbnail request response statusCode: \(statusCode)")
					return
				}
			}
			
			guard let image = UIImage(data: data) else {
				print("Error converting thumbnail data to image!")
				return
			}
			
			self.image = image
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Article.ArticleImageDidDownloadNotification, object: self, userInfo: nil)
			}
		}
		dataTask.resume()
	}
}
