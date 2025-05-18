import Vapor
import Fluent

struct TagController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let tags = routes.grouped("tags")
        tags.get(use: index)
        tags.post(use: create)
        tags.group(":tagID") { tag in
            tag.get(use: show)
            tag.post(use: update)
        }
        tags.group("delete"){ tag in
            tag.group(":tagID") { tag1 in
                tag1.get(use: delete)
            }
        }
    }

    func index(req: Request) throws -> EventLoopFuture<View> {
        Tag.query(on: req.db)
            .all()
            .map { tags in
                tags.map { tag in
                    TagOutput(id: tag.id!, name: tag.name)
                }
            }.flatMap { tagOutputs in
                let context  = ["tags": tagOutputs]
                return req.view.render("tags/index", context)
            }
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        let input = try req.content.decode(TagInput.self)
        let tag = Tag(name: input.name)
        return tag.save(on: req.db).map {
            return req.redirect(to: "/tags")
        }
    }

    func show(req: Request) throws -> EventLoopFuture<View> {
        Tag.find(req.parameters.get("tagID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .map { tag in
                TagOutput(id: tag.id!, name: tag.name)
            }.flatMap { tagOutput in
                let context = ["tag": tagOutput]
                return req.view.render("tags/tag", context)
            }
    }

    func update(req: Request) throws -> EventLoopFuture<Response> {
        let input = try req.content.decode(TagInput.self)
        return Tag.find(req.parameters.get("tagID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { tag in
                tag.name = input.name
                return tag.save(on: req.db).map {
                     req.redirect(to: "/tags/\(tag.id!)")
                }
            }
    }

    func delete(req: Request) throws -> EventLoopFuture<Response> {
        Tag.find(req.parameters.get("tagID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap  { tag in
                tag.delete(on: req.db).map{
                    req.redirect(to: "/tags")
                }
            }
    }
}
