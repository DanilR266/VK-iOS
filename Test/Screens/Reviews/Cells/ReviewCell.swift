import UIKit

/// Конфигурация ячейки. Содержит данные для отображения в ячейке.
struct ReviewCellConfig {

    /// Идентификатор для переиспользования ячейки.
    static let reuseId = String(describing: ReviewCellConfig.self)

    /// Идентификатор конфигурации. Можно использовать для поиска конфигурации в массиве.
    let id = UUID()
    /// Текст отзыва.
    let reviewText: NSAttributedString
    /// Имя оставившего отзыв
    let reviewerNameText: NSAttributedString
    /// Максимальное отображаемое количество строк текста. По умолчанию 3.
    var maxLines = 3
    /// Время создания отзыва.
    let created: NSAttributedString
    /// Рейтинг
    let rating: Int
    /// Замыкание, вызываемое при нажатии на кнопку "Показать полностью...".
    let onTapShowMore: (UUID) -> Void
    /// Количество отзывов
    let reviewCount: Int
    /// Фото отзыва
    let reviewImage: [UIImage]

    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()

}

struct ReviewCountConfig {
    
    static let reuseId = String(describing: ReviewCountConfig.self)
    
    /// Количество отзывов
    let reviewCount: Int
    /// Объект, хранящий посчитанные фреймы для ячейки отзыва.
    fileprivate let layout = ReviewCellLayout()
}

// MARK: - TableCellConfig

extension ReviewCellConfig: TableCellConfig {

    /// Метод обновления ячейки.
    /// Вызывается из `cellForRowAt:` у `dataSource` таблицы.
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCell else { return }
        cell.reviewTextLabel.attributedText = reviewText
        cell.reviewTextLabel.numberOfLines = maxLines
        cell.createdLabel.attributedText = created
        cell.reviewerNameLabel.attributedText = reviewerNameText
        cell.setImagesPhotoStack(reviewImage)
        cell.config = self
    }

    /// Метод, возвращаюший высоту ячейки с данным ограничением по размеру.
    /// Вызывается из `heightForRowAt:` делегата таблицы.
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }

}

extension ReviewCountConfig: TableCellConfig {
    
    func update(cell: UITableViewCell) {
        guard let cell = cell as? ReviewCountCell else { return }
        cell.reviewCountLabel.text = "\(reviewCount) reviews"
        cell.config = self
    }
    
    func height(with size: CGSize) -> CGFloat {
        layout.height(config: self, maxWidth: size.width)
    }
    
}

// MARK: - Private

private extension ReviewCellConfig {

    /// Текст кнопки "Показать полностью...".
    static let showMoreText = "Показать полностью..."
        .attributed(font: .showMore, color: .showMore)

}

// MARK: - Cell

final class ReviewCell: UITableViewCell {

    fileprivate var config: Config?

    fileprivate let reviewTextLabel = UILabel()
    fileprivate let reviewerNameLabel = UILabel()
    fileprivate let createdLabel = UILabel()
    fileprivate let showMoreButton = UIButton()
    fileprivate let reviewerAvatar = UIImageView()
    fileprivate let ratingImageView = UIImageView()
    fileprivate let photoStackView = UIStackView()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        reviewTextLabel.frame = layout.reviewTextLabelFrame
        reviewerNameLabel.frame = layout.reviewerNameLabelFrame
        createdLabel.frame = layout.createdLabelFrame
        showMoreButton.frame = layout.showMoreButtonFrame
        reviewerAvatar.frame = layout.reviewerAvatarFrame
        ratingImageView.frame = layout.ratingImageViewFrame
        reviewerAvatar.frame.size = Layout.avatarSize
        photoStackView.frame = layout.reviewPhotosFrame
        let ratingRenderer = RatingRenderer()
        let image = ratingRenderer.ratingImage(config?.rating ?? 3)
        ratingImageView.image = image
        showMoreButton.addAction(UIAction { [weak self] _ in self?.labelCreateTapped() }, for: .touchUpInside)
    }
    
    @objc func labelCreateTapped() {
        guard let config else { return }
        config.onTapShowMore(config.id)
    }
    
    func setImagesPhotoStack(_ images: [UIImage]) {
        photoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for image in 0..<images.count {
            let imageView = UIImageView(image: images[image])
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.frame.size = Layout.photoSize
            imageView.layer.cornerRadius = Layout.photoCornerRadius
            photoStackView.addArrangedSubview(imageView)
        }
    }

}

// MARK: - Private

