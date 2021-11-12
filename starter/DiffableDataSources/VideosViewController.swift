/// Copyright (c) 2020 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import SafariServices

class VideosViewController: UICollectionViewController {
	enum Section {
		// UICollectionViewDiffableDataSource을 구성하기 위함
		case main
	}
		
	// MARK: - Properties
	
	private var videoList = Video.allVideos
	private lazy var dataSource = makeDataSource()	// 반드시 lazy로 설정해야 한다. VC가 makeDataSource를 호출하기 전에 초기화되기 때문.
	private var searchController = UISearchController(searchResultsController: nil)
	
	// MARK: - Value Types
	
	typealias DataSource = UICollectionViewDiffableDataSource<Section, Video>
	typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Video>
	// NSDiffableDataSourceSnapshot stores your sections and items, which the diffable data source references to understand how many sections and cells to display
	
	// MARK: - Life Cycles
	
	override func viewDidLoad() {
		// 이 프로젝트는 스토리보드에 cell이 있기때문에 register 코드가 없는데, 코드베이스라면 register을 해야한다.
		// 또는 Diffable Datasource를 만들때 UICollectionView.CellRegistration을 이용하는 방법도 있다.
		super.viewDidLoad()
		view.backgroundColor = .white
		configureSearchController()
		configureLayout()
		applySnapshot(animatingDifferences: false)
	}
	
	// MARK: - Functions
	
	func makeDataSource() -> DataSource {
		// collectionView와 video(모델)을 이용하여 dataSource를 만든다. 이로써 아래의 UICollectionViewDataSource 메서드를 대체할 수 있다.(주석처리)
		let dataSource: DataSource = .init(collectionView: collectionView) { collectionView, indexPath, video in
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoCollectionViewCell.identifier, for: indexPath) as? VideoCollectionViewCell
			cell?.video = video
			return cell
		}
		return dataSource
	}
	
	func applySnapshot(animatingDifferences: Bool = true) {
		// Apply a snapshot to the data source.
		// The method takes a Boolean which determines if changes to the data source should animate.
		var snapshot = Snapshot()
		snapshot.appendSections([.main])
		snapshot.appendItems(videoList, toSection: nil)
		DispatchQueue.main.async {
			// apply는 메인쓰레드에서 돌리는게 안전할듯?
			self.dataSource.apply(snapshot, animatingDifferences: animatingDifferences, completion: nil)	// animatingDifferences를 false로 주면 애니메이션을 하지 않는다.
		}
	}
}

/*
// MARK: - UICollectionViewDataSource
extension VideosViewController {
	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return videoList.count
	}
	
	override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as? VideoCollectionViewCell else {
			return UICollectionViewCell()
		}
		
		let video = videoList[indexPath.row]
		cell.video = video
		return cell
	}
}
*/

// MARK: - UICollectionViewDelegate
extension VideosViewController {
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		// let video = videoList[indexPath.row]  아래로 대체
		guard let video = dataSource.itemIdentifier(for: indexPath) else { return }
		guard let link = video.link else {
			print("Invalid link")
			return
		}
		let safariViewController = SFSafariViewController(url: link)
		present(safariViewController, animated: true, completion: nil)
	}
}

// MARK: - UISearchResultsUpdating Delegate
extension VideosViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		videoList = filteredVideos(for: searchController.searchBar.text)
		applySnapshot(animatingDifferences: true)
		//collectionView.reloadData() -> NSDiffableDataSourceSnapshot을 쓰면 더 이상 이 코드는 동작하지 않음.
	}
	
	func filteredVideos(for queryOrNil: String?) -> [Video] {
		let videos = Video.allVideos
		guard let query = queryOrNil, !query.isEmpty else {
			return videos
		}
		return videos.filter {
			return $0.title.lowercased().contains(query.lowercased())
		}
	}
	
	func configureSearchController() {
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		searchController.searchBar.placeholder = "Search Videos"
		navigationItem.searchController = searchController
		definesPresentationContext = true
	}
}

// MARK: - Layout Handling
extension VideosViewController {
	private func configureLayout() {
		collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
			let isPhone = layoutEnvironment.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiom.phone
			let size = NSCollectionLayoutSize(
				widthDimension: NSCollectionLayoutDimension.fractionalWidth(1),
				heightDimension: NSCollectionLayoutDimension.absolute(isPhone ? 280 : 250)
			)
			let itemCount = isPhone ? 1 : 3
			let item = NSCollectionLayoutItem(layoutSize: size)
			let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: itemCount)
			let section = NSCollectionLayoutSection(group: group)
			section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
			section.interGroupSpacing = 10
			return section
		})
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		coordinator.animate(alongsideTransition: { context in
			self.collectionView.collectionViewLayout.invalidateLayout()
		}, completion: nil)
	}
}

// MARK: - SFSafariViewControllerDelegate Implementation
extension VideosViewController: SFSafariViewControllerDelegate {
	func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
		controller.dismiss(animated: true, completion: nil)
	}
}
