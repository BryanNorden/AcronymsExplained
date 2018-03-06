import Vapor

struct CategoriesController: RouteCollection {
    func boot(router: Router) throws {
        let categoriesRoutes = router.grouped("api", "categories")
        categoriesRoutes.post(use: createHandler)
        categoriesRoutes.get(use: getAllHandler)
        categoriesRoutes.get(Category.parameter, use: getHandler)
        categoriesRoutes.get(Category.parameter, "acronyms", use: getAcronymsHandler)
        categoriesRoutes.delete(Category.parameter, use: deleteHandler)
    }
    
    func createHandler(_ req: Request) throws -> Future<Category> {
        return try req.content.decode(Category.self).flatMap(to: Category.self) { category in
            return category.save(on: req)
        }
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameter(Category.self)
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameter(Category.self).flatMap(to: [Acronym].self) { category in
            return try category.acronyms.query(on: req).all()
        }
    }
    
    func deleteHandler(_ req: Request) throws -> Future<HTTPStatus> {
        return try req.parameter(Category.self).flatMap(to: HTTPStatus.self, { category in
            return category.delete(on: req).transform(to: .noContent)
        })
    }
    
}

extension Category: Parameter {}