private extension ReviewCell {

    func setupCell() {
        setupReviewTextLabel()
        setupReviewerNameLabel()
        setupCreatedLabel()
        setupShowMoreButton()
        setupReviewerAvatar()
        setupRatingImageView()
        setupPhotoStackView()
    }

    func setupReviewTextLabel() {
        contentView.addSubview(reviewTextLabel)
        reviewTextLabel.lineBreakMode = .byWordWrapping
    }
    
    func setupReviewerNameLabel() {
        contentView.addSubview(reviewerNameLabel)
        reviewerNameLabel.textColor = .black
    }

    func setupCreatedLabel() {
        contentView.addSubview(createdLabel)
        
    }

    func setupShowMoreButton() {
        contentView.addSubview(showMoreButton)
        showMoreButton.contentVerticalAlignment = .fill
        showMoreButton.setAttributedTitle(Config.showMoreText, for: .normal)
    }
    
    func setupReviewerAvatar() {
        contentView.addSubview(reviewerAvatar)
        reviewerAvatar.contentMode = .scaleAspectFit
        reviewerAvatar.image = UIImage(named: "l5w5aIHioYc")
        reviewerAvatar.layer.masksToBounds = true
        reviewerAvatar.layer.cornerRadius = Layout.avatarCornerRadius
    }
    
    func setupRatingImageView() {
        contentView.addSubview(ratingImageView)
        ratingImageView.contentMode = .scaleAspectFit
    }
    
    func setupPhotoStackView() {
        contentView.addSubview(photoStackView)
        photoStackView.axis = .horizontal
        photoStackView.spacing = Layout.photosSpacing
        photoStackView.distribution = .fillEqually
        photoStackView.alignment = .fill
    }


}

final class ReviewCountCell: UITableViewCell {
    
    fileprivate var config: ConfigCount?
    
    fileprivate let reviewCountLabel = UILabel()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let layout = config?.layout else { return }
        reviewCountLabel.frame = layout.reviewCountLabelFrame
    }
}

private extension ReviewCountCell {
    
    func setupCell() {
        setupReviewsCountLabel()
    }
    
    func setupReviewsCountLabel() {
        contentView.addSubview(reviewCountLabel)
        reviewCountLabel.font = .reviewCount
        reviewCountLabel.textColor = .reviewCount
        reviewCountLabel.textAlignment = .center
    }
    
}
// MARK: - Layout

/// Класс, в котором происходит расчёт фреймов для сабвью ячейки отзыва.
/// После расчётов возвращается актуальная высота ячейки.
private final class ReviewCellLayout {

    // MARK: - Размеры

    fileprivate static let avatarSize = CGSize(width: 36.0, height: 36.0)
    fileprivate static let avatarCornerRadius = 18.0
    fileprivate static let photoCornerRadius = 8.0

    fileprivate static let photoSize = CGSize(width: 55.0, height: 66.0)
    fileprivate static let photosSpacing = 8.0
    private static let showMoreButtonSize = Config.showMoreText.size()

    // MARK: - Фреймы

    private(set) var reviewTextLabelFrame = CGRect.zero
    private(set) var reviewerNameLabelFrame = CGRect.zero
    private(set) var showMoreButtonFrame = CGRect.zero
    private(set) var createdLabelFrame = CGRect.zero
    private(set) var reviewerAvatarFrame = CGRect.zero
    private(set) var ratingImageViewFrame = CGRect.zero
    private(set) var reviewCountLabelFrame = CGRect.zero
    private(set) var reviewPhotosFrame = CGRect.zero

    // MARK: - Отступы

    /// Отступы от краёв ячейки до её содержимого.
    fileprivate let insets = UIEdgeInsets(top: 9.0, left: 12.0, bottom: 9.0, right: 12.0)

    /// Горизонтальный отступ от аватара до имени пользователя.
    fileprivate let avatarToUsernameSpacing = 10.0
    /// Вертикальный отступ от имени пользователя до вью рейтинга.
    fileprivate let usernameToRatingSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до текста (если нет фото).
    fileprivate let ratingToTextSpacing = 6.0
    /// Вертикальный отступ от вью рейтинга до фото.
    fileprivate let ratingToPhotosSpacing = 10.0
    /// Вертикальный отступ от фото (если они есть) до текста отзыва.
    fileprivate let photosToTextSpacing = 10.0
    /// Вертикальный отступ от текста отзыва до времени создания отзыва или кнопки "Показать полностью..." (если она есть).
    fileprivate let reviewTextToCreatedSpacing = 6.0
    /// Вертикальный отступ от кнопки "Показать полностью..." до времени создания отзыва.
    fileprivate let showMoreToCreatedSpacing = 6.0

