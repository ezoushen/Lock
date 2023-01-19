# Lock
Lock is a Swift package that provides a set of high-performance and thread-safe locking primitives.

## Features

- `Atomic`: A property wrapper that provides atomic read and write operations for any value type.
- `MutexLock`: A wrapper for POSIX pthread_mutex_t that provides mutual exclusion for critical sections.
- `RWLock`: A wrapper for POSIX pthread_rwlock_t that provides read-write locks for shared resources.
- `UnfairLock`: A wrapper for os_unfair_lock_t on iOS, macOS, tvOS and watchOS and OSAllocatedUnfairLock on iOS 14 and later, macOS 11 and later, tvOS 14 and later, watchOS 7 and later.

## Requirements
- Swift 5.2 or later
- iOS 12.0 or later, macOS 10.12 or later, tvOS 10.0 or later, watchOS 3.0 or later

## Installation

You can install Lock using the Swift Package Manager. Add the following dependency to your Package.swift file:

``` swift
.package(url: "https://github.com/username/Lock.git", from: "1.0.0")
```

And then add Lock to your target dependencies:

``` swift
.target(name: "YourTarget", dependencies: ["Lock"]),
```

## Usage

Here's an example of how to use Atomic to make a counter thread-safe:

``` swift
import Lock

let counter = Atomic(initialState: 0)

DispatchQueue.concurrentPerform(iterations: 100) { index in
    counter.write { 
        $0 += 1
    }
}

print(counter.wrappedValue) // 100
```
You can use MutexLock to protect a shared resource:

``` swift
import Lock

let lock = MutexLock()
var sharedResource = 0

DispatchQueue.concurrentPerform(iterations: 100) { index in
    lock.lock()
    sharedResource += 1
    lock.unlock()
}

print(sharedResource) // 100
```
You can use RWLock for read-write locking:
``` swift
import Lock

let lock = RWLock()
var sharedResource = 0

DispatchQueue.concurrentPerform(iterations: 100) { index in
    lock.wrlock()
    sharedResource += 1
    lock.unlock()
}

DispatchQueue.concurrentPerform(iterations: 100) { index in
    lock.rdlock()
    print(sharedResource)
    lock.unlock()
}
```

You can use UnfairLock for lock/unlock operations:

``` swift
import Lock

let lock = UnfairLock()
var sharedResource = 0

DispatchQueue.concurrentPerform(iterations: 100) { index in
    lock.lock()
    sharedResource += 1
    lock.unlock()
}

print(sharedResource) // 100
```

# License

Lock is released under the MIT license. See LICENSE for details.
