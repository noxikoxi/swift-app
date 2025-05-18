import Vapor
import Fluent

struct ProductController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let products = routes.grouped("products")
        products.get(use: index)
        products.post(use: create)
        products.group(":productID") { product in
            product.get(use: show)
            product.post(use: update)
            product.group("tags") {product1 in
                product1.group(":tagID") { product2 in
                    product2.get(use: detachTag)
                }
                product1.post(use: attachTag)
            }
        }
        products.group("delete"){product in
            product.group(":productID") { product1 in
                product1.get(use: delete)
            }
        }
    }

    struct ProductsContext: Encodable {
        var products: [ProductOutput]
        var categories: [CategoryOutput]
    }

    struct ProductContext: Encodable {
        var product: ProductOutput
        var categories: [CategoryOutput]
        var availableTags: [TagOutput]
    }

    struct TagRequest: Content {
        let tagID: UUID
    }

    func index(req: Request) throws -> EventLoopFuture<View> {
        let productsFuture = Product.query(on: req.db)
            .with(\.$category) // Eager load relację 'category' (Parent)
            .with(\.$tags)     // Eager load relację 'tags' (Siblings)
            .all()

        let categoriesFuture = Category.query(on: req.db)
             .all()

        return productsFuture.and(categoriesFuture) // Zwraca EventLoopFuture<([Product], [Category])>
            .flatMap { (products, categories) in
                let productOutputs = products.map { product in
                    ProductOutput(
                        id: product.id!,
                        name: product.name,
                        price: product.price,
                        categoryName: product.category.name,
                        tags: product.tags
                    )
                }

                let categoryOutputs = categories.map { category in
                    CategoryOutput(id: category.id!, name: category.name)
                }

                return req.view.render("products/index", ProductsContext(products: productOutputs, categories: categoryOutputs))
            }
    }

    func create(req: Request) throws -> EventLoopFuture<Response> {
        let input = try req.content.decode(ProductInput.self)
        let product = Product(name: input.name, price: input.price, categoryID: input.categoryID)
        return product.save(on: req.db).map {
                return req.redirect(to: "/products")
        }
    }

    func show(req: Request) throws -> EventLoopFuture<View> {
        guard let productID = req.parameters.get("productID", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        let productFuture = Product.query(on: req.db)
            .filter(\.$id == productID)
            .with(\.$category)
            .with(\.$tags)  
            .first()
            .unwrap(or: Abort(.notFound))

        let categoriesFuture = Category.query(on: req.db).all()
        let allTagsFuture = Tag.query(on: req.db).all()
        

        return productFuture.and(categoriesFuture).and(allTagsFuture)
            .flatMap { (productAndCategories, allTags) in
                let (product, categories) = productAndCategories

                let productOutput = ProductOutput(
                    id: product.id!,
                    name: product.name,
                    price: product.price,
                    categoryName: product.category.name,
                    tags: product.tags
                )

                let categoryOutputs = categories.map { category in
                    CategoryOutput(id: category.id!, name: category.name)
                }

                let allTagOutputs = allTags.map { tag in
                    TagOutput(id: tag.id!, name: tag.name)
                }

                

                let assignedTagIDs = Set(product.tags.compactMap { tag in
                        tag.id
                })
                
                let availableTagOutputs = allTagOutputs.filter { tagOutput in
                    return !assignedTagIDs.contains(tagOutput.id)
                }

                return req.view.render("products/product", ProductContext(
                        product: productOutput, 
                        categories: categoryOutputs, 
                        availableTags: availableTagOutputs
                        )
                    )
            }
        
    }
    

    func update(req: Request) throws -> EventLoopFuture<Response> {
         let input = try req.content.decode(ProductInput.self)
         return Product.find(req.parameters.get("productID"), on: req.db)
             .unwrap(or: Abort(.notFound))
             .flatMap { product in
                    product.name = input.name
                    product.price = input.price
                    product.$category.id = input.categoryID 
                    return product.save(on: req.db).map {
                        req.redirect(to: "/products/\(product.id!)")
                 }
            }
     }

    func delete(req: Request) throws -> EventLoopFuture<Response> {
         return Product.find(req.parameters.get("productID"), on: req.db)
             .unwrap(or: Abort(.notFound))
             .flatMap { product in
                 product.delete(on: req.db).map {
                     req.redirect(to: "/products")
                 }
             }
     }

    func attachTag(req: Request) throws -> EventLoopFuture<Response> {
        let productID = try req.parameters.require("productID", as: UUID.self)
        let input = try req.content.decode(TagRequest.self)
        let productFuture = Product.find(productID, on: req.db).unwrap(or: Abort(.notFound))
        let tagFuture = Tag.find(input.tagID, on: req.db).unwrap(or: Abort(.notFound))

        return productFuture.and(tagFuture).flatMap { (product, tag) in
            return product.$tags.attach(tag, on: req.db)
        }.map {
            req.redirect(to: "/products/\(productID)")
        }
    }

    func detachTag(req: Request) throws -> EventLoopFuture<Response> {
        let productID = try req.parameters.require("productID", as: UUID.self)
        let tagID = try req.parameters.require("tagID", as: UUID.self)

        let productFuture = Product.find(productID, on: req.db).unwrap(or: Abort(.notFound))
        let tagFuture = Tag.find(tagID, on: req.db).unwrap(or: Abort(.notFound))

        return productFuture.and(tagFuture).flatMap { (product, tag) in
            return product.$tags.detach(tag, on: req.db)
        }.map {
            req.redirect(to: "/products/\(productID)")
        }
    }
}