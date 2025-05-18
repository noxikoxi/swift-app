import Vapor
import Redis

struct CartController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let cart = routes.grouped("cart")
        cart.get(use: viewCart)
        cart.post("add", use: addToCart)
        cart.get("clear", use: clearCart)
        cart.post("update", use: updateCart)
    }

    func getOrSetCartID(req: Request) -> (String, HTTPCookies.Value?) {
        if let cookie = req.cookies["cart_id"] {
            let refreshedCookie = HTTPCookies.Value(
                string: cookie.string,
                expires: Date().addingTimeInterval(60 * 60 * 24), // 24h
                path: "/",
                isHTTPOnly: true
            )
            return (refreshedCookie.string, refreshedCookie)
        } else {
            let newID = UUID().uuidString
            let cookieValue = HTTPCookies.Value(
                string: newID, 
                expires: Date().addingTimeInterval(60*60*24), // ważne 1 dzień
                path: "/",
                isHTTPOnly: true
                ) 
            return (newID, cookieValue)
        }
    }

    func getCart(req: Request, redisKey: RedisKey) throws  -> [CartItem] {
        let cartJSON = try req.redis.get(redisKey, as: String.self).wait()

        var cart: [CartItem] = []
        if let json = cartJSON, let data = json.data(using: .utf8),
        let decoded = try? JSONDecoder().decode([CartItem].self, from: data) {
            cart = decoded
        }
        return cart
    }


    func viewCart(req: Request) async  throws -> Response {
        let (cartID, cookie) = getOrSetCartID(req: req)
        let redisKey = RedisKey("cart:\(cartID)")

        let cart = try getCart(req: req, redisKey: redisKey)

        let products = try await Product.query(on: req.db).all()

        let cartOutput: [CartItemOutput] = cart.compactMap { item in
            if let product = products.first(where: { $0.id?.uuidString == item.productID }) {
                return CartItemOutput(productName: product.name, productID: item.productID, quantity: item.quantity)
            } else {
                return nil
            }
        }

        let view = try await req.view.render("cart/index", ["items": cartOutput]).get()

        let response = Response(status: .ok)
        response.headers.contentType = .html
        response.body = .init(buffer: view.data)
        response.cookies["cart_id"] = cookie

        return response    
    }



    func addToCart(req: Request) throws -> Response {
        struct Input: Content {
            var productID: String
        }

        let input = try req.content.decode(Input.self)
        let (cartID, cookie) = getOrSetCartID(req: req)
        let redisKey = RedisKey("cart:\(cartID)")
        var cart = try getCart(req:req, redisKey: redisKey)

        print("CHUJ")
        print(input)

        if let index = cart.firstIndex(where: { $0.productID == input.productID }) {
            cart[index].quantity += 1
        } else {
            cart.append(CartItem(productID: input.productID, quantity: 1))
        }

        let jsonData = try JSONEncoder().encode(cart)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Nie udało się zakodować koszyka")
        }

        _ = req.redis.set(redisKey, to: jsonString, onCondition: .none, expiration: .seconds(60*60*24))
        let response = req.redirect(to: "/cart")
        response.cookies["cart_id"] = cookie
        
        return req.redirect(to: "/cart")
    }

    func clearCart(req: Request) throws -> Response {
        let (cartID, cookie) = getOrSetCartID(req: req)
        let redisKey = RedisKey("cart:\(cartID)")
        _ = req.redis.delete(redisKey)
        req.cookies["cart_id"] = cookie
        return req.redirect(to: "/cart")
    }

    func updateCart(req: Request) throws -> Response {
        struct Input: Content {
            var productID: String
            var quantity: Int
        }

        let input = try req.content.decode(Input.self)
        let (cartID, cookie) = getOrSetCartID(req: req)
        let redisKey = RedisKey("cart:\(cartID)")

        var cart = try getCart(req:req, redisKey: redisKey)

        if let index = cart.firstIndex(where: { $0.productID == input.productID }) {
            if input.quantity > 0 {
                cart[index].quantity = input.quantity
            } else {
                cart.remove(at: index)
            }
        } else if input.quantity > 0 {
            cart.append(CartItem(productID: input.productID, quantity: input.quantity))
        }

        let jsonData = try JSONEncoder().encode(cart)
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw Abort(.internalServerError, reason: "Nie udało się zakodować koszyka")
        }

        _ = req.redis.set(redisKey, to: jsonString, onCondition: .none, expiration: .seconds(60 * 60 * 24))

        let response = req.redirect(to: "/cart")
        response.cookies["cart_id"] = cookie
        return req.redirect(to: "/cart")
    }
}
