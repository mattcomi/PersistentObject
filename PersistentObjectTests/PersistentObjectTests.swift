// Copyright © 2017 Matt Comi. All rights reserved.

import XCTest
import PersistentObject

class MyRepository: Repository {
  typealias ObjectType = Person

  var delegate = RepositoryDelegate<ObjectType>()

  var didArchive = false
  var didUnarchive = false
  var didSynchronize = false

  init() {}

  func archive(_ object: Person?) {
    self.didArchive = true
  }

  func unarchive() -> Person? {
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
    guard let name = aDecoder.decodeObject(forKey: "name") as? String else {
      return nil
    }

    self.name = name
    self.age = aDecoder.decodeInteger(forKey: "age")
  }

  func encode(with aCoder: NSCoder) {
    aCoder.encode(name, forKey: "name")
    aCoder.encode(age, forKey: "age")
  }

  override func isEqual(_ object: Any?) -> Bool {
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

func documentDirectory() -> URL {
  return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

class PersistentObjectTests: XCTestCase {
  let personKey = "person"
  let dateKey = "date"

  let filename = documentDirectory().appendingPathComponent("test.data").path

  override func setUp() {
    super.setUp()

    UserDefaults.standard.removeObject(forKey: personKey)
    UserDefaults.standard.removeObject(forKey: dateKey)

    UserDefaults.resetStandardUserDefaults()

    if FileManager.default.fileExists(atPath: filename) {
      try! FileManager.default.removeItem(atPath: filename)
    }
  }

  override func tearDown() {
    super.tearDown()
  }

  func testBasic() {
    let persistentPerson = PersistentObject<Person>(userDefaultsKey: personKey)

    // verify we have a fresh slate.
    XCTAssertNil(persistentPerson.object)

    persistentPerson.reset(object: Person(name: "Justin Theroux", age: 44))

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

    anotherPersistentPerson.reset(object: nil)

    // this should fail because anotherPerson hasn't been synchronized and despite being reset to nil, is still present
    // in NSUserDefaults.
    XCTAssertNotNil(PersistentObject<Person>(userDefaultsKey: personKey).object)

    anotherPersistentPerson.save()

    XCTAssertNil(PersistentObject<Person>(userDefaultsKey: personKey).object)
  }

  func testFile() {
    // The documentDirectory doesn't exist on travis-ci so create it.
    _ = try? FileManager.default.createDirectory(
      at: documentDirectory(),
      withIntermediateDirectories: true,
      attributes: nil)

    let person = PersistentObject<Person>(filename: filename)

    XCTAssertNil(person.object)

    person.reset(object: Person(name: "Liv Tyler", age: 38))

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

    persistentPerson!.reset(object: Person(name: "Carrie Coon", age: 35))

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

    myRepository.delegate.objectChangedExternally?(AnyRepository(myRepository), externalPerson)

    XCTAssertEqual(externalPerson, persistentPerson.object)

    XCTAssert(objectDidChangeExternally)
  }
}
