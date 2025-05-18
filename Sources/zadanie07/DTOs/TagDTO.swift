import Vapor

struct TagInput: Content {
    let name: String
}

struct TagOutput: Content {
    let id: UUID
    let name: String
}