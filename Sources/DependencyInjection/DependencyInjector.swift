//
//  DependencyModule.swift
//
//

import Foundation

public protocol DependencyModule {
    static func register(with dependencyInjector: DependencyInjector)
}

public protocol DependencyInjectable {
    static var injector: DependencyInjector { get }
    var injector: DependencyInjector { get }
}

/**
 Implementation of a Dependency Injection container based on type registration.
 
 Types are registered with a Producer method, or closure, with optional ScopeKind
 and an Flavor. Therefore, multiple Producers can be registered for a single
 Type as long as the ScopeKind and Flavor combinations are unique. The latest
 registration will replace any previous registration.
 
 Producers are called on demand to create an instance of the registered type.
 Dependencies are injected for Producers that take arguments. Argument values
 are retreved from the Injector that the Producer is registered under. An
 error is throw if the argument value cannot be retrieved.
 
 In addition, a Producer can specify the DependencyInjector type in its
 argument list. In which case the DependencyInjector instance is resolved using
 the optional Flavor of the registered Producer, and the DependencyInjector type.
 If one is not found, then the owner of the DependencyInjector instance is used.
 In this manner, Producers can use the injected DependencyInjector to retrieve
 additional dependencies as needed.
 
 This implementation is thread safe.
 */
public class DependencyInjector {
    /**
     Dictionary of registered producers by typed flavor
     */
    private var producers: [String: Producer] = [:]
    
    /**
     Synchronized queue for thread safety
     */
    public private(set) lazy var syncQueue: DispatchQueue = DispatchQueue(label: .init(reflecting: self),
                                                                          qos: .utility)
    public init() {
        
    }

    /**
     Retrieve an instance of the specified type. Depending on the type registration, the
     returned instance can be a shared singleton or a new instance of the specified type.
      - flavor: Optional flavor identifier used to differentiate between instances of the same type.
     */
    public func retrieve<T>(flavor: String? = nil) throws -> T {
        let typedFlavor = Producer.buildTypedFlavor(flavor, for: T.self)
        
        return try synchronized {
            guard let producer = producers[typedFlavor] else {
                //  Resolve all flavored injectors to self by default
                if let injector = self as? T {
                    return injector
                }
                //  Fallback to no flavor if a producer was not found for the given flavor
                guard flavor == nil else {
                    return try retrieve()
                }
                // Types without registered producers will produce an error
                throw ProduceError.notRegistered(type: T.self, flavor: flavor)
            }
            guard let product: T = try producer.produce(self) else {
                throw ProduceError.notProduceable(type: T.self, flavor: flavor)
            }
            return product
        }
    }
    
    func register(type: Any.Type, flavor: String?, producer: Producer) {
        let typedFlavor = Producer.buildTypedFlavor(flavor, for: type)
        
        synchronized {
            if let currentProducer = self.producers.removeValue(forKey: typedFlavor) {
                currentProducer.clear()
            }
            self.producers[typedFlavor] = producer
        }
    }
}

