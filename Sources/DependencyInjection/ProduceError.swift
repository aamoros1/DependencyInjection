//
//  ProduceError.swift
//
//

import Foundation

public enum ProduceError: Error {
    
    case notRegistered(type: Any.Type, flavor: String?)
    case notProduceable(type: Any.Type, flavor: String?)
    case producerError(type: Any.Type, flavor: String?, cause: Error)
    case circularDependency(type: Any.Type, flavor: String?)
}
