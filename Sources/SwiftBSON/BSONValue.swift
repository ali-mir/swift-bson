import Foundation
import NIO

/// The possible types of BSON values and their corresponding integer values.
public enum BSONType: UInt8 {
    case string = 0x02
    case document = 0x03
    case int32 = 0x10
    case int64 = 0x12
}

/// A protocol all types representing `BSONType`s must implement.
internal protocol BSONValue: Codable {
    /// The `BSONType` of this value.
    static var bsonType: BSONType { get }

    /// A corresponding `BSON` to this `BSONValue`.
    var bson: BSON { get }

    // encodes BSONValue into an array of bytes to append to ByteBuffer
    func encode(key: String, data: inout ByteBuffer)

    // decodes BSONValue from ByteBuffer
    init(from data: inout ByteBuffer)

}

// An extension of `Int32` to represent the BSON Int32 type.
extension Int32: BSONValue {
    internal static var bsonType: BSONType { return .int32 }

    internal var bson: BSON { return .int32(self) }

    func encode(key: String, data: inout ByteBuffer) {
        data.writeBytes([BSONType.int32.rawValue])
        data.writeBytes([UInt8](key.utf8))
        data.writeBytes([0])
        guard let intVal = self.bson.int32Value else {
            return
        }
        data.writeInteger(intVal)
        data.setInteger(Int32(data.writerIndex + 1), at: 0, as: Int32.self)

    }

    init(from data: inout ByteBuffer) {
        guard let int: Int32 = data.readInteger(as: Int32.self) else {
            self.init()
            return
        }
        self.init(int)
        return
    }
}

// An extension of `Int32` to represent the BSON Int32 type.
extension Int64: BSONValue {
    internal static var bsonType: BSONType { return .int64 }

    internal var bson: BSON { return .int64(self) }

    func encode(key: String, data: inout ByteBuffer) {
        // let len = data.writerIndex
        data.writeBytes([BSONType.int64.rawValue])
        data.writeBytes([UInt8](key.utf8))
        data.writeBytes([0])
        guard let intVal = self.bson.int64Value else {
            return
        }
        data.writeInteger(intVal)
        // data.setInteger(Int32(data.writerIndex - len), at: 0, as: Int32.self)
        data.setInteger(Int32(data.writerIndex + 1), at: 0, as: Int32.self)
    }

    init(from data: inout ByteBuffer) {
        guard let int: Int64 = data.readInteger(as: Int64.self) else {
            self.init()
            return
        }
        self.init(int)
        return
    }
}

// An extension of `String` to represent the BSON String type.
extension String: BSONValue {
    internal static var bsonType: BSONType { return .string }

    internal var bson: BSON { return .string(self) }

    func encode(key: String, data: inout ByteBuffer) {
        data.writeBytes([BSONType.string.rawValue])
        data.writeBytes([UInt8](key.utf8))
        data.writeBytes([0])
        guard let stringVal = self.bson.stringValue else {
            return
        }
        data.writeBytes(stringVal.utf8)
        data.writeBytes([0])
        let stringLen: Int32 = Int32([UInt8](stringVal.utf8).count + 1)
        data.writeInteger(stringLen)
        data.writeBytes(stringVal.utf8)
        data.writeBytes([0])
        data.setInteger(Int32(data.writerIndex + 1), at: 0, as: Int32.self)

    }

    init(from data: inout ByteBuffer) {
        guard let string: String = data.getString() else {
            self.init()
            return
        }
        // skip over string
        data.moveReaderIndex(to:data.readerIndex + 4 + (string.utf8).count + 1)
        self.init(string)
    }
}


