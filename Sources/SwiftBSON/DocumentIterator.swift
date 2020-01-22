import Foundation
import NIO

extension Document: Sequence {
    public typealias Iterator = DocumentIterator
    public typealias SubSequence = Document
    public typealias KeyValuePair = (key: String, value: BSON)



    public func makeIterator() -> DocumentIterator {
        return DocumentIterator(over: self)
    }

    public var isEmpty: Bool { return self.keys.count == 0 }

    public var values: [BSON] {
        var values = [BSON]()
        self.forEach({ values.append($0.1) })
        return values

    }

    public func dropFirst(_ n: Int) -> Document {
        switch n {
        case ..<0:
            fatalError("Can't drop a negative number of elements from a document")
        case 0:
            return self
        default:
            return self.dropFirst(n)
        }
    }

    public func dropLast(_ n: Int) -> Document {
        switch n {
        case ..<0:
            fatalError("Can't drop a negative number of elements from a `Document`")
        case 0:
            return self
        default:
            return self.dropLast(n)
        }
    }

    public func drop(while predicate: (KeyValuePair) throws -> Bool) rethrows -> Document {
        // tracks whether we are still in a "dropping" state. once we encounter
        // an element that doesn't satisfy the predicate, we stop dropping.
        var drop = true
        return try self.filter { elt in
            if drop {
                // still in "drop" mode and it matches predicate
                if try predicate(elt) {
                    return false
                }
                // else we've encountered our first non-matching element
                drop = false
                return true
            }
            // out of "drop" mode, so we keep everything
            return true
        }
    }

    public func prefix(_ maxLength: Int) -> Document {
        switch maxLength {
        case ..<0:
            fatalError("Can't retrieve a negative length prefix of a `Document`")
        case 0:
            return [:]
        default:
            // short circuit if there are fewer elements in the doc than requested
            return self.count <= maxLength ? self : self.prefix(maxLength)
        }
    }

    public func prefix(while predicate: (KeyValuePair) throws -> Bool) rethrows -> Document {
        var output = Document()
        for elt in self {
            if try !predicate(elt) { break }
            output[elt.0] = elt.1
        }
        return output
    }

    public func suffix(_ maxLength: Int) -> Document {
        switch maxLength {
        case ..<0:
            fatalError("Can't retrieve a negative length suffix of a `Document`")
        case 0:
            return [:]
        default:
            let start = self.count - maxLength
            // short circuit if there are fewer elements in the doc than requested
            return start <= 0 ? self : self.suffix(maxLength)
        }
    }

    public func split(
        maxSplits: Int = Int.max,
        omittingEmptySubsequences: Bool = true,
        whereSeparator isSeparator: (KeyValuePair) throws -> Bool
    ) rethrows -> [Document] {
        return try self.split(maxSplits: maxSplits, omittingEmptySubsequences: omittingEmptySubsequences, whereSeparator: isSeparator)
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

}

let typeMap: [BSONType: BSONValue.Type] = [
    .int32: Int32.self,
    .int64: Int64.self,
    .string: String.self,
    .document: Document.self
]
