import Nimble
@testable import SwiftBSON
import XCTest

final class swift_bsonTests: XCTestCase {

    func testInt32() {
        var d = Document()
        //test insert
        d["a"] = Int32(1).bson
        expect(d["a"]!.int32Value).to(equal(1))
        d["b"] = Int32(2).bson
        expect(d["b"]!.int32Value).to(equal(2))

        //test delete
        d["b"] = nil 
        expect(d["b"]).to(beNil())

        //test overwrite
        d["a"] = Int32(3).bson
        expect(d["a"]!.int32Value).to(equal(3))

        //test default
        expect(d["x", default: Int32(100).bson].int32Value).to(equal(Int32(100)))
    }

    func testInt64() {
        var d = Document()
        //test insert
        d["a"] = 1
        expect(d["a"]!.int64Value).to(equal(1))
        d["b"] = 2
        expect(d["b"]!.int64Value).to(equal(2))

        //test delete
        d["b"] = nil 
        expect(d["b"]).to(beNil())

        //test overwrite
        d["a"] = 3
        expect(d["a"]!.int64Value).to(equal(3))

        //test default
        expect(d["x", default: 100]).to(equal(100))

    }

    func testString() {
        var d = Document()
        //test insert
        d["a"] = "test1"
        expect(d["a"]!.stringValue).to(equal("test1"))
        d["b"] = "test2"
        expect(d["b"]!.stringValue).to(equal("test2"))

        //test delete
        d["b"] = nil 
        expect(d["b"]).to(beNil())

        //test overwrite
        d["a"] = "test3"
        expect(d["a"]!.stringValue).to(equal("test3"))

        //test default
        expect(d["x", default: "default"]).to(equal("default"))
    }

    func testDocument() {
        var d = Document()
        //test insert
        d["a"] = ["b" : 1]
        expect(d["a"]!.documentValue).to(equal(["b" : 1]))
        d["c"] = ["d" : 2]
        expect(d["c"]!.documentValue).to(equal(["d" : 2]))

        //test delete
        d["c"] = nil 
        expect(d["c"]).to(beNil())

        //test overwrite
        d["a"] = ["e" : 3]
        expect(d["a"]!.documentValue).to(equal(["e" : 3]))

        //test default
        expect(d["x", default: ["y" : 4]]).to(equal(["y" : 4]))
    }

    static var allTests = [
        ("testInt32", testInt32),
        ("testInt64", testInt64),
        ("testString", testString),
        ("testDocument", testDocument)
    ]
}
