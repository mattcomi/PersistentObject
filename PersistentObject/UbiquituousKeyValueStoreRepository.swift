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

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(ubiquitousKeyValueStoreDidChangeExternally),
      name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
      object: NSUbiquitousKeyValueStore.default)
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// Archives an object to the `NSUbiquituousKeyValueStore`.
  /// - parameter object: The object.
  func archive(_ object: ObjectType?) {
    let store = NSUbiquitousKeyValueStore.default

    if let object = object {
      store.set(NSKeyedArchiver.archivedData(withRootObject: object), forKey: key)
    } else {
      store.removeObject(forKey: key)
    }
  }

  /// Unarchives an object from the `NSUbiquituousKeyValueStore` and synchronizes immediately to determine if a newer
  /// value exists in iCloud.
  /// - returns: The unarchived object.
  func unarchive() -> ObjectType? {
    return unarchiveObject(synchronize: true)
  }

  /// Synchronizes the `NSUbiquituousKeyValueStore`.
  func synchronize() {
    NSUbiquitousKeyValueStore.default.synchronize()
  }

  private func unarchiveObject(synchronize: Bool) -> ObjectType? {
    var object: ObjectType? = nil

    let store = NSUbiquitousKeyValueStore.default

    if let data = store.data(forKey: key) {
      object = NSKeyedUnarchiver.unarchiveObject(with: data) as? ObjectType
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

      self.delegate.objectChangedExternally?(AnyRepository(self), object)
    }
  }
}
