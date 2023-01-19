//
//  RWLock.swift
//  
//
//  Created by EZOU on 2023/1/19.
//

import Foundation
import MachO

final class __RWLock {
    private let _lock: UnsafeMutablePointer<pthread_rwlock_t>

    init() {
        _lock = .allocate(capacity: 1)
        _lock.initialize(to: pthread_rwlock_t())
        let code = pthread_rwlock_init(_lock, nil)
        assert(posixCode: code)
    }

    deinit {
        pthread_rwlock_destroy(_lock)
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }

    func rdlock() {
        let code = pthread_rwlock_rdlock(_lock)
        assert(posixCode: code)
    }

    func tryRdlock() -> Bool {
        let code = pthread_rwlock_tryrdlock(_lock)
        switch code {
        case 0:
            return true
        case EBUSY, EDEADLK, EAGAIN:
            return false
        default:
            assert(posixCode: code)
            return false
        }
    }

    func wrlock() {
        let code = pthread_rwlock_wrlock(_lock)
        assert(posixCode: code)
    }

    func tryWrlock() -> Bool {
        let code = pthread_rwlock_trywrlock(_lock)
        switch code {
        case 0:
            return true
        case EBUSY, EDEADLK, EAGAIN:
            return false
        default:
            assert(posixCode: code)
            return false
        }
    }

    func unlock() {
        let code = pthread_rwlock_unlock(_lock)
        assert(posixCode: code)
    }
}

/// Provides a read-write lock mechanism.
/// This struct provides the ability to lock and unlock a shared resource for both read and write accesses.
///
/// Example code:
///
///     let lock = RWLock()
///     lock.rdlock()
///     // Protected read operation
///     lock.unlock()
///
///     lock.wrlock()
///     // Protected write operation
///     lock.unlock()
///
public struct RWLock {

    let _lock = __RWLock()

    /// Locks the shared resource for reading.
    /// If the lock is already held for writing by another thread, this method will block until the lock is released.
    public func rdlock() {
        _lock.rdlock()
    }

    /// Attempts to lock the shared resource for reading.
    /// If the lock is already held for writing by another thread, this method will return `false`.
    /// - Returns: `true` if the lock was acquired successfully, `false` otherwise.
    public func tryRdlock() -> Bool {
        _lock.tryRdlock()
    }

    /// Locks the shared resource for writing.
    /// If the lock is already held for reading or writing by another thread, this method will block until the lock is released.
    public func wrlock() {
        _lock.wrlock()
    }

    /// Attempts to lock the shared resource for writing.
    /// If the lock is already held for reading or writing by another thread, this method will return `false`.
    /// - Returns: `true` if the lock was acquired successfully, `false` otherwise.
    public func tryWrlock() -> Bool {
        _lock.tryWrlock()
    }

    /// Unlocks the shared resource, allowing other threads to acquire the lock.
    public func unlock() {
        _lock.unlock()
    }
}
