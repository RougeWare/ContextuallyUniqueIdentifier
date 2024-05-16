import XCTest
import COID



final class ContextuallyUniqueIdentifierTests: XCTestCase {
    
    override func setUp() {
        COID.__deleteAllRegisteredIds()
    }
    
    
    func testUniqueCreation() {
        XCTAssertEqual(COID.next().description, "0")
        XCTAssertEqual(COID.next().description, "1")
        XCTAssertEqual(COID.next().description, "2")
    }
    
    
    func testComparison() {
        let id1 = COID.next()
        
        XCTAssertEqual(id1, id1)
        
        let id2 = COID.next()
        
        XCTAssertFalse(id1 == id2)
        XCTAssertTrue(id1 != id2)
        XCTAssertTrue(id1 < id2)
        XCTAssertTrue(id2 > id1)
    }
    
    
    func testEncode() throws {
        let dax = Person(name: "Dax")
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let daxData = try encoder.encode(dax)
        let daxString = String(data: daxData, encoding: .utf8)
        
        XCTAssertEqual(daxString, """
        {
          "id" : 0,
          "name" : "Dax"
        }
        """)
    }
    
    
    func testDecode() throws {
        let firstId = COID.next()
        
        XCTAssertEqual(firstId.description, "0")
        
        let decoder = JSONDecoder()
        let dax = try decoder.decode(Person.self, from: """
        {
          "id" : 0,
          "name" : "Dax"
        }
        """.data(using: .utf8)!)
        
        let anotherId = COID.next()
        
        XCTAssertEqual(dax.id.description, "0")
        XCTAssertEqual(dax.name, "Dax")
        
        XCTAssertEqual(anotherId.description, "1")
    }
    
    
    func testFromString() {
        XCTAssertEqual(COID("42")?.description, "42")
        XCTAssertEqual(COID("invalid lol")?.description, nil)
    }
    
    
    func testRecycle() {
        let id0 = COID.next()
        XCTAssertEqual(id0.description, "0")
        
        let id1 = COID.next()
        XCTAssertEqual(id1.description, "1")
        
        let id2 = COID.next()
        XCTAssertEqual(id2.description, "2")
        
        COID.recycle(id: id1)
        
        XCTAssertEqual(COID.next().description, "1")
        XCTAssertEqual(COID.next().description, "3")
    }
    
    
    
    func testRegions() {
        XCTAssertEqual(COID.next().region, .generalUse)
        XCTAssertEqual(COID.next().region, .generalUse)
        XCTAssertEqual(COID.next().region, .generalUse)
        
        XCTAssertTrue(COID.Region.generalUse.contains(.next()))
        XCTAssertTrue(COID.Region.generalUse.contains(.next()))
        XCTAssertTrue(COID.Region.generalUse.contains(.next()))
        
        XCTAssertEqual(COID.privateUse(offset: 0).region, .privateUse)
        XCTAssertEqual(COID.privateUse(offset: 1).region, .privateUse)
        XCTAssertEqual(COID.privateUse(offset: 3).region, .privateUse)
        
        XCTAssertTrue(COID.Region.privateUse.contains(.privateUse(offset: 4)))
        XCTAssertTrue(COID.Region.privateUse.contains(.privateUse(offset: 5)))
        XCTAssertTrue(COID.Region.privateUse.contains(.privateUse(offset: 6)))
        
        XCTAssertEqual(COID.error.region, .error)
        XCTAssertTrue(COID.Region.error.contains(.error))
        XCTAssertTrue(COID.error.isError)
    }
}



struct Person: Identifiable, Codable {
    var id: COID
    let name: String
    
    init(id: COID = .next(), name: String) {
        self.id = id
        self.name = name
    }
}
