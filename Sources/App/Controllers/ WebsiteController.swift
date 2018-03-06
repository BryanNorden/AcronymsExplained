import Leaf
import Vapor
import Foundation
import Authentication

struct WebsiteController: RouteCollection {
    func boot(router: Router) throws {
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("acronyms", Acronym.parameter, use: acronymHandler)
        authSessionRoutes.get("users", User.parameter, use: userHandler)
        authSessionRoutes.get("users", use: listAllUsersHandler)
        authSessionRoutes.get("categories", use: listAllCategoriesHandler)
        authSessionRoutes.get("categories", Category.parameter, use: categoryHandler)
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post("login", use: loginPostHandler)
        
        let protectedRoutes = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        protectedRoutes.get("create-acronym", use: createAcryonymHandler)
        protectedRoutes.post("create-acronym", use: createAcryonymPostHandler)
        protectedRoutes.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        protectedRoutes.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        protectedRoutes.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        return Acronym.query(on: req).all().flatMap(to: View.self) { acronyms in
            let context = IndexContent(title: "Homepage", acronyms: acronyms.isEmpty ? nil : acronyms)
            return try req.leaf().render("index", context)
        }
    }
    
//    Known issue - https://github.com/vapor/fluent-mysql/issues/60
//    Saving till fixed
//    =======================================
//
//    func acronymHandler(_ req: Request) throws -> Future<View> {
//        return try req.parameter(Acronym.self).flatMap(to: View.self) { acronym in
//            return try flatMap(to: View.self, acronym.creator.get(on: req), acronym.categories.query(on: req).all()) { creator, categories in
//                let context = AcronymContext(title: acronym.long, acronym: acronym, creator: creator, categories: categories.isEmpty ? nil : categories)
//                return try req.leaf().render("acronym", context)
//            }
//        }
//    }
    
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
    
    func userHandler(_ req: Request) throws -> Future<View> {
        return try req.parameter(User.self).flatMap(to: View.self) { user in
            return try user.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
                let context = UserContext(title: user.name, user: user, acronyms: acronyms.isEmpty ? nil : acronyms)
                return try req.leaf().render("user", context)
            }
        }
    }
    
    func listAllUsersHandler(_ req: Request) throws -> Future<View> {
        return User.query(on: req).all().flatMap(to: View.self) { users in
            let context = AllUserContext(title: "All Users", users: users.isEmpty ? nil : users)
            return try req.leaf().render("allUsers", context)
        }
    }
    
    func listAllCategoriesHandler(_ req: Request) throws -> Future<View> {
        return Category.query(on: req).all().flatMap(to: View.self) { categories in
            let context = AllCategoriesContext(title: "All Categories", categories: categories.isEmpty ? nil : categories)
            return try req.leaf().render("allCategories", context)
        }
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameter(Category.self).flatMap(to: View.self) { category in
            return try category.acronyms.query(on: req).all().flatMap(to: View.self) { acronyms in
                let context = CategoryContext(title: category.name, category: category, acronyms: acronyms.isEmpty ? nil : acronyms)
                return try req.leaf().render("category", context)
            }
        }
    }
    
    func createAcryonymHandler(_ req: Request) throws -> Future<View> {
        let context = CreateAcronymContext(title: "Create An Acronym")
        return try req.leaf().render("createAcronym", context)
    }
    
    func createAcryonymPostHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(AcronymPostData.self).flatMap(to: Response.self) { data in
            let user = try req.requireAuthenticated(User.self)
            let acronym = try Acronym(short: data.acronymShort, long: data.acronymLong, creatorID: user.requireID())
            return acronym.save(on: req).map(to: Response.self) { acronym in
                guard let id = acronym.id else {
                    return req.redirect(to: "/")
                }
                
                return req.redirect(to: "/acronyms/\(id)")
            }
        }
    }
    
    func editAcronymHandler(_ req: Request) throws -> Future<View> {
        return try req.parameter(Acronym.self).flatMap(to: View.self) { acronym in
            let context = EditAcronymContext(title: "Edit Acronym", acronym: acronym)
            return try req.leaf().render("createAcronym", context)
        }
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameter(Acronym.self), req.content.decode(AcronymPostData.self)) { acronym, data in
            acronym.short = data.acronymShort
            acronym.long = data.acronymLong
            acronym.creatorID = try req.requireAuthenticated(User.self).requireID()
            
            return acronym.save(on: req).map(to: Response.self) { acronym in
                guard let id = acronym.id else {
                    return req.redirect(to: "/")
                }
                
                return req.redirect(to: "/acronyms/\(id)")
            }
        }
    }
    
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameter(Acronym.self).flatMap(to: Response.self) { acronym in
            return acronym.delete(on: req).transform(to: req.redirect(to: "/"))
        }
    }
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        print(req.content)
        let context = LoginContext(title: "Login")
        return try req.leaf().render("login", context)
    }
    
    func loginPostHandler(_ req: Request) throws -> Future<Response> {
        return try req.content.decode(LoginPostData.self).flatMap(to: Response.self) { data in
            let verifier = try req.make(BCryptVerifier.self)
            return User.authenticate(username: data.username, password: data.password, using: verifier, on: req).map(to: Response.self) { user in
                guard let user = user else {
                    // TODO: Display an error message for the user
                   return req.redirect(to: "/login")
                }
                
                print(req.content)
                
                try req.authenticateSession(user)
                // TODO: Redirect the user to the page the were trying to visit if not from the login page
                return req.redirect(to: "/")
            }
        }
    }
}

extension Request {
    func leaf() throws -> LeafRenderer {
        return try self.make(LeafRenderer.self)
    }
}

struct IndexContent: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let creator: User
    let categories: [Category]?
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let acronyms: [Acronym]?
}

struct AllCategoriesContext: Encodable {
    let title: String
    let categories: [Category]?
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]?
}

struct AllUserContext: Encodable {
    let title: String
    let users: [User]?
}

struct CreateAcronymContext: Encodable {
    let title: String
}

struct AcronymPostData: Content {
    static var defaultMediaType = MediaType.urlEncodedForm
    let acronymLong: String
    let acronymShort: String
}

struct EditAcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let editing = true
}

struct LoginContext: Encodable {
    let title: String
}

struct LoginPostData: Content {
    let username: String
    let password: String
}
