import Vapor
import Fluent

struct AcronymsController: RouteCollection {
    func boot(router: Router) throws {
        let acronymsRoute = router.grouped("api", "acronyms")
        acronymsRoute.get(use: getAllHandler)
        acronymsRoute.get(Acronym.parameter, use: getHandler)
        acronymsRoute.get(Acronym.parameter, "creator", use: getCreatorHandler)
        acronymsRoute.get(Acronym.parameter, "categories", use: getCategoriesHandler)
        acronymsRoute.post(Acronym.parameter, "categories", Category.parameter, use: addCategoriesHandler)
        acronymsRoute.get("search", use: searchHandler)
        
        let tokenAuthMiddleware = User.tokenAuthMiddleware()
        let tokenAuthGroup = acronymsRoute.grouped(tokenAuthMiddleware)
        tokenAuthGroup.post(use: createHandler)
        tokenAuthGroup.put(Acronym.parameter, use: updateHandler)
        tokenAuthGroup.delete(Acronym.parameter, use: deleteHandler)
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Acronym]> {
        return Acronym.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.parameter(Acronym.self)
    }
    
    func createHandler(_ req: Request) throws -> Future<Acronym> {
        return try req.content.decode(AcronymCreateData.self).flatMap(to: Acronym.self) { acronymData in
            let user = try req.requireAuthenticated(User.self)
            let acronym = try Acronym(short: acronymData.short, long: acronymData.long, creatorID: user.requireID())
            return acronym.save(on: req)
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameter(Acronym.self).flatMap(to: HTTPStatus.self, { acronym in
            return acronym.delete(on: req).transform(to: .noContent)
        })
    }
    
    func updateHandler(_ req: Request) throws -> Future<Acronym>  {
        return try flatMap(to: Acronym.self, req.parameter(Acronym.self), req.content.decode(AcronymCreateData.self)) { acronym, acronymData in
            acronym.short = acronymData.short
            acronym.long = acronymData.long
            acronym.creatorID = try req.requireAuthenticated(User.self).requireID()
            return acronym.save(on: req)
        }
    }
    
    func getCreatorHandler(_ req: Request) throws -> Future<User> {
        return try req.parameter(Acronym.self).flatMap(to: User.self) { acronym in
            return acronym.creator.get(on: req)
        }
    }
    
    func getCategoriesHandler(_ req: Request) throws -> Future<[Category]> {
        return try req.parameter(Acronym.self).flatMap(to: [Category].self) { acronym in
            return try acronym.categories.query(on: req).all()
        }
    }
    
//    Known issue - https://github.com/vapor/fluent-mysql/issues/60
//    Saving till fixed
//    =======================================
//
//    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
//        return try flatMap(to: HTTPStatus.self, req.parameter(Acronym.self), req.parameter(Category.self)) { acronym, category in
//            let pivot = try AcronymCategoryPivot(acronym.requireID(), category.requireID())
//            return pivot.save(on: req).transform(to: .ok)
//        }
//    }
    
    func addCategoriesHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameter(Acronym.self).flatMap(to: HTTPStatus.self) { acronym in
            return try req.parameter(Category.self).flatMap(to: HTTPStatus.self) { category in
                let pivot = try AcronymCategoryPivot(acronym.requireID(), category.requireID())
                return pivot.save(on: req).transform(to: .ok)
            }
        }
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameter(Acronym.self).flatMap(to: View.self) { acronym in
            return acronym.creator.get(on: req).flatMap(to: View.self) { creator in
                return try acronym.categories.query(on: req).all().flatMap(to: View.self) { categories in
                    let context = AcronymContext(title: acronym.long, acronym: acronym, creator: creator, categories: categories.isEmpty ? nil : categories)
                    return try req.leaf().render("acronym", context)
                }
            }
        }
    }
    
    func searchHandler(_ req: Request) throws -> Future<[Acronym]> {
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest, reason: "Missing search tearm in request")
        }
    
//        return Acronym.query(on: req).filter(\.short == searchTerm).all()
        return Acronym.query(on: req).group(.or) { or in
            or.filter(\.short == searchTerm)
            or.filter(\.long == searchTerm)
        }.all()
        
    }
}

extension Acronym: Parameter {}

struct AcronymCreateData: Content {
    let short: String
    let long: String
}