    // MARK: - Расчёт фреймов и высоты ячейки

    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: ConfigCount, maxWidth: CGFloat) -> CGFloat {
        
        let maxY = insets.top
        reviewCountLabelFrame = CGRect(
            origin: CGPoint(x: reviewCountLabelFrame.minX, y: maxY),
            size: CGSize(width: maxWidth, height: 20)
        )
        return reviewCountLabelFrame.maxY
    }
    
    /// Возвращает высоту ячейку с данной конфигурацией `config` и ограничением по ширине `maxWidth`.
    func height(config: Config, maxWidth: CGFloat) -> CGFloat {
        
        let width = maxWidth - insets.left - insets.right

        var maxY = insets.top
        var showShowMoreButton = false
        
        reviewCountLabelFrame = CGRect.zero
        reviewerAvatarFrame = CGRect(
            origin: CGPoint(x: insets.left, y: maxY),
            size: Layout.avatarSize
        )
        
        let nameLabelWidth = width - Layout.avatarSize.width - avatarToUsernameSpacing
        reviewerNameLabelFrame = CGRect(
            origin: CGPoint(
                x: reviewerAvatarFrame.maxX + avatarToUsernameSpacing,
                y: maxY
            ),
            size: CGSize(
                width: nameLabelWidth,
                height: config.reviewerNameText.font()?.lineHeight ?? .zero
            )
        )

        maxY = reviewerNameLabelFrame.maxY + usernameToRatingSpacing
        
        let ratingRenderer = RatingRenderer()
        let ratingImageSize = ratingRenderer.ratingImage(config.rating).size
        ratingImageViewFrame = CGRect(
            origin: CGPoint(x: reviewerNameLabelFrame.minX, y: maxY),
            size: ratingImageSize
        )
        maxY = ratingImageViewFrame.maxY + ratingToTextSpacing
        
        if !config.reviewImage.isEmpty {
            reviewPhotosFrame = CGRect(
                origin: CGPoint(x: reviewerAvatarFrame.maxX + avatarToUsernameSpacing,  y: maxY),
                size: CGSize(width: Layout.photoSize.width * CGFloat(config.reviewImage.count) + Layout.photosSpacing * CGFloat(config.reviewImage.count - 1), height: Layout.photoSize.height)
            )
            maxY = reviewPhotosFrame.maxY + photosToTextSpacing
        }
        else {
            reviewPhotosFrame = CGRect.zero
        }
        
        if !config.reviewText.isEmpty() {
            // Высота текста с текущим ограничением по количеству строк.
            let currentTextHeight = (config.reviewText.font()?.lineHeight ?? .zero) * CGFloat(config.maxLines)
            // Максимально возможная высота текста, если бы ограничения не было.
            let actualTextHeight = config.reviewText.boundingRect(width: width).size.height
            // Показываем кнопку "Показать полностью...", если максимально возможная высота текста больше текущей.
            showShowMoreButton = config.maxLines != .zero && actualTextHeight > currentTextHeight

            reviewTextLabelFrame = CGRect(
                origin: CGPoint(x: reviewerNameLabelFrame.minX, y: maxY),
//                size: CGSize(width: maxWidth - reviewTextLabelFrame.minX, height: currentTextHeight)
                size: config.reviewText.boundingRect(width: maxWidth - reviewTextLabelFrame.minX - insets.right, height: currentTextHeight).size
            )
            maxY = reviewTextLabelFrame.maxY + reviewTextToCreatedSpacing
        }

        if showShowMoreButton {
            showMoreButtonFrame = CGRect(
                origin: CGPoint(x: reviewTextLabelFrame.minX, y: maxY),
                size: Self.showMoreButtonSize
            )
            maxY = showMoreButtonFrame.maxY + showMoreToCreatedSpacing
        } else {
            showMoreButtonFrame = .zero
        }

        createdLabelFrame = CGRect(
            origin: CGPoint(x: reviewerNameLabelFrame.minX, y: maxY),
            size: config.created.boundingRect(width: width).size
        )
        return createdLabelFrame.maxY + insets.bottom
    }

}

// MARK: - Typealias

fileprivate typealias Config = ReviewCellConfig
fileprivate typealias ConfigCount = ReviewCountConfig
fileprivate typealias Layout = ReviewCellLayout
