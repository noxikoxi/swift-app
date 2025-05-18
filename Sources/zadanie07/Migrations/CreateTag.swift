import Fluent

struct CreateTag: Migration {
    func prepare(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("tags")
            .id()
            .field("name", .string, .required)
            .unique(on: "name")
            .create()
    }

    func revert(on database: any Database) -> EventLoopFuture<Void> {
        database.schema("tags").delete()
    }
}
