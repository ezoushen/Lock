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
    Swift.assert(code == 0, "Unexpected POSIX error code: \(POSIXErrorCode(rawValue: code)!)")
}

/// Wrapper for `pthread_mutex_lock`
final class __Mutex {
    fileprivate let _lock: UnsafeMutablePointer<pthread_mutex_t>

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

/// Wrapper class for POSIX `pthread_cond_t`
final class __Cond {
    let _cond: UnsafeMutablePointer<pthread_cond_t>

    init() {
        self._cond = .allocate(capacity: 1)
        self._cond.initialize(to: pthread_cond_t())

        let code = pthread_cond_init(_cond, nil)
        assert(posixCode: code)
    }

    func wait(mutex: __Mutex) {
        let code = pthread_cond_wait(_cond, mutex._lock)
        assert(posixCode: code)
    }

    func wait(timespec: inout timespec, mutex: __Mutex) -> TimeoutResult {
        let code = pthread_cond_timedwait(_cond, mutex._lock, &timespec)
        switch code {
        case 0:
            return .success
        case ETIMEDOUT, EINTR:
            return .timeout
        default:
            assert(posixCode: code)
            return .timeout
        }
    }

    func wait(relativeTimespec: inout timespec, mutex: __Mutex) -> TimeoutResult {
        let code = pthread_cond_timedwait_relative_np(_cond, mutex._lock, &relativeTimespec)
        switch code {
        case 0:
            return .success
        case ETIMEDOUT:
            return .timeout
        default:
            assert(posixCode: code)
            return .timeout
        }
    }

    func signal() {
        let code = pthread_cond_signal(_cond)
        assert(posixCode: code)
    }

    func broadcast() {
        let code = pthread_cond_broadcast(_cond)
        assert(posixCode: code)
    }

    deinit {
        let code = pthread_cond_destroy(_cond)
        assert(posixCode: code)
        _cond.deinitialize(count: 1)
        _cond.deallocate()
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

/// A synchronization primitive that allows threads to wait for a certain condition to be met.
///
/// Example usage:
///     let condition = ConditionVariable()
///     let lock = MutexLock()
///
///     DispatchQueue.global().async {
///         lock.lock()
///         condition.wait(mutex: lock)
///         print("Thread 1: Condition met!")
///         lock.unlock()
///     }
///
///     DispatchQueue.global().async {
///         lock.lock()
///         print("Thread 2: Waiting...")
///         sleep(2) // Simulate some work
///         condition.signal()
///         lock.unlock()
///     }
///
///     // Output:
///     // Thread 2: Waiting...
///     // Thread 1: Condition met!
///
public struct ConditionVariable {

    /// The underlying condition variable object.
    let _cond: __Cond

    /// Initializes a new `ConditionVariable`.
    public init() {
        _cond = __Cond()
    }

    /// Waits on the condition variable with the given mutex lock.
    ///
    /// If the condition is not met, the current thread will be blocked until another thread signals
    /// or broadcasts the condition variable with `signal()` or `broadcast()`.
    ///
    /// - Parameter mutex: The mutex lock to use for the condition variable.
    public func wait(mutex: MutexLock) {
        _cond.wait(mutex: mutex._lock)
    }

    /// Waits on the condition variable with the given mutex lock until a specified date.
    ///
    /// If the condition is not met, the current thread will be blocked until the specified date is reached
    /// or another thread signals or broadcasts the condition variable with `signal()` or `broadcast()`.
    ///
    /// - Parameters:
    ///   - date: The date to wait until.
    ///   - mutex: The mutex lock to use for the condition variable.
    public func wait(until date: Date, mutex: MutexLock) -> TimeoutResult {
        var timespec = date.timeIntervalSince1970.timespec
        return _cond.wait(timespec: &timespec, mutex: mutex._lock)
    }

    /// Waits on the condition variable with the given mutex lock for a specified timespan.
    ///
    /// If the condition is not met, the current thread will be blocked until the specified timespan
    /// has elapsed or another thread signals or broadcasts the condition variable with `signal()` or `broadcast()`.
    ///
    /// - Parameters:
    ///   - timespan: The timespan to wait for.
    ///   - mutex: The mutex lock to use for the condition variable.
    public func wait(for timespan: Timespan, mutex: MutexLock) -> TimeoutResult {
        var timespec = timespan.asTimeIntervalInSeconds.timespec
        return _cond.wait(relativeTimespec: &timespec, mutex: mutex._lock)
    }

    /// Wakes up one thread waiting on the condition variable, if there are any.
    public func signal() {
        _cond.signal()
    }

    /// Wakes up all threads waiting on the condition variable.
    public func broadcast() {
        _cond.broadcast()
    }
}
