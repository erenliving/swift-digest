//
//  Models.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

import UIKit

struct SwiftSubredditService: Codable {
	var data: SwiftSubredditPageService
	
	struct SwiftSubredditPageService: Codable {
		var after: String
		var before: String?
		var children: [ListingService]
		var dist: Int
		
		struct ListingService: Codable {
			var data: Listing
		}
	}
}

struct SwiftSubredditPage: Codable {
	var after: String
	var before: String?
	var listings: [Listing]
	var recordCount: Int
}

class Listing: Codable {
	
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
	
	func fetchThumbnail(completion: @escaping () -> Void) {
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
				// TODO: handle error
				print("Thumbnail request failed! URL: \(url), Error: \(error)")
				return
			}
			
			guard let data = data,
				let response = response else {
					// TODO: handle error
					print("Error parsing thumbnail data and response!")
					return
			}
			
			// TODO: check response for 200...299 statusCode
			
			guard let image = UIImage(data: data) else {
				print("Error converting thumbnail data to image!")
				return
			}
			
			self.image = image
			DispatchQueue.main.async {
				completion()
			}
		}
		dataTask.resume()
	}
}

extension SwiftSubredditPage {
	init(from service: SwiftSubredditService) {
		self.after = service.data.after
		self.before = service.data.before
		self.recordCount = service.data.dist
		
		self.listings = service.data.children.map { (listingService) -> Listing in
			return listingService.data
		}
	}
}
