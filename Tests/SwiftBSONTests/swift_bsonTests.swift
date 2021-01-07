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

    func testKeyValueRetrieval() {
        var d = Document()
        d["a"] = 1
        d["b"] = "hello"
        d["c"] = ["d" : 2]
        expect(Set(d.keys)).to(equal(Set(["a", "b", "c"])))
        expect(Set(d.values)).to(equal(Set([1, "hello", ["d" : 2]])))
    }

    func testRawBSON() throws {
        var d = Document()
        d["a"] = 10
        let fromRawBSON = Document(fromBSON: d.rawBSON)
        expect(d).to(equal(fromRawBSON))
    }

    func testEquatable() {
        expect(["hi": ["a" : 2], "hello": "hi", "cat": 2] as Document)
            .to(equal(["hi": ["a" : 2], "hello": "hi", "cat": 2] as Document))
    }

    func testValueBehavior() {
        let doc1: Document = ["a": 1]
        var doc2 = doc1
        doc2["b"] = 2
        expect(doc2["b"]).to(equal(2))
        expect(doc1["b"]).to(beNil())
        expect(doc1).toNot(equal(doc2))
    }

    func testMultibyteCharacterStrings() throws {
        let str = String(repeating: "🇧🇩", count: 10)
        var doc: Document = ["first": .string(str)]
        expect(doc["first"]).to(equal(.string(str)))
        let doc1: Document = [str: "second"]
        expect(doc1[str]).to(equal("second"))
    }

    static var allTests = [
        ("testInt32", testInt32),
        ("testInt64", testInt64),
        ("testString", testString),
        ("testDocument", testDocument),
        ("testKeyValueRetrieval", testKeyValueRetrieval),
        ("testRawBSON", testRawBSON),
        ("testEquatable", testEquatable)
    ]
}
