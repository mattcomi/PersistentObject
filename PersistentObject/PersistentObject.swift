// Copyright © 2017 Matt Comi. All rights reserved.

#if os(iOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif

/// A persistent object.
public class PersistentObject<ObjectType> {
  private let repository: AnyRepository<ObjectType>

  /// The object being persisted.
  public private(set) var object: ObjectType? = nil

  /// The delegate to notify when the object changes externally. Note that depending on the underlying repository, this
  /// may not occur. Default is `PersistentObjectDelegate()`.
  public let delegate: PersistentObjectDelegate<ObjectType>? = nil

  /// Initializes the `PersistentObject` with the specified repository.
  ///
  /// - parameter repository: The `Repository`.
  /// - parameter delegate: The `PersistentObjectDelegate` to notify when the object changes externally.
  public init<RepositoryType: Repository>(
    repository: RepositoryType,
    delegate: PersistentObjectDelegate<ObjectType>? = PersistentObjectDelegate())
    where ObjectType == RepositoryType.ObjectType {

    self.repository = AnyRepository(repository)

    self.repository.delegate.objectChangedExternally = { [weak self] repository, object in
      guard self != nil else {
        return
      }

      self!.reset(object: object)

      delegate?.objectChangedExternally?(self!)
    }

    object = repository.unarchive()

    #if os(iOS)
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationDidEnterBackgroundOrResignActive),
        name: NSNotification.Name.UIApplicationDidEnterBackground,
        object: nil)
    #elseif os(OSX)
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(applicationDidEnterBackgroundOrResignActive),
        name: NSApplication.didResignActiveNotification,
        object: nil)
    #endif
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    save()
  }

  /// Resets the persistent object.
  /// - parameter object: The new object to persist. If `nil`, the object will removed from the repository.
  public func reset(object: ObjectType?) {
    self.object = object
  }

  /// Saves the persistent object.
  /// - remark: This is also performed when the application enters the background and during deinitialization.
  public func save() {
    repository.archive(object)
  }

  /// Synchronizes the underlying `Repository`.
  public func synchronize() {
    repository.synchronize()
  }

  @objc private func applicationDidEnterBackgroundOrResignActive(notification: NSNotification) {
    save()
  }
}

public extension PersistentObject where ObjectType:NSCoding {
  /// Initializes the `PersistentObject` with a `UserDefaultsRepository`.
  /// - parameter userDefaultsKey: The key to associate with this object.
  /// - parameter userDefaults: The `UserDefaults` database. Defaults to `UserDefaults.standard`.
  public convenience init(userDefaultsKey: String, userDefaults: UserDefaults = UserDefaults.standard) {
    self.init(repository: UserDefaultsRepository(key: userDefaultsKey, userDefaults: userDefaults))
  }

  /// Initializes the `PersistentObject` with a `FileRepository`.
  /// - parameter filename: The filename.
  public convenience init(filename: String) {
    self.init(repository: FileRepository(filename: filename))
  }

  /// Initializes the `PersistentObject` with a `UbiquituousKeyValueStoreRepository`.
  /// - parameter ubiquituousKeyValueStoreKey: The key to associate with this object.
  /// - parameter delegate: The `PersistentObjectDelegate` to notify when the object changes externally.
  public convenience init(
    ubiquituousKeyValueStoreKey: String,
    delegate: PersistentObjectDelegate<ObjectType>? = PersistentObjectDelegate()) {
    self.init(repository: UbiquituousKeyValueStoreRepository(key: ubiquituousKeyValueStoreKey), delegate: delegate)
  }
}

/// A `PersistentObject` delegate.
public final class PersistentObjectDelegate<ObjectType> {
  /// Initializes the `PersistentObjectDelegate`.
  public init() { }

  /// A closure that is called when the object changed externally.
  /// - parameter persistentObject: The persistent object whose object changed externally.
  public var objectChangedExternally: ((PersistentObject<ObjectType>) -> Void)?
}
