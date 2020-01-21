import NIO
import Foundation

public struct Document {
    internal var data: ByteBuffer
    internal var keySet: Set<String>
}

extension Document {
    public typealias KeyValuePair = (key: String, value: BSON)

    public init() {
        self.data = ByteBufferAllocator().buffer(capacity: 4)
        self.data.writeInteger(Int32(4))
        self.keySet = Set<String>()
    }

    internal init(keyValuePairs: [(String, BSON)]) {
        // make sure all keys are unique
        guard Set(keyValuePairs.map { $0.0 }).count == keyValuePairs.count else {
            fatalError("Dictionary literal \(keyValuePairs) contains duplicate keys")
        }
        var d = Document()
        for (key, value) in keyValuePairs {
            d[key] = value
        }
        self = d
    }

    // public init(fromJSON json: String) throws {
    //     // `String`s are Unicode under the hood so force unwrap always succeeds.
    //     // see https://www.objc.io/blog/2018/02/13/string-to-data-and-back/
    //     try self.init(fromJSON: json.data(using: .utf8)!) // swiftlint:disable:this force_unwrapping
    // }

    public init(fromBSON data: Data) {
        self.data = ByteBufferAllocator().buffer(capacity: data.count)
        self.data.writeBytes([UInt8](data))
        self.keySet = Set<String>()
        self.forEach({ self.keySet.insert($0.0) })

    }

    internal init(fromBSON data: ByteBuffer) {
        self.data = data
        self.keySet = Set<String>()
        self.forEach({ self.keySet.insert($0.0) })
    }


    public func filter(_ isIncluded: (KeyValuePair) throws -> Bool) rethrows -> Document {
        var output = Document()
        for el in self where try isIncluded(el) {
            output[el.0] = el.1
        }
        return output
    }

    public subscript(key: String) -> BSON? {
        get {
            if (!keySet.contains(key)) {
                return nil
            }
            return first { k, _ in k == key }.map { _, v in v }
        }
        set(newValue) {
            guard let value = newValue else {
                self = self.filter { $0.key != key}
                keySet.remove(key)
                return
            }
            if keySet.contains(key) {
                self = self.filter { $0.key != key}
            }
            value.bsonValue.encode(key: key, data: &self.data)
            self.data.writeBytes([0])
            self.data.moveWriterIndex(to: self.data.writerIndex - 1)
            keySet.insert(key)
        }
    }

    public subscript(key: String, default defaultValue: @autoclosure () -> BSON) -> BSON {
        return self[key] ?? defaultValue()
    }

    @available(swift 4.2)
    public subscript(dynamicMember member: String) -> BSON? {
        get {
            return self[member]
        }
        set(newValue) {
            self[member] = newValue
        }
    }

    public func hasKey(_ key: String) -> Bool {
        return keySet.contains(key)
    }

    public var keys: [String] {
        return self.keySet.map { $0 }
    }

    public var count: Int {
        return keys.count
    }

    public var rawBSON: Data { 
        return Data(self.data.getBytes(at: 0, length: self.data.writerIndex)!)
    }

    public func printBytes() {
        print(self.data.getBytes(at: 0, length: self.data.writerIndex)!.hex + "00")
    }
}

extension Document: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral keyValuePairs: (String, BSON)...) {
        self.init(keyValuePairs: keyValuePairs)
    }
}

extension Document: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.data)
        hasher.combine(self.keySet)
    }
}

extension Document: BSONValue {
    internal static var bsonType: BSONType { return .document }

    internal var bson: BSON { return .document(self) }

    func encode(key: String, data: inout ByteBuffer) {
        data.writeBytes([BSONType.document.rawValue])
        data.writeBytes([UInt8](key.utf8))
        data.writeBytes([0])
        guard let docVal = self.bson.documentValue else {
            return
        }
        guard let bytes = docVal.data.getBytes(at: 0, length: docVal.data.writerIndex) else {
            return
        }
        data.writeBytes(bytes)
        data.setInteger(Int32(data.writerIndex + 1), at: 0, as: Int32.self)

    }

    init(from data: inout ByteBuffer) {
        guard let len: Int32 = data.readInteger(as: Int32.self) else {
            self.init()
            return
        }
        data.moveReaderIndex(to: data.readerIndex - 4)
        guard let slicedData = data.getSlice(at: data.readerIndex, length: Int(len) - 1) else {
            self.init()
            return
        }
        data.moveReaderIndex(to: data.readerIndex + Int(len) - 1)
        self.init(fromBSON: slicedData)
        return
    }
}

extension Document: Codable {}


extension ByteBuffer {
    internal mutating func getString() -> String? {
        var idx: Int = self.readerIndex
        while self.getBytes(at: idx, length: 1)![0] != UInt8(0) {
            idx += 1
        }
        let str = self.readString(length: idx - self.readerIndex)
        //skip over null byte
        self.moveReaderIndex(to: self.readerIndex + 1)
        return str
    }
}

extension ByteBuffer: Hashable {
    /// The hash value for the readable bytes.
    public func hash(into hasher: inout Hasher) {
        self.withUnsafeReadableBytes { ptr in
            hasher.combine(bytes: ptr)
        }
    }
}

extension ByteBuffer: Codable {
    public init(from decoder: Decoder) throws {
        throw DecodingError.typeMismatch(
        ByteBuffer.self,
        DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "error decoding"))
    }

    public func encode(to: Encoder) throws {
        throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: to.codingPath, debugDescription: "error encoding"))
    }
}

extension UInt8 {
    var hex: String {
        return String(format: "%02x", self)
    }
}

extension Array where Element == UInt8 {
    var hex: String {
        return reduce("") { $0 + String(format: "%02x ", $1) }
    }
}
