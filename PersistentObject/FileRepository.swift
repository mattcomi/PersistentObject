// Copyright © 2016 Matt Comi. All rights reserved.

/// A `Repository` that persists to a file.
class FileRepository<ObjectType:NSCoding> : Repository {
  let delegate = RepositoryDelegate<ObjectType>()

  private let filename: String

  /// Initializes the `FileRepository` with the specified filename.
  ///
  /// - parameter filename: The filename.
  init(filename: String) {
    self.filename = filename
  }

  /// Archives an object to a file.
  ///
  /// - parameter object: The object. If `nil`, the file will be deleted.
  func archiveObject(object: ObjectType?) {
    if let object = object {
      NSKeyedArchiver.archiveRootObject(object, toFile: filename)
    } else {
      if NSFileManager.defaultManager().fileExistsAtPath(filename) {
        try! NSFileManager.defaultManager().removeItemAtPath(filename)
      }
    }
  }

  /// Unarchives an object from a file.
  ///
  /// - returns: The unarchived object.
  func unarchiveObject() -> ObjectType? {
    return NSKeyedUnarchiver.unarchiveObjectWithFile(filename) as? ObjectType
  }

  /// No effect.
  func synchronize() {
  }
}
