# PersistentObject

[![](https://travis-ci.org/mattcomi/PersistentObject.svg?branch=master)](https://travis-ci.org/mattcomi/PersistentObject)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![](https://img.shields.io/cocoapods/v/PersistentObject.svg?style=flat)](https://cocoapods.org/pods/PersistentObject)
[![Platform](https://img.shields.io/cocoapods/p/PersistentObject.svg?style=flat)](http://cocoadocs.org/docsets/PersistentObject)

Simple object persistence in Swift.

Include support for `NSUserDefaults`, `NSUbiquitousKeyValueStore` and the file system.

[API Documentation](http://cocoadocs.org/docsets/PersistentObject)

## Getting Started

To persist an object, initialize a `PersistentObject` with the desired repository. For example, to persist a `Vehicle` to a file:

```swift
let persistentVehicle = PersistentObject<Vehicle>(filename: "file.txt")
```

Or, to persist a `Person` to the `NSUserDefaults` database:

```swift
let persistentPerson = PersistentObject<Person>(userDefaultsKey: personKey)
```

If a `PersistentObject` exists in the repository, that is, if it has been persisted previously, it will be unarchived and initialized. To access the underlying object:

```swift
if let person = persistentPerson.object {
  print("Hi, my name is \(person.name)")
}
```

## Initialization

If a `PersistentObject` does not yet exist in the repository, you will need to initialize it yourself:

```swift
if persistentPerson.object == nil {
    persistentPerson.reset(Person(name: "Brian Doyle-Murray"))
}
```

## Saving and Synchronization

The underlying object is automatically archived to its repository when the app enters the background and when the `PersistentObject` is deinitialized. You may also trigger it manually:

```swift
persistentPerson.save()
```

You may also synchronize the repository:

```swift
persistentPerson.synchronize()
```

Manual synchronization is typically only necessary when:

1. The underlying repository is a `UbiquituousKeyValueStoreRepository`
2. You require fast-as-possible upload to iCloud after changing the object

## Repository

The follow repositories are supported currently:

- `FileRepository`: Persists to a file
- `UbiquituousKeyValueStoreRepository`: Persists to the `NSUbiquituousKeyValueStore`
- `UserDefaultsRepository`: Persists to the `NSUserDefaults` database

## External Changes

A `Repository` may support external changes. For example, when using the `UbiquituousKeyValueStoreRepository`, it is possible for the value to change in iCloud. If an external change occurs, the `PersistentObject`'s underlying object is replaced, invalidating any references. To be notified when this occurs, provide a delegate when initializing the `PersistentObject`:

```swift
let delegate = PersistentObjectDelegate<Person>()

delegate.objectChangedExternally = { (persistentObject) in
  // handle the external change
}

let p = PersistentObject<Person>(
  ubiquituousKeyValueStoreKey: "personKey",
  delegate: delegate)
```

## Custom Repository

To provide a custom repository, you may implement the `Repository` protocol:

```swift
public protocol Repository {
  associatedtype ObjectType
  var delegate: RepositoryDelegate<ObjectType> { get }
  func archiveObject(object: ObjectType?)
  func unarchiveObject() -> ObjectType
  func synchronize()
}
```

Then, to initialize a `PersistentObject` with that `Repository`:

```swift
let p = PersistentObject<Person>(repository: MyCustomRepository())
```
