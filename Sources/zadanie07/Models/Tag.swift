import Fluent
import struct Foundation.UUID

final class Tag: Model, @unchecked Sendable {
    static let schema="tags"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Siblings(through: ProductTag.self, from: \.$tag, to: \.$product)
    var products: [Product]

    // Empty object
    init() {}

    init(name: String){
        self.id=UUID()
        self.name=name
    }
}

final class ProductTag: Model, @unchecked Sendable {
    static let schema = "product_tag"

    @ID()
    var id: UUID?

    @Parent(key: "product_id")
    var product: Product

    @Parent(key: "tag_id")
    var tag: Tag

    init() {}

    init(productID: UUID, tagID: UUID) {
        self.$product.id = productID
        self.$tag.id = tagID
    }
}
