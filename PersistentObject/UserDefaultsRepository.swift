// Copyright © 2017 Matt Comi. All rights reserved.

/// A `Repository` that persists to the `NSUserDefaults` database.
class UserDefaultsRepository<ObjectType:NSCoding> : Repository {
  let delegate = RepositoryDelegate<ObjectType>()

  private let key: String
  private var userDefaults: UserDefaults

  /// Initializes the `UserDefaultsRepository` with the specified key and `NSUserDefaults` database.
  ///
  /// - parameter key:          The key.
  /// - parameter userDefaults: The `UserDefaults` database.
  init(key: String, userDefaults: UserDefaults) {
    self.key = key
    self.userDefaults = userDefaults
  }

  /// Archives an object to the `NSUserDefaults` database.
  /// - parameter object: The object.
  func archive(_ object: ObjectType?) {
    if let object = object {
      userDefaults.set(NSKeyedArchiver.archivedData(withRootObject: object), forKey: key)
    } else {
      userDefaults.removeObject(forKey: key)
    }
  }

  /// Unarchives an object from the `NSUserDefaults` database.
  /// - returns: The unarchived object.
  func unarchive() -> ObjectType? {
    if let data = userDefaults.object(forKey: key) as? Data {
      return NSKeyedUnarchiver.unarchiveObject(with: data) as? ObjectType
    }

    return nil
  }

  /// Synchronizes the `NSUserDefaults` database.
  func synchronize() {
    userDefaults.synchronize()
  }
}
