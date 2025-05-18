import Vapor

struct CategoryInput: Content {
    let name: String
}

struct CategoryOutput: Content {
    let id: UUID
    let name: String
}