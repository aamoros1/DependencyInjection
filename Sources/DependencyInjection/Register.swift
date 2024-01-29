//
//  Register.swift
//
//

import Foundation

/**
 Support for synchronization within module
 */
extension DependencyInjector: Synchronizable { }

/**
 Public registration extensions
 */
public extension DependencyInjector {
    
    /// Register a type producer that takes no arguments.
    /// - Parameters:
    ///   - type: The type to register
    ///   - flavor: Optional flavor identifier used to differentiate between instances of the same type.
    ///   - scope: The scope that determines how the product is produced on retrieval.
    ///   - producer: The method or block called to produce the production on demand.
    func register<T>(type: Any.Type = T.self, flavor: String? = nil, _ scope: ScopeKind, withNoArg producer: @escaping () throws -> T?) {
        register(type: type,
                 flavor: flavor,
                 producer: Producer(flavor: flavor, scope: scope) { _ in
            try producer()
        })
    }
    
    func register<T, A1>(type: Any.Type = T.self, flavor: String? = nil, _ scope: ScopeKind, with1Arg producer: @escaping (A1) throws -> T?) {
        register(type: type,
                 flavor: flavor,
                 producer: Producer(flavor: flavor,
                                    scope: scope, produce: { injector in
            try producer(injector.retrieve(flavor: flavor))
        }))
    }
    
    func register<T, A1, A2>(type: Any.Type = T.self, flavor: String? = nil, _ scope: ScopeKind, with2Args producer: @escaping (A1, A2) throws -> T?) {
        register(type: type,
                 flavor: flavor,
                 producer: Producer(flavor: flavor, scope: scope, produce: { injector in
            try producer(injector.retrieve(flavor: flavor),
                         injector.retrieve(flavor: flavor))
        }))
    }
    
    func register<T, A1, A2, A3>(type: Any.Type = T.self, flavor: String? = nil, _ scope: ScopeKind, with3Args producer: @escaping (A1, A2, A3) throws -> T?) {
        register(type: type,
                 flavor: flavor,
                 producer: Producer(flavor: flavor, scope: scope, produce: { injector in
            try producer(injector.retrieve(flavor: flavor),
                         injector.retrieve(flavor: flavor),
                         injector.retrieve(flavor: flavor))
        }))
    }
    
    func register<T, A1, A2, A3, A4>(type: Any.Type = T.self, flavor: String? = nil, _ scope: ScopeKind, with4Args producer: @escaping (A1, A2, A3, A4) throws -> T?) {
        register(type: type,
                 flavor: flavor,
                 producer: Producer(flavor: flavor, scope: scope, produce: { injector in
            try producer(injector.retrieve(flavor: flavor),
                         injector.retrieve(flavor: flavor),
                         injector.retrieve(flavor: flavor),
                         injector.retrieve(flavor: flavor))
        }))
    }
}
