//
//  FilePermission.swift
//  
//
//  Created by EZOU on 2023/2/19.
//

import Foundation

/**
 An enumeration that represents different file permission modes.

 You can use these modes to specify the permissions for a file or directory using bitwise OR operators.

 For example, to specify that a file should have read and write permissions for the owner, but only read permissions for group members and others, you could use the following:

     let filePermissions: FilePermissions = [.ownerRead, .ownerWrite, .groupRead, .othersRead]

 For more information on file permissions and the bitwise OR operator, see the `chmod` man page.

 - Note: The `mode_t` type is typically defined in the C standard library and can be used interchangeably with this enumeration.
 */
public struct FilePermission: OptionSet {
    public let rawValue: mode_t

    public init(rawValue: mode_t) {
        self.rawValue = rawValue
    }

    /// Read permission for the owner of the file.
    public static let ownerRead = FilePermission(rawValue: S_IRUSR)

    /// Write permission for the owner of the file.
    public static let ownerWrite = FilePermission(rawValue: S_IWUSR)

    /// Execute permission for the owner of the file.
    public static let ownerExecute = FilePermission(rawValue: S_IXUSR)

    /// Read permission for users who are members of the file's group.
    public static let groupRead = FilePermission(rawValue: S_IRGRP)

    /// Write permission for users who are members of the file's group.
    public static let groupWrite = FilePermission(rawValue: S_IWGRP)

    /// Execute permission for users who are members of the file's group.
    public static let groupExecute = FilePermission(rawValue: S_IXGRP)

    /// Read permission for all other users (not the owner and not members of the file's group).
    public static let othersRead = FilePermission(rawValue: S_IROTH)

    /// Write permission for all other users (not the owner and not members of the file's group).
    public static let othersWrite = FilePermission(rawValue: S_IWOTH)

    /// Execute permission for all other users (not the owner and not members of the file's group).
    public static let othersExecute = FilePermission(rawValue: S_IXOTH)
}

extension FilePermission: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: UInt16) {
        self.rawValue = value
    }
}
