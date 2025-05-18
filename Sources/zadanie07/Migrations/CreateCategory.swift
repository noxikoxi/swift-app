import Fluent

struct CreateCategory: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("categories")
            .id() // domyślnie UUID
            .field("name", .string, .required)
            .unique(on: "name")
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("categories").delete()
    }
}
