// Copyright © 2016 Matt Comi. All rights reserved.

import XCTest
@testable import PersistentObject

class Person : NSObject, NSCoding {
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

func ==(lhs: Person, rhs: Person) -> Bool {
  return lhs.name == rhs.name && lhs.age == rhs.age
}

class PersistentObjectTests: XCTestCase {
  let personKey = "person"
  let dateKey = "date"
  
  override func setUp() {
    super.setUp()
    
    NSUserDefaults.standardUserDefaults().removeObjectForKey(personKey)
    NSUserDefaults.standardUserDefaults().removeObjectForKey(dateKey)
    
    NSUserDefaults.resetStandardUserDefaults()
  }
  
  override func tearDown() {
    print("tear down")
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testBasic() {
    let persistentPerson = PersistentObject<Person>(key: personKey)
    
    // verify we have a fresh slate.
    XCTAssertNil(persistentPerson.object)
    
    persistentPerson.reset(Person(name: "Amanda", age: 29))
    
    XCTAssertNotNil(persistentPerson.object)
    
    guard persistentPerson.object != nil else {
      return
    }
    
    // initializing another PersistentObject using the same key should fail because the PersistentObject hasn't been
    // synchronized (i.e. serialized to NSUserDefaults) yet.
    XCTAssertNil(PersistentObject<Person>(key: personKey).object)
    
    // serialize the Person to the NSUserDefaults database so that it can be deserialized into a new PersistentObject.
    persistentPerson.synchronize()
    
    let anotherPersistentPerson = PersistentObject<Person>(key: personKey)
    
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
    XCTAssertNotNil(PersistentObject<Person>(key: personKey).object)
    
    anotherPersistentPerson.synchronize()
    
    XCTAssertNil(PersistentObject<Person>(key: personKey).object)
  }
  
  func testDate() {
    let date = NSDate()
    
    let persistentDate = PersistentObject<NSDate>(key: dateKey)
    
    // verify we have a fresh slate.
    XCTAssertNil(PersistentObject<NSDate>(key: dateKey).object)
    
    persistentDate.reset(date)
    
    persistentDate.synchronize()
    
    let anotherPersistentDate = PersistentObject<NSDate>(key: dateKey)
    
    XCTAssertNotNil(anotherPersistentDate.object)
    
    XCTAssertEqual(anotherPersistentDate.object, date)
  }
  
  func testSynchronizeOnDeinit() {
    var persistentPerson: PersistentObject<Person>? = PersistentObject<Person>(key: personKey)
    
    // verify we have a clean slate.
    XCTAssertNil(persistentPerson!.object)
    
    guard persistentPerson!.object == nil else {
      return
    }
    
    persistentPerson!.reset(Person(name: "Andy", age: 9))
    
    XCTAssertNotNil(persistentPerson!.object)
    
    guard persistentPerson!.object != nil else {
      return
    }
    
    // initializing another PersistentObject using the same key should fail because the PersistentObject hasn't been
    // synchronized (i.e. serialized to NSUserDefaults) yet.
    XCTAssertNil(PersistentObject<Person>(key: personKey).object)
    
    // synchronization should occur on deinit.
    persistentPerson = nil
    
    let anotherPersistentPerson = PersistentObject<Person>(key: personKey)
    
    XCTAssertNotNil(anotherPersistentPerson.object)
    
    guard anotherPersistentPerson.object != nil else {
      return
    }
    
    XCTAssertEqual(anotherPersistentPerson.object!.name, "Andy")
    XCTAssertEqual(anotherPersistentPerson.object!.age, 9)
  }
}
