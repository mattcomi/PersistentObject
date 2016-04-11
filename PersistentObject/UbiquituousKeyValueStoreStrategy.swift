// Copyright © 2016 Matt Comi. All rights reserved.

public protocol UbiquituousKeyValueStoreDelegate {
  func objectChangedExternally<ObjectType>(strategy: UbiquituousKeyValueStoreStrategy<ObjectType>)
}

/// A `Strategy` that uses the `NSUbiquituousKeyValueStore`.
public class UbiquituousKeyValueStoreStrategy<ObjectType:NSCoding> : Strategy {
  private let key: String
  
  /// The delegate that is notified when the object changes externally.
  public var delegate: UbiquituousKeyValueStoreDelegate? = nil
  
  /// Initializes the `UbiquituousKeyValueStoreStrategy` with the specified key.
  ///
  /// - parameter key: The key to associate with this object.
  /// - returns: The new `UbiquituousKeyValueStoreStrategy` instance.
  public init(key: String) {
    self.key = key
    
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(ubiquitousKeyValueStoreDidChangeExternally),
      name: NSUbiquitousKeyValueStoreDidChangeExternallyNotification,
      object: NSUbiquitousKeyValueStore.defaultStore())
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
  }
  
  /// Archives an object to the `NSUbiquituousKeyValueStore`.
  ///
  /// - parameter object: The object.
  public func archiveObject(object: ObjectType?) {
    if let object = object {
      let store = NSUbiquitousKeyValueStore.defaultStore()
      
      store.setData(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
    }
  }
  
  /// Unarchives an object from the `NSUbiquituousKeyValueStore` database.
  ///
  /// - returns: The unarchived object.
  public func unarchiveObject() -> ObjectType? {
    let store = NSUbiquitousKeyValueStore.defaultStore()
    if let data = store.dataForKey(key) {
      return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ObjectType
    }
    
    return nil
  }
  
  /// Synchronizes the `NSUbiquituousKeyValueStore`.
  public func synchronize() {
    NSUbiquitousKeyValueStore.defaultStore().synchronize()
  }
  
  @objc private func ubiquitousKeyValueStoreDidChangeExternally(notification: NSNotification) {
    guard let userInfo = notification.userInfo else {
      return
    }
    
    guard let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
      return
    }
    
    guard reason == NSUbiquitousKeyValueStoreInitialSyncChange || reason == NSUbiquitousKeyValueStoreServerChange else {
      return
    }
    
    guard let keys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
      print(userInfo[NSUbiquitousKeyValueStoreChangedKeysKey])
      return
    }
    
    if keys.contains(key) {
      self.unarchiveObject()
      
      self.delegate?.objectChangedExternally(self)
    }
  }
}