import Foundation
import NIO

extension Document: Sequence {
    public typealias Iterator = DocumentIterator

    public func makeIterator() -> DocumentIterator {
        return DocumentIterator(over: self)
    }
}

public struct DocumentIterator: IteratorProtocol {
    /// The data we are iterating over.
    private var data: ByteBuffer

    internal init(over document: Document) {
        /// Skip the first 4 bytes as they contain the length.
        data = document.data
        data.moveReaderIndex(to: 4)
    }

    public mutating func next() -> (String, BSON)? {
        do {
            return try nextOrError()
        } catch {
            fatalError("error reading next value from iterator: \(error)")
        }
    }

    /// Attempts to get the next value in the iterator, or throws an error
    internal mutating func nextOrError() throws -> (String, BSON)? {
        guard let rawType = self.data.readBytes(length: 1) else {
            return nil
        }
        guard let type = BSONType(rawValue: rawType[0]) else {
            return nil
        }
        guard let key = self.data.getString() else {
            return nil
        }
        guard let swiftType = typeMap[type] else {
            return nil
        }
        let value = swiftType.init(from: &self.data)
        return (key, value.bson)
    }

    // internal var keys: [String] {
    //     var keys = [String]()
    //     while self.advance() { keys.append(self.currentKey) }
    //     return keys
    // }

    // internal var values: [BSON] {
    //     var values = [BSON]()
    //     while self.advance() { values.append(self.currentValue) }
    //     return values
    // }
}

let typeMap: [BSONType: BSONValue.Type] = [
    .int32: Int32.self,
    .int64: Int64.self,
    .string: String.self,
    .document: Document.self
]
