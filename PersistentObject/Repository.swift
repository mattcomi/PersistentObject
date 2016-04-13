// Copyright © 2016 Matt Comi. All rights reserved.

/// Types adopting the `Repository` protocol are capable of archiving and unarchiving an object to a repository.
public protocol Repository {
  associatedtype ObjectType
 
  /// The delegate to notify when the object changes externally.
  var delegate: RepositoryDelegate<ObjectType> { get }

  /// Archives an object.
  ///
  /// - parameter object: The object to archive.
  func archiveObject(object: ObjectType?)
  
  /// Unarchives an object.
  ///
  /// - returns: The unarchived object.
  func unarchiveObject() -> ObjectType?
  
  /// Performs any necessary synchronization, e.g. write modifications to disk.
  func synchronize()
}

/// A `Repository` delegate.
public final class RepositoryDelegate<ObjectType> {
  /// Initializes the `RepositoryDelegate`.
  public init() { }
  
  /// A closure that is called when the object changed externally.
  ///
  /// - parameter repository: The type-erased repository.
  /// - parameter object:     The object.
  public var objectChangedExternally: ((repository: AnyRepository<ObjectType>, object: ObjectType?) -> Void)?
}

/// A type erased `Repository`.
public class AnyRepository<ObjectType> : Repository {
  private let baseDelegate: () -> RepositoryDelegate<ObjectType>
  private let baseArchiveObject: (object: ObjectType?) -> Void
  private let baseUnarchiveObject: () -> ObjectType?
  private let baseSynchronize: () -> Void

  /// Initializes the `AnyRepository` with the specified underlying `Repository`.
  ///
  /// - parameter strategy: The underlying `Repository`.
  public init<RepositoryType: Repository where ObjectType == RepositoryType.ObjectType>(_ repository: RepositoryType) {
    baseDelegate = { repository.delegate }
    baseArchiveObject = repository.archiveObject
    baseUnarchiveObject = repository.unarchiveObject
    baseSynchronize = repository.synchronize
  }
  
  /// The delegate to notify when the object changes externally.
  public var delegate: RepositoryDelegate<ObjectType> { return baseDelegate() }
  
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