import Fluent
import struct Foundation.UUID

final class Product: Model, @unchecked Sendable {
    static let schema="products"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "price")
    var price: Double

    @Parent(key: "category_id")
    var category: Category

    @Siblings(through: ProductTag.self, from: \.$product, to: \.$tag)
    var tags: [Tag]

    // Empty object
    init() {}

    init(name: String, price: Double, categoryID: UUID){
        self.id=UUID()
        self.price=price
        self.$category.id=categoryID
        self.name=name
    }
}