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

	@IBOutlet private var articlesCollectionView: UICollectionView!
	
	private var articles = [Article]()
	private var lastSelectedArticle: Article?
	
	private let sectionInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
	
	deinit {
		// Clean up any hanging notification observers
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setUpCollectionView()
		
		fetchListing()
	}
	
	// MARK: - Set up
	
	private func setUpCollectionView() {
		articlesCollectionView.delegate = self
		articlesCollectionView.dataSource = self
		
		articlesCollectionView.register(UINib(nibName: "\(ArticleCollectionViewCell.self)", bundle: nil), forCellWithReuseIdentifier: ArticleCollectionViewCell.reuseIdentifier)
		
		let refreshControl = UIRefreshControl()
		refreshControl.attributedTitle = NSAttributedString(string: "Refreshing")
		refreshControl.addTarget(self, action: #selector(pullToRefresh(_:)), for: .valueChanged)
		articlesCollectionView.refreshControl = refreshControl
	}
	
	// MARK - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let articleVC = segue.destination as? ArticleViewController,
			let selectedListing = lastSelectedArticle {
				articleVC.article = selectedListing
		}
	}
	
	// MARK: - Pull to Refresh
	
	@objc private func pullToRefresh(_ sender: Any) {
		fetchListing()
	}
	
	// MARK: - Fetching Listing JSON
	
	private func fetchListing() {
		guard let url = URL(string: ListingsViewController.baseURL) else {
			assertionFailure("Could not create listing URL!")
			return
		}
		
		articlesCollectionView.refreshControl?.beginRefreshing()
		
		var urlRequest = URLRequest(url: url)
		urlRequest.httpMethod = "GET"
		
		let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
			if let error = error {
				print("Listing request failed! Error: \(error)")
				
				DispatchQueue.main.async {
					self.articlesCollectionView.refreshControl?.endRefreshing()
					
					let alert = UIAlertController(title: "Error", message: "Fetching articles failed, please try again.", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					self.present(alert, animated: true, completion: nil)
				}
				
				return
			}
			
			guard let data = data,
				let response = response else {
					print("Error parsing listing data and response!")
					
					DispatchQueue.main.async {
						self.articlesCollectionView.refreshControl?.endRefreshing()
						
						let alert = UIAlertController(title: "Error", message: "Could not parse response, please try again.", preferredStyle: .alert)
						alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
						self.present(alert, animated: true, completion: nil)
					}
					
					return
			}
			
			if let httpResponse = response as? HTTPURLResponse {
				let statusCode = httpResponse.statusCode
					guard 200...299 ~= statusCode else {
						print("Error non-2xx listing request response statusCode: \(statusCode)")
						
						DispatchQueue.main.async {
							self.articlesCollectionView.refreshControl?.endRefreshing()
							
							let alert = UIAlertController(title: "Error", message: "Network request failed with statusCode \(statusCode), please try again.", preferredStyle: .alert)
							alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
							self.present(alert, animated: true, completion: nil)
						}
						
						return
					}
			}
			
			do {
				let listingService = try JSONDecoder().decode(ListingService.self, from: data)
				let listingPage = ListingPage(from: listingService)
				let articles = listingPage.articles
				
				DispatchQueue.main.async { [weak self] in
					guard let strongSelf = self else { return }
					
					strongSelf.updateArticles(articles)
					strongSelf.articlesCollectionView.refreshControl?.endRefreshing()
					strongSelf.articlesCollectionView.reloadData()
				}
			} catch let decodeError {
				print(decodeError)
				
				DispatchQueue.main.async {
					self.articlesCollectionView.refreshControl?.endRefreshing()
					
					let alert = UIAlertController(title: "Error", message: "Could not decode response data, please try again.", preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
					self.present(alert, animated: true, completion: nil)
				}
			}
		}
		dataTask.resume()
	}
	
	private func updateArticles(_ downloadedArticles: [Article]) {
		for article in downloadedArticles {
			if !articles.contains(article) {
				articles.append(article)
			}
		}
		
		// Sort articles by creationUTC date descending
		articles.sort { (lhs, rhs) -> Bool in
			return lhs.createdUTC > rhs.createdUTC
		}
	}
}

// MARK: - UICollectionViewDelegate

extension ListingsViewController: UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
		let cell = collectionView.cellForItem(at: indexPath) as! ArticleCollectionViewCell
		cell.dimmingView.backgroundColor = UIColor(white: 0.3, alpha: 0.7)
	}
	
	func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
		let cell = collectionView.cellForItem(at: indexPath) as! ArticleCollectionViewCell
		cell.dimmingView.backgroundColor = UIColor(white: 1, alpha: 0.7)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let article = articles[indexPath.row]
		lastSelectedArticle = article
		
		// Clear the cell selection immediately, so that nothing is selected when user returns to this screen
		articlesCollectionView.deselectItem(at: indexPath, animated: false)
		
		performSegue(withIdentifier: ListingsViewController.showArticleSegueIdentifier, sender: self)
	}
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ListingsViewController: UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let width = UIScreen.main.bounds.width - sectionInsets.left - sectionInsets.right
		
		let article = articles[indexPath.row]
		let cellMargins: CGFloat = 16 // 8pt margins on each side of cell content
		let titleWidth = width - cellMargins
		let titleRect = article.title.boundingRect(with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.systemFont(ofSize: 17, weight: .regular)], context: nil) // UIFont size and weight should match ArticleCollectionViewCell.titleLabel font size in its .xib
		let height = ceil(titleRect.height) + cellMargins
		
		/**
		If the article has a thumbnail (and associated height) and the title
		height is < thumbnailHeight, set the height to thumbnailHeight (plus margins)
		*/
		if let thumbnailHeight = article.thumbnailHeight {
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

// MARK: - UICollectionViewDataSource

extension ListingsViewController: UICollectionViewDataSource {
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return articles.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ArticleCollectionViewCell.reuseIdentifier, for: indexPath) as! ArticleCollectionViewCell
		
		let article = articles[indexPath.row]
		
		cell.delegate = self
		cell.setContent(forArticle: article)
		
		return cell
	}
}

// MARK: - ArticleCollectionViewCellDelegate

extension ListingsViewController: ArticleCollectionViewCellDelegate {
	func cellArticleFetchingThumbnail(_ cell: ArticleCollectionViewCell, article: Article) {
		NotificationCenter.default.addObserver(self, selector: #selector(articleImageDidDownload(_:)), name: Article.ArticleImageDidDownloadNotification, object: article)
	}
	
	@objc private func articleImageDidDownload(_ sender: Notification) {
		guard let article = sender.object as? Article else {
			print("Error converting notification's object to Article")
			return
		}
		
		guard let row = articles.firstIndex(where: { $0.id == article.id }) else {
			print("Error finding index of article to reload image")
			return
		}
		
		let indexPath = IndexPath(row: row, section: 0)
		articlesCollectionView.reloadItems(at: [indexPath])
		NotificationCenter.default.removeObserver(self, name: Article.ArticleImageDidDownloadNotification, object: article)
	}
}
