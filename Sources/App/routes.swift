import Routing
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    let acronymsController = AcronymsController()
    try router.register(collection: acronymsController)
    
    try router.register(collection: CategoriesController())
    
    try router.register(collection: UsersController())
    
    try router.register(collection: WebsiteController())
}
