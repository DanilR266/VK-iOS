final class ReviewsScreenFactory {

    /// Создаёт контроллер списка отзывов, проставляя нужные зависимости.
    func makeReviewsController() -> ReviewsViewController {
        let reviewsProvider = ReviewsProvider.shared
        let photoRequest = ReviewPhotoRequest.shared
        let viewModel = ReviewsViewModel(reviewsProvider: reviewsProvider, photoRequest: photoRequest)
        let controller = ReviewsViewController(viewModel: viewModel)
        return controller
    }

}
