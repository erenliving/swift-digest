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
	
	private let sectionInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
	
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
				
				DispatchQueue.main.async { [weak self] in
					guard let strongSelf = self else { return }
					// Clear previously cached data
					// FIXME: probably want to convert this to an append that has a .contains() check
					strongSelf.listings = []
					// Cache parsed results and reload the collectionView
					strongSelf.listings = listings
					strongSelf.reloadData()
				}
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
}

extension ListingsViewController: UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		// TODO: implement this to handle cells that have images (maintaining image aspect ratio) and titles, or those that just have titles
		let width = UIScreen.main.bounds.width - sectionInsets.left - sectionInsets.right
		
		let listing = listings[indexPath.row]
		let titleMargins: CGFloat = 16 // 8pt margins on each side of title
		let titleWidth = width - titleMargins
		let height = listing.data.title.boundingRect(with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.systemFont(ofSize: 17)], context: nil).height + titleMargins
		
		return CGSize(width: width, height: height)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return sectionInsets
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
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ListingCollectionViewCell.reuseIdentifier, for: indexPath) as! ListingCollectionViewCell
		
		let listing = listings[indexPath.row]
		cell.titleLabel.text = listing.data.title
		
		return cell
	}
}
