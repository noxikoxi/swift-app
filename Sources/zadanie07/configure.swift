import NIOSSL
import Fluent
import FluentSQLiteDriver
import Leaf
import Vapor
import Redis

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite)

    app.migrations.add(CreateCategory())
    app.migrations.add(CreateProduct())
    app.migrations.add(CreateTag())
    app.migrations.add(CreateProductTagPivot())
    
    if let redisURL = Environment.get("REDIS_URL") {
        app.redis.configuration = try RedisConfiguration(url: redisURL)
    } else {
        app.redis.configuration = try RedisConfiguration(hostname: "localhost", port: 6379)
    }

    app.views.use(.leaf)
    // register routes
    try routes(app)
}
