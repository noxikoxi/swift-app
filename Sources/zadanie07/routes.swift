import Fluent
import Vapor
import Redis

func routes(_ app: Application) throws {
    app.get { req async throws in
        try await req.view.render("index", ["title": "Hello Vapor!"])
    }

    app.get("hello") { req in
        return req.redis.ping()
    }

    try app.register(collection: CategoryController())
    try app.register(collection: ProductController())
    try app.register(collection: TagController())
    try app.register(collection: CartController())
}
