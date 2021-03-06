import Vapor
import Authentication

struct UsersController: RouteCollection {
    func boot(router: Router) throws {
        let usersRoutes = router.grouped("api", "users")
        usersRoutes.post(use: createHandler)
        usersRoutes.get(use: getAllHandler)
        usersRoutes.get(User.Public.parameter, use: getHandler)
        usersRoutes.get(User.parameter, "acronyms", use: getAcronymsHandler)
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptVerifier())
        let basicAuthGroup = usersRoutes.grouped(basicAuthMiddleware)
        basicAuthGroup.post("login", use: loginHandler)
    }
    
    func createHandler(_ req: Request) throws -> Future<User> {
        return try req.content.decode(User.self).flatMap(to: User.self) { user in
            let hasher = try req.make(BCryptHasher.self)
            user.password = try hasher.make(user.password)
            return user.save(on: req)
        }
    }
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.Public.query(on: req).all()
    }
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameter(User.Public.self)
    }
    
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameter(User.self).flatMap(to: [Acronym].self) { user in
            return try user.acronyms.query(on: req).all()
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        return token.save(on: req)
    }
    
}

extension User: Parameter {}
extension User.Public: Parameter {}
