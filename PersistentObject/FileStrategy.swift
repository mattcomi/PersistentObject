// Copyright © 2016 Matt Comi. All rights reserved.

/// A `Strategy` that persists to a file.
class FileStrategy<ObjectType:NSCoding> : Strategy {
  let delegate = StrategyDelegate<ObjectType>()
  
  private let filename: String
    
  /// Initializes the `FileStrategy` with the specified filename.
  ///
  /// - parameter filename: The filename.
  init(filename: String) {
    self.filename = filename
  }
  
  /// Archives an object to a file.
  ///
  /// - parameter object: The object.
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