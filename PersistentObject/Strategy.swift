// Copyright © 2016 Matt Comi. All rights reserved.

/// Types adopting the `Strategy` protocol are capable of archiving and unarchiving an object to a persistent store.
public protocol Strategy {
  associatedtype ObjectType
 
  /// The delegate to notify when the object changes externally.
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

/// A `Strategy` delegate.
public final class StrategyDelegate<ObjectType> {
  /// Initializes the `StrategyDelegate`.
  public init() { }
  
  /// A closure that is called when the object changed externally.
  ///
  /// - parameter strategy: The type-erased strategy.
  /// - parameter object:   The object.
  public var objectChangedExternally: ((strategy: AnyStrategy<ObjectType>, object: ObjectType?) -> Void)?
}

/// A type erased `Strategy`.
public class AnyStrategy<ObjectType> : Strategy {
  private let baseDelegate: () -> StrategyDelegate<ObjectType>
  private let baseArchiveObject: (object: ObjectType?) -> Void
  private let baseUnarchiveObject: () -> ObjectType?
  private let baseSynchronize: () -> Void

  /// Initializes the `AnyStrategy` with the specified underlying `Strategy`.
  ///
  /// - parameter strategy: The underlying `Strategy`.
  public init<BaseStrategy: Strategy where ObjectType == BaseStrategy.ObjectType>(strategy: BaseStrategy) {
    baseDelegate = { strategy.delegate }
    baseArchiveObject = strategy.archiveObject
    baseUnarchiveObject = strategy.unarchiveObject
    baseSynchronize = strategy.synchronize
  }
  
  /// The delegate to notify when the object changes externally.
  public var delegate: StrategyDelegate<ObjectType> { return baseDelegate() }
  
  /// Archives an object.
  ///
  /// - parameter object: The object to archive.
  public func archiveObject(object: ObjectType?) { baseArchiveObject(object: object) }
  
  /// Unarchives an object.
  ///
  /// - returns: The unarchived object.
  public func unarchiveObject() -> ObjectType? { return baseUnarchiveObject() }
  
  /// Performs any necessary synchronization.
  public func synchronize() { baseSynchronize() }
}