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
