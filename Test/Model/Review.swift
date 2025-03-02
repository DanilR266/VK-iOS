/// Модель отзыва.
struct Review: Decodable {

    /// Текст отзыва.
    let text: String
    /// Время создания отзыва.
    let created: String
    /// Имя оставившего отзыв
    let first_name: String
    /// Фамилия оставившего отзыв
    let last_name: String
    /// Рейтинг
    let rating: Int
    /// Фото отзыва
    let photo_urls: [String]?
}

struct ReviewCount: Decodable {
    
    /// Количество отзывов
    let count: Int
}
