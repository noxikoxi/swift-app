import Vapor
import Fluent

struct CategoryController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let categories = routes.grouped("categories")
        categories.get(use: index)
        categories.post(use: create)
        categories.group(":categoryID") { category in
            category.get(use: show)
            category.post(use: update)
        }
        categories.group("delete"){ category in
            category.group(":categoryID") { category1 in
                category1.get(use: delete)
            }
        }
    }

    func index(req: Request) throws -> EventLoopFuture<View> {
        Category.query(on: req.db)
            .all()
            .map{ categories in
                categories.map { category in
                    CategoryOutput(id: category.id!, name: category.name)
                }
            }
            .flatMap { categoryOutputs in
                // Gdy mamy gotową tablicę [CategoryOutput], renderujemy widok
                // Tworzymy kontekst dla szablonu, przekazując tablicę categoryOutputs pod kluczem "categories"
                let context = ["categories": categoryOutputs]
                return req.view.render("categories/index", context)
            }
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        let input = try req.content.decode(CategoryInput.self)
        let category = Category(name: input.name)
        return category.save(on: req.db).map {
                return req.redirect(to: "/categories")
            }
    }

    func show(req: Request) throws -> EventLoopFuture<View> {
        Category.find(req.parameters.get("categoryID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { category in
                CategoryOutput(id: category.id!, name: category.name)
            }.flatMap { categoryOutput in
                let context = ["category": categoryOutput]
                return req.view.render("categories/category", context)
            }
    }

    func update(req: Request) throws -> EventLoopFuture<Response> {
    let input = try req.content.decode(CategoryInput.self)

    return Category.find(req.parameters.get("categoryID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMap { category in
            category.name = input.name
            return category.save(on: req.db).map {
                req.redirect(to: "/categories/\(category.id!)")
            }
        }
}

    func delete(req: Request) throws -> EventLoopFuture<Response> {
    return Category.find(req.parameters.get("categoryID"), on: req.db)
        .unwrap(or: Abort(.notFound))
        .flatMap { category in
            category.delete(on: req.db).map {
                 req.redirect(to: "/categories")
            }
        }
}
    
}
