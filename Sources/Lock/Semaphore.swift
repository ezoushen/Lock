//
//  Semaphore.swift
//
//
//  Created by EZOU on 2023/2/19.
//

import Foundation

final class __Semaphore {

    let _name: String
    let _sem: UnsafeMutablePointer<sem_t>!

    init(name: String, oflag: Int32, mode: mode_t, value: UInt32) {
        self._name = name
        self._sem = sem_open(name, oflag, mode, value)

        if _sem == SEM_FAILED {
            assert(posixCode: errno)
        }
    }

    func wait() {
        let code = sem_wait(_sem)
        assert(posixCode: code)
    }

    func tryWait() -> Bool {
        if sem_trywait(_sem) == 0 {
            return true
        }
        switch errno {
        case EAGAIN:
            return false
        default:
            assert(posixCode: errno)
            return false
        }
    }

    func signal() {
        let code = sem_post(_sem)
        assert(posixCode: code)
    }

    deinit {
        sem_close(_sem)
        sem_unlink(_name)
        _sem.deinitialize(count: 1)
    }
}


///
/// A couting semaphore.
///
/// Semaphores are a synchronization primitive that can be used to protect shared resources. A semaphore maintains a
/// count that can be incremented by calling `signal()` and decremented by calling `wait()`. When the count reaches zero,
/// calls to `wait()` will block until another thread calls `signal()`. This can be used to limit the number of threads that can
/// access a resource concurrently.
///
public struct Semaphore {
    class __Name { }

    let _sem: __Semaphore
    let _name: __Name?

    /// Creates a new counting semaphore.
    ///
    /// - Parameters:
    ///    - name: The name of the semaphore. If `nil`, a random unlinked name will be used automatically.
    ///    - oflag: The file open mode to use when creating the semaphore. The default value is `[.create, .exclusiveCreate]`, which creates a new semaphore if it does not already exist.
    ///    - mode: The file permission to use when creating the semaphore. The default value is `[.ownerRead, .ownerWrite]`, which grants read and write permissions to the owner of the file.
    ///    - value: The initial value of the semaphore. This determines the maximum number of threads that can access the protected resource concurrently.
    ///
    public init(
        name: String? = nil,
        oflag: FileOpenMode = [.create, .exclusiveCreate],
        mode: FilePermission = [.ownerRead, .ownerWrite],
        value: UInt32)
    {
        _name = name == nil ? __Name() : nil
        _sem = __Semaphore(
            name: name ?? "\(Unmanaged.passUnretained(_name!).toOpaque())",
            oflag: oflag.rawValue, mode: mode.rawValue, value: value)
    }

    ///
    /// Signals the semaphore.
    ///
    /// Increments the semaphore count. If there are threads waiting on the semaphore, one of them will be woken up.
    ///
    public func signal() {
        _sem.signal()
    }


    /// Waits on the semaphore.
    ///
    /// Decrements the semaphore count. If the count is zero, this call will block until another thread calls `signal()`.
    public func wait() {
        _sem.wait()
    }


    /// Attempts to wait on the semaphore.
    ///
    /// Decrements the semaphore count if it is greater than zero.
    /// If the count is zero, this call will return immediately with a value of `false`.
    ///
    /// - Returns: `true` if the semaphore count was successfully decremented, `false` otherwise.
    ///
    public func tryWait() -> Bool {
        return _sem.tryWait()
    }
}


