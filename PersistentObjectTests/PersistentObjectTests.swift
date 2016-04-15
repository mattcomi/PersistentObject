// Copyright © 2016 Matt Comi. All rights reserved.

import XCTest
import PersistentObject

class MyRepository: Repository {
  typealias ObjectType = Person

  var delegate = RepositoryDelegate<ObjectType>()

  var didArchive = false
  var didUnarchive = false
  var didSynchronize = false

  init() {}

  func archiveObject(object: Person?) {
    self.didArchive = true
  }

  func unarchiveObject() -> Person? {
    self.didUnarchive = true
    return nil
  }

  func synchronize() {
    self.didSynchronize = true
  }
}

class Person: NSObject, NSCoding {
  var name: String
  var age: Int

  init(name: String, age: Int) {
    self.name = name
    self.age = age
  }

  required init?(coder aDecoder: NSCoder) {
    guard let name = aDecoder.decodeObjectForKey("name") as? String else {
      return nil
    }

    self.name = name
    self.age = aDecoder.decodeIntegerForKey("age")
  }

  func encodeWithCoder(aCoder: NSCoder) {
    aCoder.encodeObject(name, forKey: "name")
    aCoder.encodeInteger(age, forKey: "age")
  }

  override func isEqual(object: AnyObject?) -> Bool {
    guard let rhs = object as? Person else {
      return false
    }

    return self == rhs
  }

  override var description: String {
    return "(name: \(name), age: \(age))"
  }
}

func == (lhs: Person, rhs: Person) -> Bool {
  return lhs.name == rhs.name && lhs.age == rhs.age
}

func documentDirectory() -> NSURL {
  return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
}

class PersistentObjectTests: XCTestCase {
  let personKey = "person"
  let dateKey = "date"

  let filename = documentDirectory().URLByAppendingPathComponent("test.data").path!

  override func setUp() {
    super.setUp()

    NSUserDefaults.standardUserDefaults().removeObjectForKey(personKey)
    NSUserDefaults.standardUserDefaults().removeObjectForKey(dateKey)

    NSUserDefaults.resetStandardUserDefaults()

    if NSFileManager.defaultManager().fileExistsAtPath(filename) {
      try! NSFileManager.defaultManager().removeItemAtPath(filename)
    }
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testBasic() {
    let persistentPerson = PersistentObject<Person>(userDefaultsKey: personKey)

    // verify we have a fresh slate.
    XCTAssertNil(persistentPerson.object)

    persistentPerson.reset(Person(name: "Justin Theroux", age: 44))

    XCTAssertNotNil(persistentPerson.object)

    guard persistentPerson.object != nil else {
      return
    }

    // initializing another PersistentObject using the same key should fail because the PersistentObject hasn't been
    // synchronized (i.e. serialized to NSUserDefaults) yet.
    XCTAssertNil(PersistentObject<Person>(userDefaultsKey: personKey).object)

    // serialize the Person to the NSUserDefaults database so that it can be deserialized into a new PersistentObject.
    persistentPerson.save()

    let anotherPersistentPerson = PersistentObject<Person>(userDefaultsKey: personKey)

    XCTAssertNotNil(anotherPersistentPerson.object)

    guard anotherPersistentPerson.object != nil else {
      return
    }

    // the Person objects should be equal...
    XCTAssertEqual(persistentPerson.object, anotherPersistentPerson.object)

    // ...but their references should not be.
    XCTAssert(persistentPerson.object !== anotherPersistentPerson.object)

    anotherPersistentPerson.reset(nil)

    // this should fail because anotherPerson hasn't been synchronized and despite being reset to nil, is still present
    // in NSUserDefaults.
    XCTAssertNotNil(PersistentObject<Person>(userDefaultsKey: personKey).object)

    anotherPersistentPerson.save()

    XCTAssertNil(PersistentObject<Person>(userDefaultsKey: personKey).object)
  }

  func testFile() {
    // The documentDirectory doesn't exist on travis-ci so create it.
    _ = try? NSFileManager.defaultManager().createDirectoryAtURL(
        documentDirectory(),
        withIntermediateDirectories: true,
        attributes: nil)

    let person = PersistentObject<Person>(filename: filename)

    XCTAssertNil(person.object)

    person.reset(Person(name: "Liv Tyler", age: 38))

    XCTAssertNotNil(person.object)

    person.save()

    // Initialize it from a different but identical FileRepository.
    let anotherPerson = PersistentObject<Person>(filename: filename)

    XCTAssertEqual(person.object, anotherPerson.object)
  }

  func testSynchronizeOnDeinit() {
    var persistentPerson: PersistentObject<Person>? = PersistentObject<Person>(userDefaultsKey: personKey)

    // verify we have a clean slate.
    XCTAssertNil(persistentPerson!.object)

    guard persistentPerson!.object == nil else {
      return
    }

    persistentPerson!.reset(Person(name: "Carrie Coon", age: 35))

    XCTAssertNotNil(persistentPerson!.object)

    guard persistentPerson!.object != nil else {
      return
    }

    // initializing another PersistentObject using the same key should fail because the PersistentObject hasn't been
    // synchronized (i.e. serialized to NSUserDefaults) yet.
    XCTAssertNil(PersistentObject<Person>(userDefaultsKey: personKey).object)

    // save should occur on deinit.
    persistentPerson = nil

    let anotherPersistentPerson = PersistentObject<Person>(userDefaultsKey: personKey)

    XCTAssertNotNil(anotherPersistentPerson.object)

    guard anotherPersistentPerson.object != nil else {
      return
    }

    XCTAssertEqual(anotherPersistentPerson.object!.name, "Carrie Coon")
    XCTAssertEqual(anotherPersistentPerson.object!.age, 35)
  }

  func testRepository() {
    let myRepository = MyRepository()

    let delegate = PersistentObjectDelegate<Person>()

    var objectDidChangeExternally = false

    delegate.objectChangedExternally = { (persistentObject) in
      objectDidChangeExternally = true

      XCTAssert(persistentObject.object?.name == "Patti Levin")
    }

    let persistentPerson = PersistentObject<Person>(repository: myRepository, delegate: delegate)

    XCTAssert(myRepository.didUnarchive)
    XCTAssert(!myRepository.didArchive)
    XCTAssert(!myRepository.didSynchronize)

    persistentPerson.save()

    XCTAssert(myRepository.didArchive)
    XCTAssert(!myRepository.didSynchronize)

    persistentPerson.synchronize()

    XCTAssert(myRepository.didSynchronize)

    let externalPerson = Person(name: "Patti Levin", age: 60)

    myRepository.delegate.objectChangedExternally?(repository: AnyRepository(myRepository), object: externalPerson)

    XCTAssertEqual(externalPerson, persistentPerson.object)

    XCTAssert(objectDidChangeExternally)
  }
}
