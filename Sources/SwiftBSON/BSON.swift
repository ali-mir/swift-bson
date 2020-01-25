import NIO

public enum BSON {
    // /// A BSON double.
    // case double(Double)

    /// A BSON string.
    /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#string
    case string(String)

    /// A BSON document.
    case document(Document)

    // /// A BSON array.
    // indirect case array([BSON])

    // /// A BSON binary.
    // case binary(Binary)

    // /// A BSON undefined.
    // case undefined

    // /// A BSON ObjectId.
    // /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#objectid
    // case objectId(ObjectId)

    // /// A BSON boolean.
    // case bool(Bool)

    // /// A BSON UTC datetime.
    // /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#date
    // case datetime(Date)

    // /// A BSON null.
    // case null

    // /// A BSON regular expression.
    // case regex(RegularExpression)

    // /// A BSON dbPointer.
    // case dbPointer(DBPointer)

    // /// A BSON symbol.
    // case symbol(Symbol)

    // /// A BSON JavaScript code.
    // case code(Code)

    // /// A BSON JavaScript code with scope.
    // case codeWithScope(CodeWithScope)

    /// A BSON int32.
    case int32(Int32)

    // /// A BSON timestamp.
    // /// - SeeAlso: https://docs.mongodb.com/manual/reference/bson-types/#timestamps
    // case timestamp(Timestamp)

    /// A BSON int64.
    case int64(Int64)

    // /// A BSON Decimal128.
    // /// - SeeAlso: https://github.com/mongodb/specifications/blob/master/source/bson-decimal128/decimal128.rst
    // case decimal128(Decimal128)

    // /// A BSON minKey.
    // case minKey

    // /// A BSON maxKey.
    // case maxKey

    public var stringValue: String? {
        guard case let .string(value) = self else {
            return nil
        }
        return value
    }

    /// If this `BSON` is an `.int32`, return it as an `Int32`. Otherwise, return nil.
    public var int32Value: Int32? {
        guard case let .int32(i) = self else {
            return nil
        }
        return i
    }

    /// If this `BSON` is an `.int64`, return it as an `Int64`. Otherwise, return nil.
    public var int64Value: Int64? {
        guard case let .int64(i) = self else {
            return nil
        }
        return i
    }

    /// If this `BSON` is a `.document`, return it as a `Document`. Otherwise, return nil.
    public var documentValue: Document? {
        guard case let .document(d) = self else {
            return nil
        }
        return d
    }
}

extension BSON {
    /// List of all BSONValue types. Can be used to exhaustively check each one at runtime.
    internal static var allBSONTypes: [BSONValue.Type] = [
        Int32.self,
    ]

    /// Get the associated `BSONValue` to this `BSON` case.
    internal var bsonValue: BSONValue {
        switch self {
        case let .string(v):
            return v
        case let .int32(v):
            return v
        case let .document(v):
            return v
        case let .int64(v):
            return v
        }
    }

    internal var bsonType: BSONType {
        return type(of: self.bsonValue).bsonType
    }

    /// Initialize a `BSON` from an integer. On 64-bit systems, this will result in an `.int64`. On 32-bit systems,
    /// this will result in an `.int32`.
    public init(_ int: Int) {
        if MemoryLayout<Int>.size == 4 {
            self = .int32(Int32(int))
        } else {
            self = .int64(Int64(int))
        }
    }
}


extension BSON: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension BSON: ExpressibleByIntegerLiteral {
    /// Initialize a `BSON` from an integer. On 64-bit systems, this will result in an `.int64`. On 32-bit systems,
    /// this will result in an `.int32`.
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension BSON: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, BSON)...) {
        self = .document(Document(keyValuePairs: elements))
    }
}

extension BSON: Equatable {}

extension BSON: Hashable {}





