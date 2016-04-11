// Copyright © 2016 Matt Comi. All rights reserved.

/// A `Strategy` that uses the `NSUserDefaults` database.
public class UserDefaultsStrategy<ObjectType:NSCoding> : Strategy {
  private let key: String
  private var userDefaults: NSUserDefaults
  
  /// Initializes the `UserDefaultsStrategy` with the specified key and `NSUserDefaults` database.
  ///
  /// - parameter key:          The key to associate with this object.
  /// - parameter userDefaults: The `NSUserDefaults` database. Defaults to `NSUserDefaults.standardUserDefaults()`.
  /// - returns: The new `UserDefaultsStrategy` instance.
  public init(key: String, userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
    self.key = key
    self.userDefaults = userDefaults
  }
  
  /// Archives an object to the `NSUserDefaults` database.
  ///
  /// - parameter object: The object.
  public func archiveObject(object: ObjectType?) {
    if let object = object {
      userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
    } else {
      userDefaults.removeObjectForKey(key)
    }
  }
  
  /// Unarchives an object from the `NSUserDefaults` database.
  ///
  /// - returns: The unarchived object.
  public func unarchiveObject() -> ObjectType? {
    if let data = userDefaults.objectForKey(key) as? NSData {
      return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ObjectType
    }
    
    return nil
  }
  
  /// Synchronizes the `NSUserDefaults` database.
  public func synchronize() {
    userDefaults.synchronize()
  }
}