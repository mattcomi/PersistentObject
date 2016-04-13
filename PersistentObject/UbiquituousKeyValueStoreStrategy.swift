// Copyright © 2016 Matt Comi. All rights reserved.

/// A `Strategy` that uses the `NSUbiquituousKeyValueStore`.
class UbiquituousKeyValueStoreStrategy<ObjectType:NSCoding> : Strategy {
  let delegate = StrategyDelegate<ObjectType>()
  
  private let key: String
  
  /// Initializes the `UbiquituousKeyValueStoreStrategy` with the specified key.
  ///
  /// - parameter key:      The key to associate with this object.
  /// - parameter delegate: The delegate. Default is `nil`.
  init(key: String) {
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
  func archiveObject(object: ObjectType?) {
    let store = NSUbiquitousKeyValueStore.defaultStore()
    
    if let object = object {
      store.setData(NSKeyedArchiver.archivedDataWithRootObject(object), forKey: key)
    } else {
      store.removeObjectForKey(key)
    }
  }
  
  /// Unarchives an object from the `NSUbiquituousKeyValueStore` and synchronizes immediately to determine if a newer
  /// value exists in iCloud. If a newer value is found, it will replace
  ///
  /// - returns: The unarchived object.
  func unarchiveObject() -> ObjectType? {
    return unarchiveObject(synchronize: true)
  }
  
  /// Synchronizes the `NSUbiquituousKeyValueStore`.
  func synchronize() {
    NSUbiquitousKeyValueStore.defaultStore().synchronize()
  }
  
  private func unarchiveObject(synchronize synchronize: Bool) -> ObjectType? {
    var object: ObjectType? = nil
    
    let store = NSUbiquitousKeyValueStore.defaultStore()
    if let data = store.dataForKey(key) {
      object = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? ObjectType
    }
    
    if synchronize {
      store.synchronize()
    }
    
    return object
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
      return
    }
    
    if keys.contains(key) {
      let object = self.unarchiveObject(synchronize: false)
      
      self.delegate.objectChangedExternally?(strategy: AnyStrategy(strategy: self), object: object)
    }
  }
}