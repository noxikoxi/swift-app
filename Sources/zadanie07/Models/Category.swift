import Fluent
import struct Foundation.UUID
import Vapor

final class Category: Model, @unchecked Sendable {
    static let schema="categories"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Children(for: \.$category)
    var products: [Product]
    
    // Empty object
    init() {}

    init(name: String){
        self.id=UUID()
        self.name=name
    }
}