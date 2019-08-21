//
//  ListingsViewController.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

import UIKit

class ListingsViewController: UIViewController {
	
	private static let baseURL = "https://www.reddit.com/r/swift/.json"

	@IBOutlet private var listingsCollectionView: UICollectionView!
	
	private var listings = [Listing]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		listingsCollectionView.delegate = self
		listingsCollectionView.dataSource = self
		
		listingsCollectionView.register(UINib(nibName: "\(ListingCollectionViewCell.self)", bundle: nil), forCellWithReuseIdentifier: ListingCollectionViewCell.reuseIdentifier)
		
		fetchSwiftSubreddit()
	}
	
	// MARK: - Fetching Swift Subreddit JSON
	
	private func fetchSwiftSubreddit() {
		guard let url = URL(string: ListingsViewController.baseURL) else {
			assertionFailure("Could not create URL!")
			return
		}
		
//		var urlRequest = URLRequest(url: url)
//		urlRequest.httpMethod = "GET"
		
		let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
//		let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			if let error = error {
				// TODO: handle error
				print("Request failed! Error: \(error)")
				return
			}
			
			guard let data = data,
				let response = response else {
					// TODO: handle error
					print("Error parsing data and response!")
					return
			}
			
			// TODO: check response for 200...299 statusCode
			
			do {
				let swiftSubreddit = try JSONDecoder().decode(SwiftSubreddit.self, from: data)
				let listings = swiftSubreddit.data.children
				for listing in listings {
					print("\(listing.data.title) -- \(listing.data.author) -- \(listing.data.selftext)\n")
				}
				
				// Clear previously cached data
				// FIXME: probably want to convert this to an append that has a .contains() check
				self.listings = []
				// Cache parsed results and reload the collectionView
				self.listings = listings
				self.reloadData()
			} catch let decodeError {
				// TODO: handle error
				print(decodeError)
			}
		}
		dataTask.resume()
	}
	
	// MARK: - Refresh UI
	
	private func reloadData() {
		listingsCollectionView.reloadData()
	}
}

extension ListingsViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		// TODO: implement this to handle cells that have images (maintaining image aspect ratio) and titles, or those that just have titles
		return CGSize.zero
	}
}

extension ListingsViewController: UICollectionViewDataSource {
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return listings.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ListingCollectionViewCell.reuseIdentifier, for: indexPath)
		// TODO: set cell's content
		return cell
	}
}
