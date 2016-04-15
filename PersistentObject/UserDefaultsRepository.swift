// Copyright © 2016 Matt Comi. All rights reserved.

/// A `Repository` that persists to the `NSUserDefaults` database.
class UserDefaultsRepository<ObjectType:NSCoding> : Repository {
  let delegate = RepositoryDelegate<ObjectType>()

  private let key: String
  private var userDefaults: NSUserDefaults

  /// Initializes the `UserDefaultsRepository` with the specified key and `NSUserDefaults` database.
  ///
  /// - parameter key:          The key.
  /// - parameter userDefaults: The `NSUserDefaults` database.
  init(key: String, userDefaults: NSUserDefaults) {
    self.key = key
    self.userDefaults = userDefaults
  }

  /// Archives an object to the `NSUserDefaults` database.
  ///
  /// - parameter object: The object.
  func archiveObject(object: ObjectType?) {
    if let object = object {
      userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
    } else {
      userDefaults.removeObjectForKey(key)
    }
  }

  /// Unarchives an object from the `NSUserDefaults` database.
  ///
  /// - returns: The unarchived object.
  func unarchiveObject() -> ObjectType? {
    if let data = userDefaults.objectForKey(key) as? NSData {
      return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ObjectType
    }

    return nil
  }

  /// Synchronizes the `NSUserDefaults` database.
  func synchronize() {
    userDefaults.synchronize()
  }
}
