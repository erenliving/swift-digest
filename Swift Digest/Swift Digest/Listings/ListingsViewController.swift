//
//  ListingsViewController.swift
//  Swift Digest
//
//  Created by Eren Livingstone on 2019-08-20.
//  Copyright © 2019 Eren Livingstone. All rights reserved.
//

import UIKit

class ListingsViewController: UIViewController {
	
	private static let showArticleSegueIdentifier = "showArticle" // This should match the segue identifier in Main.storyboard
	private static let baseURL = "https://www.reddit.com/r/swift/.json"

	@IBOutlet private var listingsCollectionView: UICollectionView!
	
	private var listings = [Listing]()
	private var selectedListing: Listing?
	
	private let sectionInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpCollectionView()
		
		fetchSwiftSubreddit()
	}
	
	private func setUpCollectionView() {
		listingsCollectionView.delegate = self
		listingsCollectionView.dataSource = self
		
		listingsCollectionView.register(UINib(nibName: "\(ListingCollectionViewCell.self)", bundle: nil), forCellWithReuseIdentifier: ListingCollectionViewCell.reuseIdentifier)
		
		let refreshControl = UIRefreshControl()
		refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
		refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
		listingsCollectionView.refreshControl = refreshControl
	}
	
	// MARK - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let articleVC = segue.destination as? ArticleViewController,
			let selectedListing = selectedListing {
				articleVC.listing = selectedListing
		}
	}
	
	// MARK: - Fetching Swift Subreddit JSON
	
	private func fetchSwiftSubreddit() {
		guard let url = URL(string: ListingsViewController.baseURL) else {
			assertionFailure("Could not create listing URL!")
			return
		}
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = "GET"
		
		let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			if let error = error {
				// TODO: handle error
				print("Listing request failed! Error: \(error)")
				return
			}
			
			guard let data = data,
				let response = response else {
					// TODO: handle error
					print("Error parsing listing data and response!")
					return
			}
			
			// TODO: check response for 200...299 statusCode
			
			do {
				let swiftSubredditService = try JSONDecoder().decode(SwiftSubredditService.self, from: data)
				let swiftSubredditPage = SwiftSubredditPage(from: swiftSubredditService)
				let listings = swiftSubredditPage.listings
				
				DispatchQueue.main.async { [weak self] in
					guard let strongSelf = self else { return }
					// Clear previously cached data
					// TODO: probably want to convert this to an append that has a .contains() check
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
	
	// MARK: - Refresh Data
	
	@objc private func refreshData(_ sender: Any) {
		fetchSwiftSubreddit()
	}
	
	// MARK: - Refresh UI
	
	private func reloadData() {
		listingsCollectionView.refreshControl?.endRefreshing()
		listingsCollectionView.reloadData()
	}
}

extension ListingsViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
		let cell = collectionView.cellForItem(at: indexPath) as! ListingCollectionViewCell
		cell.dimmingView.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
	}
	
	func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
		let cell = collectionView.cellForItem(at: indexPath) as! ListingCollectionViewCell
		cell.dimmingView.backgroundColor = UIColor(white: 1, alpha: 0.7)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let listing = listings[indexPath.row]
		selectedListing = listing
		
		// Clear the cell selection immediately, so that nothing is selected when user returns to this screen
		listingsCollectionView.deselectItem(at: indexPath, animated: false)
		
		performSegue(withIdentifier: ListingsViewController.showArticleSegueIdentifier, sender: self)
	}
}

extension ListingsViewController: UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let width = UIScreen.main.bounds.width - sectionInsets.left - sectionInsets.right
		
		let listing = listings[indexPath.row]
		let cellMargins: CGFloat = 16 // 8pt margins on each side of cell content
		let titleWidth = width - cellMargins
		let height = listing.title.boundingRect(with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.systemFont(ofSize: 17)], context: nil).height + cellMargins
		
		/**
		If the listing has a thumbnail (and associated height) and the title
		height is < thumbnailHeight, set the height to thumbnailHeight (plus margins)
		*/
		if let thumbnailHeight = listing.thumbnailHeight {
			let paddedThumbnailHeight = CGFloat(thumbnailHeight) + cellMargins
			if height < paddedThumbnailHeight {
				return CGSize(width: width, height: paddedThumbnailHeight)
			}
		}
		
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
		cell.titleLabel.text = listing.title
		
		if let image = listing.image {
			cell.listingImageView.image = image
		} else if listing.hasThumbnail() {
			// FIXME: store the listing.data.id in a dictionary with the indexPath? Then fetch it below in the closure
			// TODO: show a spinner over the image
			listing.fetchThumbnail() { [weak self] in
				guard let strongSelf = self else { return }
				
				strongSelf.listingsCollectionView.reloadItems(at: [indexPath])
			}
		} else {
			cell.listingImageView.image = nil
		}
		
		return cell
	}
}
