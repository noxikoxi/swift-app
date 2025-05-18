import Fluent

struct CreateProductTagPivot: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("product_tag")
            .id()
            .field("product_id", .uuid, .required, .references("products", "id", onDelete: .cascade))
            .field("tag_id", .uuid, .required, .references("tags", "id", onDelete: .cascade))
            .unique(on: "product_id", "tag_id") // nie powtarzamy tych samych relacji
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("product_tag").delete()
    }
}
