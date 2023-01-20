import XCTest
@testable import Lock

final class UnfairLockTests: XCTestCase {
    func test_lock_unlock() {
        let lock = UnfairLock()
        var sharedResource: Int = 0
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            lock.lock()
            sharedResource += 1
            lock.unlock()
        }
        XCTAssertEqual(sharedResource, 100)
    }

    func test_tryLock_unlock() {
        let lock = UnfairLock()
        var sharedResource: Int = 0
        let result = lock.tryLock()
        sharedResource += 1
        lock.unlock()
        XCTAssertTrue(result)
    }

    func test_tryLock_shouldReturnFalseAfterLocked() {
        let lock = UnfairLock()
        lock.lock()
        let result = lock.tryLock()
        lock.unlock()
        XCTAssertFalse(result)
    }
}

final class MutexLockTests: XCTestCase {
    func test_lock_unlock() {
        let lock = MutexLock()
        var sharedResource: Int = 0
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            lock.lock()
            sharedResource += 1
            lock.unlock()
        }
        XCTAssertEqual(sharedResource, 100)
    }

    func test_tryLock_unlock() {
        let lock = MutexLock()
        var sharedResource: Int = 0
        let result = lock.tryLock()
        sharedResource += 1
        lock.unlock()
        XCTAssertTrue(result)
    }

    func test_tryLock_shouldReturnFalseAfterLocked() {
        let lock = MutexLock()
        lock.lock()
        let result = lock.tryLock()
        lock.unlock()
        XCTAssertFalse(result)
    }

    func test_recursive() {
        let expectation = expectation(description: #function)
        var sharedResource = 0
        let lock = MutexLock(type: .recursive)
        DispatchQueue.global().async {
            lock.lock()
            sharedResource += 1
            lock.lock()
            sharedResource += 1
            lock.unlock()
            lock.unlock()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(sharedResource, 2)
    }
}

final class RWLockTests: XCTestCase {
    func test_lock_unlock() {
        let lock = RWLock()
        var sharedResource: Int = 0
        DispatchQueue.concurrentPerform(iterations: 100) { _ in
            lock.wrlock()
            sharedResource += 1
            lock.unlock()
        }
        XCTAssertEqual(sharedResource, 100)
    }

    func test_tryRdlock() {
        let lock = RWLock()
        XCTAssertTrue(lock.tryRdlock())
        XCTAssertTrue(lock.tryRdlock())
        lock.unlock()
        lock.unlock()
    }

    func test_tryWrlock() {
        let lock = RWLock()
        XCTAssertTrue(lock.tryWrlock())
        XCTAssertFalse(lock.tryWrlock())
        lock.unlock()
    }

    func test_tryWrlockRdlock() {
        let lock = RWLock()
        XCTAssertTrue(lock.tryWrlock())
        XCTAssertFalse(lock.tryRdlock())
        lock.unlock()
    }
}

final class AtomicTests: XCTestCase {
    func test_read_usingGCD() {
        let atomic = Atomic(initialState: 10, impl: .gcd)
        let result = atomic.withValue { _ in
            return 100
        }
        XCTAssertEqual(result, 100)
    }

    func test_write_usingGCD() {
        let atomic = Atomic(initialState: 10, impl: .gcd)
        let result = atomic.withMutableValue { _ in
            return 100
        }
        XCTAssertEqual(result, 100)
    }

    func test_read_usingRW() {
        let atomic = Atomic(initialState: 10, impl: .rw)
        let result = atomic.withValue { _ in
            return 100
        }
        XCTAssertEqual(result, 100)
    }

    func test_write_usingRW() {
        let atomic = Atomic(initialState: 10, impl: .rw)
        let result = atomic.withMutableValue { _ in
            return 100
        }
        XCTAssertEqual(result, 100)
    }

    func test_read_usingMutex() {
        let atomic = Atomic(initialState: 10, impl: .mutex)
        let result = atomic.withValue { _ in
            return 100
        }
        XCTAssertEqual(result, 100)
    }

    func test_write_usingMutex() {
        let atomic = Atomic(initialState: 10, impl: .mutex)
        let result = atomic.withMutableValue { _ in
            return 100
        }
        XCTAssertEqual(result, 100)
    }

    func test_read_usingUnfair() {
        let atomic = Atomic(initialState: 10, impl: .unfair)
        let result = atomic.withValue { _ in
            return 100
        }
        XCTAssertEqual(result, 100)
    }

    func test_write_usingUnfair() {
        let atomic = Atomic(initialState: 10, impl: .unfair)
        let result = atomic.withMutableValue { _ in
            return 100
        }
        XCTAssertEqual(result, 100)
    }

    func test_writeBlock() {
        for impl in [AtomicImpl<Int>.mutex, .rw, .unfair, .gcd] {
            let lock = Atomic(initialState: 10, impl: impl)
            let expectation = expectation(description: #function)
            DispatchQueue.concurrentPerform(iterations: 100) { value in
                lock.withMutableValue {
                    $0 += 1
                }
                if value == 99 {
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 10.0)
            XCTAssertEqual(lock.wrappedValue, 110)
        }
    }
}
