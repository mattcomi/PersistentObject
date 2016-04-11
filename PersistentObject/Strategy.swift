// Copyright © 2016 Matt Comi. All rights reserved.

/// Types adopting the `Strategy` protocol are capable of archiving and unarchiving an object to a persistent store.
public protocol Strategy {
  associatedtype ObjectType
  
  /// Archives an object.
  ///
  /// parameter object: The object to archive.
  func archiveObject(object: ObjectType?)
  
  /// Unarchives an object.
  ///
  /// returns: The unarchived object.
  func unarchiveObject() -> ObjectType?
  
  /// Performs any necessary synchronization.
  func synchronize()
}

class AnyStrategyBase<ObjectType> : Strategy {
  func archiveObject(object: ObjectType?) { }
  func unarchiveObject() -> ObjectType? { return nil }
  func synchronize() { }
}

/// A type-erased Strategy.
///
/// Forwards operations to an arbitrary underlying strategy having the same `ObjectType`, hiding the specifics of the
/// underlying `StrategyType`.
public class AnyStrategy<ObjectType> : AnyStrategyBase<ObjectType> {
  private let box: AnyStrategyBase<ObjectType>
  
  /// Initializes the `AnyStrategy` with the specified undelying strategy.
  ///
  /// - parameter strategy: The underlying strategy. That is, the strategy to which all operations are forwarded.
  init<StrategyType:Strategy where StrategyType.ObjectType == ObjectType>(strategy: StrategyType) {
    box = AnyStrategyBox(strategy)
  }
  
  /// Archives an object using the underlying strategy.
  ///
  /// - parameter object: The object to archive.
  override func archiveObject(object: ObjectType?) {
    box.archiveObject(object)
  }
  
  /// Unarchives an object using the underlying strategy.
  ///
  /// - returns: The unarchived object.
  override func unarchiveObject() -> ObjectType? {
    return box.unarchiveObject()
  }
  
  override func synchronize() {
     return box.synchronize()
  }
}

final class AnyStrategyBox<Base:Strategy> : AnyStrategyBase<Base.ObjectType> {
  var base: Base
  
  init(_ base: Base) { self.base = base }
  
  override func archiveObject(object: Base.ObjectType?) {
    base.archiveObject(object)
  }
  
  override func unarchiveObject() -> Base.ObjectType? {
    return base.unarchiveObject()
  }
  
  override func synchronize() {
    return base.synchronize()
  }
}
