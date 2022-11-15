import XCTest
import AppUniqueIdentifier

final class AppUniqueIdentifierTests: XCTestCase {
    
    override func setUp() {
        AppUniqueIdentifier.__deleteAllRegisteredIds()
    }
    
    
    func testUniqueCreation() throws {
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
}



struct Person: Identifiable, Codable {
    var id: AppUniqueIdentifier = .next()
    let name: String
}
