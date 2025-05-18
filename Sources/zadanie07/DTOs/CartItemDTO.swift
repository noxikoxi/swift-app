import Vapor

struct CartItem: Content {
    init(productID: String, quantity: Int) {
        self.productID = productID
        self.quantity = quantity
    }
    var productID: String
    var quantity: Int
}

struct CartItemOutput: Content {
    init(productName: String, productID: String, quantity: Int) {
        self.productName = productName
        self.quantity = quantity
        self.productID = productID
    }
    var productID: String
    var productName: String
    var quantity: Int
}
