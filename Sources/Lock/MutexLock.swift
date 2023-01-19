//
//  MutexLock.swift
//  
//
//  Created by EZOU on 2023/1/19.
//

import Foundation
import MachO

@inline(__always)
func assert(posixCode code: Int32) {
    Swift.assert(code == 0, "Unexpected pthread mutex error code: \(POSIXErrorCode(rawValue: code)!)")
}

/// Wrapper for `pthread_mutex_lock`
final class __Mutex {
    private let _lock: UnsafeMutablePointer<pthread_mutex_t>

    init(type: Int32) {
        _lock = .allocate(capacity: 1)
        _lock.initialize(to: pthread_mutex_t())

        let attr = UnsafeMutablePointer<pthread_mutexattr_t>.allocate(capacity: 1)
        attr.initialize(to: pthread_mutexattr_t())
        pthread_mutexattr_init(attr)
        pthread_mutexattr_settype(attr, type)

        let code = pthread_mutex_init(_lock, attr)
        assert(posixCode: code)

        pthread_mutexattr_destroy(attr)
        attr.deinitialize(count: 1)
        attr.deallocate()
    }

    func lock() {
        let code = pthread_mutex_lock(_lock)
        assert(posixCode: code)
    }

    func unlock() {
        let code = pthread_mutex_unlock(_lock)
        assert(posixCode: code)
    }

    func tryLock() -> Bool {
        let code = pthread_mutex_trylock(_lock)
        switch code {
        case 0:
            return true
        case EBUSY, EAGAIN, EDEADLK:
            return false
        default:
            assert(posixCode: code)
            return false
        }
    }

    deinit {
        let code = pthread_mutex_destroy(_lock)
        assert(posixCode: code)
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }
}

/// A struct for performing mutex locks.
///
/// This struct provides a simple lock implementation that uses a mutex lock internally. A mutex lock is a synchronization
/// mechanism that allows multiple threads to have simultaneous read-only access, but only one thread can have exclusive
/// write access at a time. The type of mutex lock can be specified with the `LockType` struct.
///
/// Example usage:
///
///    let lock = MutexLock()
///    lock.lock()
///    // protected code
///    lock.unlock()
///
public struct MutexLock: SimpleLock {
    /// POSIX mutex attribute type
    @frozen public struct LockType {
        let int: Int32
        /// Equal to PTHREAD_MUTEX_NORMAL
        public static let normal: LockType =
            LockType(int: PTHREAD_MUTEX_NORMAL)
        /// Equal to PTHREAD_MUTEX_RECURSIVE
        public static let recursive: LockType =
            LockType(int: PTHREAD_MUTEX_RECURSIVE)
        /// Equal to PTHREAD_MUTEX_DEFAULT
        public static let `default`: LockType =
            LockType(int: PTHREAD_MUTEX_DEFAULT)
        /// Equal to PTHREAD_MUTEX_ERRORCHECK
        public static let errorCheck: LockType =
            LockType(int: PTHREAD_MUTEX_ERRORCHECK)
    }

    let _lock: __Mutex

    public init(type: LockType = .default) {
        _lock = __Mutex(type: type.int)
    }

    /// Acquires the lock
    public func lock() {
        _lock.lock()
    }

    /// Releases the lock
    public func unlock() {
        _lock.unlock()
    }

    /// Tries to acquire the lock and return true if it succeeds.
    public func tryLock() -> Bool {
        _lock.tryLock()
    }
}
