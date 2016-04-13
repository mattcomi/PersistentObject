// Copyright © 2016 Matt Comi. All rights reserved.

/// Types adopting the `Strategy` protocol are capable of archiving and unarchiving an object to a persistent store.
public protocol Strategy {
  associatedtype ObjectType
 
  var delegate: StrategyDelegate<ObjectType> { get }

  /// Archives an object.
  ///
  /// - parameter object: The object to archive.
  func archiveObject(object: ObjectType?)
  
  /// Unarchives an object.
  ///
  /// - returns: The unarchived object.
  func unarchiveObject() -> ObjectType?
  
  /// Performs any necessary synchronization.
  func synchronize()
}

public final class StrategyDelegate<ObjectType> {
  public init() { }
  public var objectChangedExternally: ((strategy: AnyStrategy<ObjectType>, object: ObjectType?) -> Void)?
}

public class AnyStrategy<ObjectType> : Strategy {
  private let baseDelegate: () -> StrategyDelegate<ObjectType>
  private let baseArchiveObject: (object: ObjectType?) -> Void
  private let baseUnarchiveObject: () -> ObjectType?
  private let baseSynchronize: () -> Void

  public init<BaseStrategy: Strategy where ObjectType == BaseStrategy.ObjectType>(strategy: BaseStrategy) {
    baseDelegate = { return strategy.delegate }
    baseArchiveObject = strategy.archiveObject
    baseUnarchiveObject = strategy.unarchiveObject
    baseSynchronize = strategy.synchronize
  }
  
  public var delegate: StrategyDelegate<ObjectType> {
    return baseDelegate()
  }
  
  public func archiveObject(object: ObjectType?) { baseArchiveObject(object: object) }
  public func unarchiveObject() -> ObjectType? { return baseUnarchiveObject() }
  public func synchronize() { baseSynchronize() }
}