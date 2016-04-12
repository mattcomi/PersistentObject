// Copyright © 2016 Matt Comi. All rights reserved.

/// A persistent object.
public class PersistentObject<ObjectType> {
  private let strategy: AnyStrategy<ObjectType>
  
  /// The object being persisted.
  public private(set) var object: ObjectType?
  
  /// Initializes the `PersistentObject` with the specified strategy.
  ///
  /// - parameter strategy:  The `PersistenceStrategy`.
  public init<StrategyType:Strategy where ObjectType == StrategyType.ObjectType>(strategy: StrategyType) {
    self.strategy = AnyStrategy(strategy: strategy)
    object = strategy.unarchiveObject()

    #if os(iOS)
      NSNotificationCenter.defaultCenter().addObserver(
        self,
        selector: #selector(applicationDidEnterBackground),
        name: UIApplicationDidEnterBackgroundNotification,
        object: nil)
    #endif
  }
  
  deinit {
    NSNotificationCenter.defaultCenter().removeObserver(self)
    save()
  }
  
  /// Resets the persistent object. Setting this to `nil` will remove the key from `NSUserDefaults`.
  ///
  /// - parameter object: The new object to persist or `nil`.
  public func reset(object: ObjectType?) {
    self.object = object
  }
  
  /// Saves the persistent object.
  ///
  /// - remark: This is also performed when the application enters the background and during deinitialization.
  public func save() {
    strategy.archiveObject(object)
  }
  
  @objc private func applicationDidEnterBackground(notification: NSNotification) {
    save()
  }
}

public extension PersistentObject where ObjectType:NSCoding {
  /// Initializes the `PersistentObject` with the `UserDefaults` strategy.
  ///
  /// - parameter key: The key to associate with this object.  
  public convenience init(key: String) {
    self.init(strategy: UserDefaultsStrategy(key: key))
  }
}