//
//  Lock.swift
//  
//
//  Created by EZOU on 2023/1/19.
//

import Foundation

public protocol SimpleLock {
    func lock()
    func unlock()
    func tryLock() -> Bool
}

extension SimpleLock {
    /// Critical area
    public func lock(_ block: () -> Void) {
        lock()
        block()
        unlock()
    }
}

extension RWLock {
    /// Protect the critical area by reader lock
    public func rdlock(_ block: () -> Void) {
        rdlock()
        block()
        unlock()
    }

    /// Protect the critical area by writer lock
    public func wrlock(_ block: () -> Void) {
        wrlock()
        block()
        unlock()
    }
}
