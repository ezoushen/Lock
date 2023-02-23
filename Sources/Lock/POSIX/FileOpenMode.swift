//
//  FileOpenMode.swift
//  
//
//  Created by EZOU on 2023/2/19.
//

import Foundation

/// Options for opening a file.
///
/// Use these options to specify how a file should be opened or created. You can combine multiple options using bitwise OR (`|`) to create a single set of options.
///
/// Example:
///
/// ```
/// let mode: FileOpenMode = [.read, .write, .create]
/// ```
public struct FileOpenMode: OptionSet {

    /// The underlying raw value type of this option set.
    public typealias RawValue = Int32

    /// Creates an option set with the given raw value.
    public init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// The raw value of the option set.
    public let rawValue: Int32

    /// The file should be opened for reading.
    public static let read = FileOpenMode(rawValue: FREAD)

    /// The file should be opened for writing.
    public static let write = FileOpenMode(rawValue: FWRITE)

    /// The file should be opened with no delay.
    public static let nonBlocking = FileOpenMode(rawValue: O_NONBLOCK)

    /// The file should be opened in append mode.
    public static let append = FileOpenMode(rawValue: O_APPEND)

    /// The file should be opened with a shared lock.
    public static let sharedLock = FileOpenMode(rawValue: O_SHLOCK)

    /// The file should be opened with an exclusive lock.
    public static let exclusiveLock = FileOpenMode(rawValue: O_EXLOCK)

    /// The process group should be signaled when data is ready to read.
    public static let async = FileOpenMode(rawValue: O_ASYNC)

    /// The file should be opened without delay and all writes should be synchronized with the file descriptor.
    public static let sync = FileOpenMode(rawValue: O_FSYNC)

    /// The file should not be followed if it is a symbolic link.
    public static let noFollow = FileOpenMode(rawValue: O_NOFOLLOW)

    /// The file should be created if it does not exist.
    public static let create = FileOpenMode(rawValue: O_CREAT)

    /// The file should be truncated to zero length if it already exists.
    public static let truncate = FileOpenMode(rawValue: O_TRUNC)

    /// An error should be returned if the file already exists.
    public static let exclusiveCreate = FileOpenMode(rawValue: O_EXCL)

    /// The file descriptor should be used only for event notifications.
    public static let eventOnly = FileOpenMode(rawValue: O_EVTONLY)

    /// The file should not be used as the process's controlling terminal.
    public static let noCTTY = FileOpenMode(rawValue: O_NOCTTY)

    /// The file should be treated as a directory.
    public static let directory = FileOpenMode(rawValue: O_DIRECTORY)

    /// The file should be followed if it is a symbolic link.
    public static let symlink = FileOpenMode(rawValue: O_SYMLINK)

    /// The file should be opened for execute-only access.
    public static let executeOnly = FileOpenMode(rawValue: O_EXEC)

    /// The directory should be opened for search-only access.
    public static let searchOnly = FileOpenMode(rawValue: O_SEARCH)

    /// All subsequent file descriptors opened by this process should have the `close-on-exec` flag set.
    public static let closeOnExec = FileOpenMode(rawValue: O_CLOEXEC)

    /// No symbolic links are allowed in the path.
    public static let noFollowAny = FileOpenMode(rawValue: O_NOFOLLOW_ANY)
}

extension FileOpenMode: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int32) {
        rawValue = value
    }
}
