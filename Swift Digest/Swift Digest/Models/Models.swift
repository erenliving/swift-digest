//
//  Models.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

struct SwiftSubreddit: Codable {
	var data: SwiftSubredditPage
//	var kind: String
}

struct SwiftSubredditPage: Codable {
	var after: String
	var before: String?
	var children: [Listing]
	var dist: Int
//	var modhash: String
}

struct Listing: Codable {
	var data: ListingData
//	var kind: String
}

struct ListingData: Codable {
	var author: String
//	var created: Double
	var createdUTC: Double
	var numComments: Int
	var selftext: String
	var title: String
	
	enum CodingKeys: String, CodingKey {
		case author
//		case created
		case createdUTC = "created_utc"
		case numComments = "num_comments"
		case selftext
		case title
	}
}