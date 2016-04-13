# PersistentObject

![](https://travis-ci.org/mattcomi/PersistentObject.svg?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![](https://img.shields.io/cocoapods/v/PersistentObject.svg?style=flat)
[![Platform](https://img.shields.io/cocoapods/p/PersistentObject.svg?style=flat)](http://cocoadocs.org/docsets/PersistentObject)

Simple object persistence in Swift.

Include support for `NSUserDefaults`, `NSUbiquitousKeyValueStore` and the file system.

[API Documentation](http://cocoadocs.org/docsets/PersistentObject)

## Getting Started

To persist an object, initialize a `PersistentObject` with the desired strategy. To persist a `Person` to the `NSUserDefaults` database:

```swift
let persistentPerson = PersistentObject<Person>.userDefaults(key: personKey)
```

If a `Person` with the specified key had been persisted previously, it will be unarchived from `NSUserDefaults` and initialized. If not, you will need to initialize it yourself:

```swift
if persistentPerson.object == nil {
    persistentPerson.reset(Person(name: "Brian Doyle-Murray"))
}
```

The underlying object may now be accessed with the `object` property.

```swift
persistentPerson.object?.age = 70
```

The object is automatically archived back to `NSUserDefaults` when the application enters the background and when the `PersistentObject` is deinitialized. It may also be triggered manually:

```swift
persistentPerson.save()
```

## Strategies

The follow strategies are supported currently:

- `FileStrategy`: Persists to the file system.
- `UbiquituousKeyValueStoreStrategy`: Persists to the `NSUbiquituousKeyValueStore`.
- `UserDefaultsStrategy`: Persists to the `NSUserDefaults` database.

## External Changes

A `Strategy` may support external changes. For example, when using the `UbiquituousKeyValueStoreStrategy`, it is possible for the value to change in iCloud. If an external change occurs, the `PersistentObject`'s underlying object is replaced. To be notified when this occurs, provide a delegate when initializing the `PersistentObject`:

```swift
let delegate = PersistentObjectDelegate<Person>()

delegate.objectChangedExternally = { (persistentObject) in
  // handle the external change
}

let p = PersistentObject<Person>.ubiquituousKeyValueStore(
  key: "personKey",
  delegate: delegate)
```

## Custom Strategies

To provide a custom persistence strategy, you may implement the `Strategy` protocol:

```swift
public protocol Strategy {
  associatedtype ObjectType
  var delegate: StrategyDelegate<ObjectType> { get }
  func archiveObject(object: ObjectType?)
  func unarchiveObject() -> ObjectType
  func synchronize()
}
```

Then, to initialize a `PersistentObject` with that `Strategy`:

```swift
let p = PersistentObject<Person>(strategy: myCustomStrategy)
```
