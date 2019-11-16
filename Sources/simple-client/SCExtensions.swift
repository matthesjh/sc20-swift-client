extension Array where Element: Equatable {
    /// Removes the first occurrence of the given element from the collection.
    ///
    /// Calling this method may invalidate any existing indices for use with
    /// this collection.
    ///
    /// - Parameter element: The element to remove from the collection.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the collection.
    @inlinable
    public mutating func removeFirst(of element: Element) {
        guard let index = self.firstIndex(of: element) else {
            return
        }

        self.remove(at: index)
    }
}

extension Sequence {
    /// Returns the number of elements in the sequence that satisfy the given
    /// predicate.
    ///
    /// The sequence must be finite.
    ///
    /// - Parameter predicate: A closure that takes each element of the sequence
    ///   as its argument and returns a Boolean value indicating whether the
    ///   element should be included in the count.
    ///
    /// - Returns: The number of elements in the sequence that satisfy the given
    ///   predicate.
    ///
    /// - Complexity: O(*n*), where *n* is the length of the sequence.
    @inlinable
    public func count(where predicate: (Element) throws -> Bool) rethrows -> Int {
        var count = 0

        for e in self {
            if try predicate(e) {
                count += 1
            }
        }

        return count
    }
}