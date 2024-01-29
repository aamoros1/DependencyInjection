//
//  Producer.swift
//
//

import Foundation


public class Producer {
    public static let defaultFlavor = "DEFAULT"
    
    public let scope: ScopeKind
    public let flavor: String?
    
    private var isEntered: Bool = false
    private var produce: ((DependencyInjector) throws -> Any)!
    
    private var singleton: Any?
    private weak var weakSingleton: AnyObject?
    
    public required init(scope: ScopeKind, flavor: String?) {
        self.scope = scope
        self.flavor = flavor
    }

    public convenience init(flavor: String?, scope: ScopeKind,
                            produce: @escaping (DependencyInjector) throws -> Any?) {
        self.init(scope: scope, flavor: flavor)
        self.produce = produce
    }

    public func produce<T>(_ injector: DependencyInjector) throws -> T? {
        defer {
            leave()
        }
        
        // Use cached singletons if available
        try enter(type: T.self)
        
        let cachedProduct: Any? = singleton ?? weakSingleton
        
        guard cachedProduct != nil && cachedProduct is T else {
            do {
                let product = try produce(injector) as? T
                switch scope {
                    case .singleton:
                        singleton = product
                    case .weakSingleton:
                        // Weak singleton must be object type
                        weakSingleton = product as AnyObject?
                        
                        // use singleton Any storage as backup
                        if weakSingleton == nil {
                            singleton = product
                        }
                    default:
                        break;
                }
                return product
            } catch let cause where !(cause is ProduceError) {
                throw ProduceError.producerError(type: T.self, flavor: flavor, cause: cause)
            }
        }
        return cachedProduct as? T
    }
    
    public func clear() {
        singleton = nil
        weakSingleton = nil
    }
    
    private func enter(type: Any.Type) throws {
        if isEntered {
            isEntered = false
            throw ProduceError.circularDependency(type: type, flavor: flavor)
        }
        isEntered = true
    }
    
    private func leave() {
        isEntered = false
    }
    
    static func buildTypedFlavor(_ flavor: String?, for type: Any.Type) -> String {
        "\(String(reflecting: type))<\(flavor ?? Producer.defaultFlavor)"
    }
}
