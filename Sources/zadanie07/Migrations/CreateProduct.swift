import Fluent

struct CreateProduct: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("products")
            .id()
            .field("name", .string, .required)
            .field("price", .double, .required)
            .field("category_id", .uuid, .required, .references("categories", "id"))
            .unique(on: "name")
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("products").delete()
    }
}
