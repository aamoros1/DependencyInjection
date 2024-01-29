//
//  Synchronizable.swift
//
//

import Foundation

/**
 Specific Key used as a marker for queue reentrancy check.
 */
private let synchQueueReentrantSpecificKey = DispatchSpecificKey<Bool>()

/**
 Contractual interface used for implementing serial queue based synchronization.
 Use this interface instead of the objc_sync_* functions becase they are not
 reliable when mixed with objc GCD dispatch.
 */
public protocol Synchronizable {
    /**
     Get the serial queue used for synchronization. If the queue is concurrent,
     then synchronization is not affective for write operations. Rather, the
     class can manually call dispatch with barrier flag to perform async write
     operations.
     
     - Note: The implementation can return a shared serial queue,
     or one for this specified instance.
     */
    var syncQueue: DispatchQueue { get }
}

/**
 Extension for implementing synchronization using the backing serial
 syncQueue.
 */

public extension Synchronizable {
    private var reentrantKey: String {
        "Synchronizable[\(String(reflecting: self))]::\(syncQueue.label)#\(syncQueue.hashValue)>"
    }
    
    /**
     Test wether any submission to the queue will result in a reentrant state for the current thread.
     A reentrant state is when a synchronous block is being executed in a serial
     queue, and a call to dispatch another synchronous blck is made. This will
     create a deadlock in the current thread.
     If this condition is true, then the subsequent block is executed immediately.
     */
    private var isReentrant: Bool {
        Thread.current.threadDictionary[reentrantKey] as? Bool == true
    }
    
    /**
     Synchronized execution of a block with no return.
     */
    func synchronized(_ execute: @escaping () throws -> Void) rethrows {
        try synchronized(if: { true }, execute)
    }
    
    /**
     Synchronized execution of a block with a return value.
     */
    func synchronized<R>(_ execute: () throws -> R) rethrows -> R {
        guard isReentrant else {
            return try syncQueue.sync {
                defer {
                    leave()
                }
                enter()
                return try execute()
            }
        }
        return try execute()
    }

    /// Synchronized execution of a block if the tested condition is true.
    /// - Parameters:
    ///   - test: <#test description#>
    ///   - execute: <#execute description#>
    /// - Returns: true if the condition is true and the block is executed.
    @discardableResult
    func synchronized(if test: @escaping () -> Bool, _ execute: @escaping () throws -> Void) rethrows -> Bool {
        guard isReentrant else {
            return try syncQueue.sync {
                defer {
                    leave()
                }
                enter()
                guard test() else {
                    return false
                }
                try execute()
                return true
            }
        }
        guard test() else { return false }
        try execute()
        return true
    }
    
    /**
     Called during a block dispatch to flag the queue as reentrant if another block
     is submitted.
     */
    private func enter() {
        Thread.current.threadDictionary[reentrantKey] = true
    }
    
    /**
     Called when a block finishes to remove the reentrant flag.
     */
    private func leave() {
        Thread.current.threadDictionary.removeObject(forKey: reentrantKey)
    }
}
