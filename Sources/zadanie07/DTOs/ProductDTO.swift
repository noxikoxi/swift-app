
import Vapor

struct ProductInput: Content {
    let name: String
    let price: Double
    let categoryID: UUID
    let tagIDs: [UUID]?
}

struct ProductOutput: Content {
    let id: UUID
    let name: String
    let price: Double
    let categoryName: String
    let tags: [Tag]
}