// Copyright © 2016 Matt Comi. All rights reserved.

/// An object that persists itself to the `NSUserDefaults` database.
public class PersistentObject<T:NSCoding> {
  /// The object being persisted.
  public private(set) var object: T?
  /// The `NSUserDefaults` key associated with this object.
  public private(set) var key: String
  private var userDefaults: NSUserDefaults
  
  /// Initializes the `PersistentObject` with the specified key.
  /// - parameter key:          The `NSUserDefaults` key to associate with this object.
  /// - parameter userDefaults: The `NSUserDefaults` database. Defaults to `NSUserDefaults.standardUserDefaults()`.
  /// - returns: The new `PersistentObject` instance.
  public init(key: String, userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) {
    self.key = key
    self.userDefaults = userDefaults
    
    if let data = userDefaults.objectForKey(key) as? NSData {
      object = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? T
    }
  }
  
  deinit {
    synchronize()
  }
  
  /// Resets the persistent object. Setting this to `nil` will remove the key from `NSUserDefaults`.
  /// - parameter object: The new object to persist or `nil`.
  public func reset(object: T?) {
    self.object = object
  }
  
  /// Synchronize the persistent object.
  /// - remark: This is also performed during deinitialization.
  public func synchronize() {
    if let object = self.object {
      userDefaults.setObject(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
    } else {
      userDefaults.removeObjectForKey(key)
    }
  }
}
