//
//  ScopeKind.swift
//
//

import Foundation

public enum ScopeKind {
    /**
     Product is retained after first retrieval and returned for subsequent
     retrievals
     */
    case singleton
    
    /**
     Product is retained with a weak reference after first retrieval and return
     for subsequent retrievals if a reference to it is still available. Otherwise,
     it is produced again.
     */
    case weakSingleton
    
    /**
     Product is newly produced for each retrieval.
     */
    case instance
}
