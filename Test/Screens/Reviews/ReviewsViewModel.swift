import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?
    
    private let queueRewiews = DispatchQueue(label: "com.reviews", attributes: .concurrent)

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let decoder: JSONDecoder
    private let photoRequest: ReviewPhotoRequest

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider,
        decoder: JSONDecoder = JSONDecoder(),
        photoRequest: ReviewPhotoRequest
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.decoder = decoder
        self.photoRequest = photoRequest
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        queueRewiews.async { [weak self] in
            guard let self else { return }
            reviewsProvider.getReviews(offset: self.state.offset, completion: gotReviews)
        }
    }

}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            state.items += reviews.items.map(makeReviewItem)
            state.offset += state.limit
            state.shouldLoad = state.offset < reviews.count
            if !state.shouldLoad {
                let rv = ReviewCountItem(reviewCount: state.items.count)
                state.items.append(rv)
            }
        } catch {
            state.shouldLoad = true
        }
        onStateChange?(state)
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewItem)?.id == id }),
            var item = state.items[index] as? ReviewItem
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }

}

// MARK: - Items

private extension ReviewsViewModel {

    typealias ReviewItem = ReviewCellConfig

    func makeReviewItem(_ review: Review) -> ReviewItem {
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let firstName = review.first_name.attributed(font: .username)
        let lastName = review.last_name.attributed(font: .username)
        let reviewerNameText = NSMutableAttributedString()
        reviewerNameText.append(firstName)
        reviewerNameText.append(NSAttributedString(string: " "))
        reviewerNameText.append(lastName)
        let rating = review.rating
        let reviewCount = state.items.count
        var reviewImages = [UIImage]()
        
        let item = ReviewItem(
            reviewText: reviewText,
            reviewerNameText: reviewerNameText,
            created: created,
            rating: rating,
            onTapShowMore: { [weak self] id in
                self?.showMoreReview(with: id)
            },
            reviewCount: reviewCount,
            reviewImage: reviewImages.isEmpty ? nil : reviewImages
        )
        
        if let photoURLs = review.photo_urls {
            for urlString in photoURLs {
                ReviewPhotoRequest.shared.getReviewPhoto(from: urlString) { [weak self] result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let data):
                            if let image = UIImage(data: data) {
                                reviewImages.append(image)
                            }
                        case .failure:
                            break
                        }
                        if reviewImages.count == photoURLs.count {
                            print("Photo load")
                            self?.onStateChange!(self!.state)
//                            self?.updateReviewItem(item, with: reviewImages)
                        }
                    }
                }
            }
        }
        return item
    }
}

private extension ReviewsViewModel {

    typealias ReviewCountItem = ReviewCountConfig

    func makeReviewItem(_ review: ReviewCount) -> ReviewCountItem {
        let reviewCount = review.count
        
        let item = ReviewCountItem(
            reviewCount: reviewCount
        )
        return item
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
