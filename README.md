# PersistentObject

![](https://travis-ci.org/mattcomi/PersistentObject.svg?branch=master)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
![](https://img.shields.io/cocoapods/v/PersistentObject.svg?style=flat)
[![Platform](https://img.shields.io/cocoapods/p/PersistentObject.svg?style=flat)](http://cocoadocs.org/docsets/PersistentObject)

Simplifies object persistence in Swift.

Include support for `NSUserDefaults`, `NSUbiquitousKeyValueStore` and the file system.

[API Documentation](http://cocoadocs.org/docsets/PersistentObject)

## Usage

To persist an NSCoding-compliant object to the `NSUserDefaults` database, specify its key.

```swift
let persistentPerson = PersistentObject<Person>(key: "person")
```

If an object with the specified key has been persisted previously, it will be unarchived from `NSUserDefaults` and initialized. If not, you will need to initialize it yourself.

```swift
if persistentPerson.object == nil {
    persistentPerson.reset(Person(name: "Brian Doyle-Murray"))
}
```

The underlying object may be accessed with the `object` property.

```swift
persistentPerson.object?.age = 70
```

The object is automatically archived back to `NSUserDefaults` when the application enters the background and when the `PersistentObject` is deinitialized. It may also be triggered manually:

```swift
persistentPerson.save()
```

## Strategies

You may specify *how* an object is persisted by specifying its `Strategy`. In this example, the `Person` is persisted to a file named `file.data`.

```swift
let persistentPerson = PersistentObject<Person>(strategy: FileStrategy(filename: "file.data"))
```

This example persists the `Person` to the NSUbiquitousKeyValueStore.

```swift
let strategy = UbiquituousKeyValueStoreStrategy<Person>(key: "person")
strategy.delegate = self

let persistentPerson = PersistentObject<Person>(strategy: strategy)
```

Note `strategy.delegate = self`. Delegates of the `UbiquituousKeyValueStoreStrategy` are notified when the object changes externally.

## Custom Strategies

You may implement the `Strategy` protocol to provide alternative persistence strategies.
