//
//  Timespan.swift
//  
//
//  Created by EZOU on 2023/2/19.
//

import Foundation

/// A period of time between fixed points
@frozen public enum Timespan {
    /// Seconds
    case seconds(TimeInterval)
    /// Milliseconds
    case milliseconds(TimeInterval)
    /// Microseconds
    case microseconds(TimeInterval)
    /// Nanoseconds
    case nanoseconds(TimeInterval)

    @inlinable
    var asTimeIntervalInSeconds: TimeInterval {
        switch self {
        case .seconds(let timeInterval):
            return timeInterval
        case .milliseconds(let timeInterval):
            return timeInterval / 1_000
        case .microseconds(let timeInterval):
            return timeInterval / 1_000_000
        case .nanoseconds(let timeInterval):
            return timeInterval / 1_000_000_000
        }
    }
}

extension Timespan: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double

    public init(floatLiteral value: Double) {
        self = .seconds(value)
    }
}

extension TimeInterval {
    var timespec: timespec {
        let seconds = rounded(.down)
        let ns = (self - seconds) * 1_000_000_000
        return Darwin.timespec(tv_sec: Int(seconds), tv_nsec: Int(ns))
    }
}
