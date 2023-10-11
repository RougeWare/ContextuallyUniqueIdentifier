import XCTest
import AppUniqueIdentifier



final class AppUniqueIdentifierTests: XCTestCase {
    
    override func setUp() {
        AppUniqueIdentifier.__deleteAllRegisteredIds()
    }
    
    
    func testUniqueCreation() {
        XCTAssertEqual(AppUniqueIdentifier.next().description, "0")
        XCTAssertEqual(AppUniqueIdentifier.next().description, "1")
        XCTAssertEqual(AppUniqueIdentifier.next().description, "2")
    }
    
    
    func testComparison() {
        let id1 = AppUniqueIdentifier.next()
        
        XCTAssertEqual(id1, id1)
        
        let id2 = AppUniqueIdentifier.next()
        
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
        let firstId = AppUniqueIdentifier.next()
        
        XCTAssertEqual(firstId.description, "0")
        
        let decoder = JSONDecoder()
        let dax = try decoder.decode(Person.self, from: """
        {
          "id" : 0,
          "name" : "Dax"
        }
        """.data(using: .utf8)!)
        
        let anotherId = AppUniqueIdentifier.next()
        
        XCTAssertEqual(dax.id.description, "0")
        XCTAssertEqual(dax.name, "Dax")
        
        XCTAssertEqual(anotherId.description, "1")
    }
    
    
    func testFromString() {
        XCTAssertEqual(AppUniqueIdentifier("42")?.description, "42")
    }
    
    
    func testRecycle() {
        let id0 = AppUniqueIdentifier.next()
        XCTAssertEqual(id0.description, "0")
        
        let id1 = AppUniqueIdentifier.next()
        XCTAssertEqual(id1.description, "1")
        
        let id2 = AppUniqueIdentifier.next()
        XCTAssertEqual(id2.description, "2")
        
        AppUniqueIdentifier.recycle(id: id1)
        
        XCTAssertEqual(AppUniqueIdentifier.next().description, "1")
        XCTAssertEqual(AppUniqueIdentifier.next().description, "3")
    }
    
    
    
    func testRegions() {
        XCTAssertEqual(AppUniqueIdentifier.next().region, .generalUse)
        XCTAssertEqual(AppUniqueIdentifier.next().region, .generalUse)
        XCTAssertEqual(AppUniqueIdentifier.next().region, .generalUse)
        
        XCTAssertTrue(AppUniqueIdentifier.Region.generalUse.contains(.next()))
        XCTAssertTrue(AppUniqueIdentifier.Region.generalUse.contains(.next()))
        XCTAssertTrue(AppUniqueIdentifier.Region.generalUse.contains(.next()))
        
        XCTAssertEqual(AppUniqueIdentifier.privateUse(offset: 0).region, .privateUse)
        XCTAssertEqual(AppUniqueIdentifier.privateUse(offset: 1).region, .privateUse)
        XCTAssertEqual(AppUniqueIdentifier.privateUse(offset: 3).region, .privateUse)
        
        XCTAssertTrue(AppUniqueIdentifier.Region.privateUse.contains(.privateUse(offset: 4)))
        XCTAssertTrue(AppUniqueIdentifier.Region.privateUse.contains(.privateUse(offset: 5)))
        XCTAssertTrue(AppUniqueIdentifier.Region.privateUse.contains(.privateUse(offset: 6)))
        
        XCTAssertEqual(AppUniqueIdentifier.error.region, .error)
        XCTAssertTrue(AppUniqueIdentifier.Region.error.contains(.error))
        XCTAssertTrue(AppUniqueIdentifier.error.isError)
    }
}



struct Person: Identifiable, Codable {
    var id: AppUniqueIdentifier
    let name: String
    
    init(id: AppUniqueIdentifier = .next(), name: String) {
        self.id = id
        self.name = name
    }
}
