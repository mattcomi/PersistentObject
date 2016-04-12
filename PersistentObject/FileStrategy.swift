// Copyright © 2016 Matt Comi. All rights reserved.

/// A `Strategy` that persists to a file.
public class FileStrategy<ObjectType:NSCoding> : Strategy {
  private let filename: String
  
  /// Initializes the `FileStrategy` with the specified filename.
  ///
  /// - parameter filename: The filename.
  public init(filename: String) {
    self.filename = filename
  }
  
  /// Archives an object to a file.
  ///
  /// - parameter object: The object.
  public func archiveObject(object: ObjectType?) {
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
  public func unarchiveObject() -> ObjectType? {
    return NSKeyedUnarchiver.unarchiveObjectWithFile(filename) as? ObjectType
  }
  
  /// No effect.
  public func synchronize() {
  }
}