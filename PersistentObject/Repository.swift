// Copyright © 2017 Matt Comi. All rights reserved.

/// Types adopting the `Repository` protocol are capable of archiving and unarchiving an object to a repository.
public protocol Repository {
  associatedtype ObjectType

  /// The delegate to notify when the object changes externally.
  var delegate: RepositoryDelegate<ObjectType> { get }

  /// Archives an object.
  /// - parameter object: The object to archive.
  func archive(_ object: ObjectType?)

  /// Unarchives an object.
  /// - returns: The unarchived object.
  func unarchive() -> ObjectType?

  /// Performs any necessary synchronization, e.g. write modifications to disk.
  func synchronize()
}

/// A `Repository` delegate.
public final class RepositoryDelegate<ObjectType> {
  /// Initializes the `RepositoryDelegate`.
  public init() { }

  /// A closure that is called when the object changed externally.
  /// - parameter repository: The type-erased repository.
  /// - parameter object: The object.
  public var objectChangedExternally: ((AnyRepository<ObjectType>, ObjectType?) -> Void)?
}

/// A type erased `Repository`.
public class AnyRepository<ObjectType> : Repository {
  private let baseDelegate: () -> RepositoryDelegate<ObjectType>
  private let baseArchive: (ObjectType?) -> Void
  private let baseUnarchive: () -> ObjectType?
  private let baseSynchronize: () -> Void

  /// Initializes the `AnyRepository` with the specified underlying `Repository`.
  /// - parameter repository: The underlying `Repository`.
  public init<RepositoryType: Repository>(_ repository: RepositoryType) where ObjectType == RepositoryType.ObjectType {
    baseDelegate = { repository.delegate }
    baseArchive = repository.archive
    baseUnarchive = repository.unarchive
    baseSynchronize = repository.synchronize
  }

  /// The delegate to notify when the object changes externally.
  public var delegate: RepositoryDelegate<ObjectType> { return baseDelegate() }

  /// Archives an object.
  /// - parameter object: The object to archive.
  public func archive(_ object: ObjectType?) { baseArchive(object) }

  /// Unarchives an object.
  /// - returns: The unarchived object.
  public func unarchive() -> ObjectType? { return baseUnarchive() }

  /// Performs any necessary synchronization.
  public func synchronize() { baseSynchronize() }
}
