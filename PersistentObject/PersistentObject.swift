// Copyright © 2016 Matt Comi. All rights reserved.

#if os(iOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif

/// A persistent object.
public class PersistentObject<ObjectType> {
  private let strategy: AnyStrategy<ObjectType>
  
  /// The delegate to notify when the object changes externally.
  public weak var delegate: PersistentObjectDelegate?
  
  /// The object being persisted.
  public private(set) var object: ObjectType?
  
  /// Initializes the `PersistentObject` with the specified strategy.
  ///
  /// - parameter strategy:  The `Strategy`.
  public init<StrategyType:Strategy where ObjectType == StrategyType.ObjectType>(
    strategy: StrategyType, delegate: PersistentObjectDelegate? = nil) {
    self.strategy = AnyStrategy(strategy: strategy)
    
    self.strategy.delegate.objectChangedExternally = { [weak self] strategy, object in
      guard self != nil else {
        return
      }
      
      self!.object = object
      delegate?.objectChangedExternally(self!)
    }
    
    object = strategy.unarchiveObject()

    #if os(iOS)
      NSNotificationCenter.defaultCenter().addObserver(
        self,
        selector: #selector(applicationDidEnterBackgroundOrResignActive),
        name: UIApplicationDidEnterBackgroundNotification,
        object: nil)
    #elseif os(OSX)
      NSNotificationCenter.defaultCenter().addObserver(
        self,
        selector: #selector(applicationDidEnterBackgroundOrResignActive),
        name: NSApplicationDidResignActiveNotification,
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
  
  /// Synchronizes the underlying `Strategy`.
  public func synchronize() {
    strategy.synchronize()
  }
  
  /// Called by the underlying `Strategy` when the object changed externally.
  ///
  /// - parameter strategy: The object's strategy.
  /// - parameter object:   The new object.
  /// ::TODO::

  @objc private func applicationDidEnterBackgroundOrResignActive(notification: NSNotification) {
    save()
  }
}

public extension PersistentObject where ObjectType:NSCoding {
  public class func userDefaults(
    key key: String,
    userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) -> PersistentObject<ObjectType>
  {
    return PersistentObject.init(strategy: UserDefaultsStrategy(key: key, userDefaults: userDefaults))
  }
  
  public class func file(filename filename: String) -> PersistentObject<ObjectType> {
    return PersistentObject.init(strategy: FileStrategy(filename: filename))
  }
  
  public class func ubiquituousKeyValueStore(key key: String) -> PersistentObject<ObjectType> {
    return PersistentObject.init(strategy: UbiquituousKeyValueStoreStrategy(key: key))
  }
}

public protocol PersistentObjectDelegate : class {
  func objectChangedExternally<ObjectType>(persistentObject: PersistentObject<ObjectType>)
}
