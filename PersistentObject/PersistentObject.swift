// Copyright © 2016 Matt Comi. All rights reserved.

#if os(iOS)
  import UIKit
#elseif os(OSX)
  import AppKit
#endif

/// A persistent object.
public class PersistentObject<ObjectType> {
  private let strategy: AnyStrategy<ObjectType>
  
  /// The object being persisted.
  public private(set) var object: ObjectType? = nil
  
  /// The delegate to notify when the object changes externally. Note that depending on the underlying strategy, this 
  /// may not occur. Default is `PersistentObjectDelegate()`.
  public let delegate: PersistentObjectDelegate<ObjectType>? = nil
  
  /// Initializes the `PersistentObject` with the specified strategy.
  ///
  /// - parameter strategy: The `Strategy`.
  /// - parameter delegate: The `PersistentObjectDelegate` to notify when the object changes externally.
  public init<StrategyType:Strategy where ObjectType == StrategyType.ObjectType>(
    strategy: StrategyType,
    delegate: PersistentObjectDelegate<ObjectType>? = PersistentObjectDelegate())
  {
    self.strategy = AnyStrategy(strategy: strategy)
    
    self.strategy.delegate.objectChangedExternally = { [weak self] strategy, object in
      guard self != nil else {
        return
      }
      
      self!.reset(object)
      
      delegate?.objectChangedExternally?(persistentObject: self!)
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
  
  @objc private func applicationDidEnterBackgroundOrResignActive(notification: NSNotification) {
    save()
  }
}

public extension PersistentObject where ObjectType:NSCoding {
  /// Creates a `PersistentObject` that persists to the `NSUserDefaults` database.
  ///
  /// - parameter key:          The key to associate with this object.
  /// - parameter userDefaults: The `NSUserDefaults` database. Defaults to `NSUserDefaults.standardUserDefaults()`.
  /// - returns: A `PersistentObject` that persists to the `NSUserDefaults` database.
  public class func userDefaults(
    key key: String,
    userDefaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()) -> PersistentObject<ObjectType>
  {
    return PersistentObject.init(strategy: UserDefaultsStrategy(key: key, userDefaults: userDefaults))
  }
  
  /// Creates a `PersistentObject` that persists to a file.
  ///
  /// - parameter filename: The filename.
  public class func file(filename filename: String) -> PersistentObject<ObjectType> {
    return PersistentObject.init(strategy: FileStrategy(filename: filename))
  }
  
  /// Creates a `PersistentObject` that persists to the `NSUbiquituousKeyValueStore`.
  ///
  /// - parameter key: The key to associate with this object.
  public class func ubiquituousKeyValueStore(
    key key: String,
    delegate: PersistentObjectDelegate<ObjectType>? = PersistentObjectDelegate()) -> PersistentObject<ObjectType> {
    return PersistentObject.init(strategy: UbiquituousKeyValueStoreStrategy(key: key), delegate: delegate)
  }
}

/// A `PersistentObject` delegate.
public final class PersistentObjectDelegate<ObjectType> {
  /// Initializes the `PersistentObjectDelegate`.
  public init() { }
  
  /// A closure that is called when the object changed externally.
  /// 
  /// - parameter persistentObject: The persistent object whose object changed externally.
  public var objectChangedExternally: ((persistentObject: PersistentObject<ObjectType>) -> Void)?
}
