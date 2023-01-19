//
//  Atomic.swift
//  
//
//  Created by EZOU on 2023/1/19.
//

import Foundation


/// Detail implementation of protecting critical area for reading and writing operation
public struct AtomicImpl<T> {
    public typealias ReadTask = () -> T
    public typealias WriteTask = () -> Void
    public let read: (ReadTask) -> T
    public let write: (@escaping WriteTask) -> Void

    public init(
        read: @escaping (ReadTask) -> T,
        write: @escaping (@escaping WriteTask) -> Void)
    {
        self.read = read
        self.write = write
    }
}

extension AtomicImpl {
    /// Ensure atomicity using a POSIX mutex
    public static var mutex: AtomicImpl<T> {
        let lock = MutexLock()
        return AtomicImpl {
            lock.lock()
            defer { lock.unlock() }
            return $0()
        } write: {
            lock.lock()
            defer { lock.unlock() }
            $0()
        }
    }

    /// Ensure atomicity using a POSIX rwlock, which allows for concurrent reading but sequential writing.
    public static var rw: AtomicImpl<T> {
        let lock = RWLock()
        return AtomicImpl {
            lock.rdlock()
            defer { lock.unlock() }
            return $0()
        } write: {
            lock.wrlock()
            defer { lock.unlock() }
            $0()
        }
    }
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    /// Ensure atomicity using a os unfair lock (spin lock).
    public static var unfair: AtomicImpl<T> {
        let lock = UnfairLock()
        return AtomicImpl {
            lock.lock()
            defer { lock.unlock() }
            return $0()
        } write: {
            lock.lock()
            defer { lock.unlock() }
            $0()
        }
    }
#endif
    
#if canImport(Dispatch)
    /// Ensure atomicity using a GCD queue, which allows for concurrent reading but sequential writing.
    public static var gcd: AtomicImpl<T> {
        let queue = DispatchQueue(
            label: "AtomicGCD",
            attributes: [.concurrent])
        return AtomicImpl { task in
            queue.sync(execute: task)
        } write: { task in
            queue.`async`(flags: .barrier, execute: task)
        }
    }

    /// Default to `.gcd`
    public static var `default`: AtomicImpl<T> {
        .gcd
    }
#else
    /// Default to `.rw`
    public static var `default`: AtomicImpl<T> {
        .rw
    }
#endif
}
/// A property wrapper for performing atomic operations on a value.
///
/// This class provides thread-safe read and write access to a value.
/// The underlying implementation can be configured using the `AtomicImpl`.
/// The default implementation is `.gcd`.
///
/// Example usage:
///
///     @Atomic var count = 0
///     count += 1
///
/// Moreover, this class can be used other than a property wrapper. It provides you to perform
/// an atomic read/write operation on the value.
///
/// Example usage:
///
///     let atomic = Atomic(initialState: 10, impl: .rw)
///
///     // Atomic read operation
///
///     atomic.read { value in
///         // Do something
///     }
///
///     // Atomic mutating write operation
///
///     atomic.write { value in // value is a inout variable
///         // Do something
///     }
///
@propertyWrapper
public final class Atomic<T> {
    public var wrappedValue: T {
        get {
            impl.read {
                value
            }
        }
        set {
            impl.write {
                self.value = newValue
            }
        }
    }

    private let impl: AtomicImpl<T>
    private var value: T

    public init(wrappedValue: T, impl: AtomicImpl<T> = .default) {
        self.value = wrappedValue
        self.impl = impl
    }

    public convenience init(initialState: T, impl: AtomicImpl<T> = .unfair) {
        self.init(wrappedValue: initialState, impl: impl)
    }

    /// Performs an atomic write operation on the value.
    public func write(_ block: @escaping (inout T) -> Void) {
        impl.write {
            block(&self.value)
        }
    }

    /// Performs an atomic read operation on the value.
    public func read(_ block: @escaping (T) -> Void) {
        _ = impl.read {
            block(value)
            return value
        }
    }
}

extension Atomic where T == Void {
    public convenience init(impl: AtomicImpl<Void> = .unfair) {
        self.init(wrappedValue: (), impl: impl)
    }
}
