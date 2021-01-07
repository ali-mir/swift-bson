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

    public func mapValues(_ transform: (BSON) throws -> BSON) rethrows -> Document {
        var output = Document()
        for (k, v) in self {
            output[k] = try transform(v)
        }
        return output
    }

}