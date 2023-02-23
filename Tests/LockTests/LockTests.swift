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

    func test_writeBlock_throws() {
        enum Dummy: Error { case dummy }
        for impl in [AtomicImpl<Int>.mutex, .rw, .unfair, .gcd] {
            let lock = Atomic(initialState: 10, impl: impl)
            XCTAssertThrowsError(try lock.withMutableValue { _ in throw Dummy.dummy})
        }
    }

    func test_readBlock_throws() {
        enum Dummy: Error { case dummy }
        for impl in [AtomicImpl<Int>.mutex, .rw, .unfair, .gcd] {
            let lock = Atomic(initialState: 10, impl: impl)
            XCTAssertThrowsError(try lock.withValue { _ in throw Dummy.dummy})
        }
    }
}

final class SemTests: XCTestCase {
    func test_tryWait_shouldReturnFalse() {
        let sem = Semaphore(value: 2)

        sem.wait()
        sem.wait()

        XCTAssertFalse(sem.tryWait())
    }

    func test_tryWait_shouldReturnTrueAfterSignaled() {
        let sem = Semaphore(value: 2)

        sem.wait()
        sem.wait()
        sem.signal()

        XCTAssertTrue(sem.tryWait())
    }

    func test_tryWait_shouldReturnTrue() {
        let sem = Semaphore(value: 3)

        sem.wait()
        sem.wait()

        XCTAssertTrue(sem.tryWait())
    }
}

final class CondTests: XCTestCase {
    var cond: ConditionVariable!
    var lock: MutexLock!

    override func setUp() {
        cond = ConditionVariable()
        lock = MutexLock()
    }

    func test_wait() {
        var called: Bool = false

        lock.lock()

        DispatchQueue.global().async {
            called = true
            self.cond.signal()
        }

        cond.wait(mutex: lock)

        XCTAssertTrue(called)

        lock.unlock()
    }

    func test_timedwait_relative_shouldTimeout() {
        lock.lock()

        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            self.cond.signal()
        }

        let result = cond.wait(for: .milliseconds(100), mutex: lock)

        XCTAssertEqual(result, .timeout)

        lock.unlock()
    }

    func test_timedwait_relative_shouldSuccess() {
        lock.lock()

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.cond.signal()
        }

        let result = cond.wait(for: .seconds(100), mutex: lock)

        XCTAssertEqual(result, .success)

        lock.unlock()
    }

    func test_broadcast() {
        var expectations: [XCTestExpectation] = []

        let calleds = UnsafeMutableBufferPointer<Bool>.allocate(capacity: 5)

        for i in 0...4 {
            calleds[i] = false
            let expectation = expectation(description: "\(#function)")
            expectations.append(expectation)
            DispatchQueue.global(qos: .userInteractive).async {
                self.lock.lock()
                self.cond.wait(mutex: self.lock)
                calleds[i] = true
                self.lock.unlock()
                expectation.fulfill()
            }
        }

        DispatchQueue.global(qos: .background).async {
            self.cond.broadcast()
        }

        wait(for: expectations, timeout: 10.0)

        XCTAssertTrue(calleds.allSatisfy { $0 })
    }

    func test_timedwait_shouldSuccess() {
        let targetDate = Date(timeIntervalSinceNow: 100)
        lock.lock()

        DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(100)) {
            self.cond.signal()
        }

        let result = cond.wait(until: targetDate, mutex: lock)

        XCTAssertEqual(result, .success)

        lock.unlock()
    }

    func test_timedwait_shouldTimeout() {
        let targetDate = Date(timeIntervalSinceNow: 0.1)
        lock.lock()

        DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
            self.cond.signal()
        }

        let result = cond.wait(until: targetDate, mutex: lock)

        XCTAssertEqual(result, .timeout)

        lock.unlock()
    }
}
