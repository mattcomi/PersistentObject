// Copyright © 2016 Matt Comi. All rights reserved.

/// A delegate of the `UbiquituousKeyValueStoreStrategy`.
public protocol UbiquituousKeyValueStoreDelegate {
  /// Called when the object changed externally.
  ///
  /// - parameter strategy: The object's strategy.
  func objectChangedExternally<ObjectType>(strategy: UbiquituousKeyValueStoreStrategy<ObjectType>)
}

/// A `Strategy` that uses the `NSUbiquituousKeyValueStore`.
public class UbiquituousKeyValueStoreStrategy<ObjectType:NSCoding> : Strategy {
  private let key: String
  
  /// The delegate that is notified when the object changes externally.
  public var delegate: UbiquituousKeyValueStoreDelegate? = nil
  
  /// Initializes the `UbiquituousKeyValueStoreStrategy` with the specified key.
  ///
  /// - parameter key:      The key to associate with this object.
  /// - parameter delegate: The delegate. Default is `nil`.
  public init(key: String, delegate: UbiquituousKeyValueStoreDelegate? = nil) {
    self.key = key
    self.delegate = delegate
    
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
  
  /// Unarchives an object from the `NSUbiquituousKeyValueStore` database and synchronizes.
  ///
  /// - returns: The unarchived object.
  public func unarchiveObject() -> ObjectType? {
    return unarchiveObject(synchronize: true)
  }
  
  /// Synchronizes the `NSUbiquituousKeyValueStore`.
  public func synchronize() {
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
      self.unarchiveObject(synchronize: false)
      
      self.delegate?.objectChangedExternally(self)
    }
  }
}