// Copyright © 2016 Matt Comi. All rights reserved.

/// A `Repository` that persists to the `NSUbiquituousKeyValueStore`.
class UbiquituousKeyValueStoreRepository<ObjectType:NSCoding> : Repository {
  let delegate = RepositoryDelegate<ObjectType>()
  
  private let key: String
  
  /// Initializes the `UbiquituousKeyValueStoreRepository` with the specified key.
  ///
  /// - parameter key: The key to associate with this object.
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
  /// value exists in iCloud.
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
      
      self.delegate.objectChangedExternally?(repository: AnyRepository(self), object: object)
    }
  }
}