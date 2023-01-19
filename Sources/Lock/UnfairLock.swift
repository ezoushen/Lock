#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
import Foundation
import os

class __UnfairLock {
    func lock() { fatalError() }
    func unlock() { fatalError() }
    func tryLock() -> Bool { fatalError() }
}

/// Wrapper for `os_unfair_lock`
final class __OSUnfairLock: __UnfairLock {
    let _lock: os_unfair_lock_t

    override init() {
        _lock = .allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    override func lock() {
        os_unfair_lock_lock(_lock)
    }

    override func unlock() {
        os_unfair_lock_unlock(_lock)
    }

    override func tryLock() -> Bool {
        os_unfair_lock_trylock(_lock)
    }

    deinit {
        _lock.deinitialize(count: 1)
        _lock.deallocate()
    }
}

/// Wrapper for `OSAllocatedUnfairLock`
@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
class __OSAllocatedUnfairLock: __UnfairLock {
    let _lock = OSAllocatedUnfairLock()

    override func lock() {
        _lock.lock()
    }

    override func unlock() {
        _lock.unlock()
    }

    override func tryLock() -> Bool {
        _lock.lockIfAvailable()
    }
}

/// A struct for performing unfair locks.
///
/// This struct provides a simple lock implementation that uses an unfair lock internally. An unfair lock does not
/// guarantee fairness in granting access to the locked resource, but can have better performance than a fair lock.
/// On newer systems, `OSAllocatedUnfairLock` is used, otherwise `__OSUnfairLock` is used.
///
/// Example usage:
///
///     let lock = UnfairLock()
///     lock.lock()
///     // protected code
///     lock.unlock()
///
public struct UnfairLock: SimpleLock {
    let __lock: __UnfairLock

    /// Creates a new instance of the unfair lock.
    public init() {
        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
            __lock = __OSAllocatedUnfairLock()
        } else {
            __lock = __OSUnfairLock()
        }
    }

    /// Acquires the lock.
    public func lock() {
        __lock.lock()
    }

    /// Releases the lock.
    public func unlock() {
        __lock.unlock()
    }

    /// Tries to acquire the lock and return true if it succeeds.
    public func tryLock() -> Bool {
        __lock.tryLock()
    }
}
#endif
