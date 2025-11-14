//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Span
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 6.3, *)
extension Span: IteratorProtocol {
  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  public mutating func next() -> Element? {
    let s = nextSpan(maximumCount: 1)
    guard !s.isEmpty else { return nil }
    return s[0]
  }

  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    let result = extracting(first: maximumCount)
    self = extracting(droppingFirst: maximumCount)
    return result
  }
}

@available(SwiftStdlib 6.3, *)
extension Sequence where NewIterator == Span<Element>, Self: ~Copyable & ~Escapable {
  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  public func makeIterator() -> Span<Element>.Iterator {
    _preconditionFailure("Cannot use 'Iterator'; must use 'NewIterator'")
  }

  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  public var underestimatedCount: Int {
    makeNewIterator().count
  }

  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  public func _customContainsEquatableElement(
    _ element: Element
  ) -> Bool? {
    nil
  }

  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  public func _copyToContiguousArray() -> ContiguousArray<Element> {
    unsafe makeNewIterator().withUnsafeBufferPointer {
      unsafe ContiguousArray($0)
    }
  }

  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  public func _copyContents(
    initializing ptr: UnsafeMutableBufferPointer<Element>
  ) -> (Iterator,UnsafeMutableBufferPointer<Element>.Index) {
    fatalError()
  }

  @available(SwiftStdlib 6.3, *)
  @safe
  @_alwaysEmitIntoClient
  public func withContiguousStorageIfAvailable<R>(
    _ body: (_ buffer: UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    try unsafe makeNewIterator().withUnsafeBufferPointer(body)
  }
}

@available(SwiftStdlib 6.3, *)
extension Span: Sequence {
  @available(SwiftStdlib 6.3, *)
  public typealias NewIterator = Self
}

extension Span {
  @available(SwiftStdlib 6.3, *)
  @frozen
  public struct Iterator {}
}

@available(SwiftStdlib 6.3, *)
extension Span.Iterator: IteratorProtocol {
  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  public mutating func next() -> Element? {
    _preconditionFailure("Cannot use 'Iterator' on Span; must use 'NewIterator'")
  }

  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  @_lifetime(&self)
  public mutating func nextSpan(maximumCount: Int) -> Span<Element> {
    _preconditionFailure("Cannot use 'Iterator' on Span; must use 'NewIterator'")
  }
}

//===----------------------------------------------------------------------===//
// MutableSpan
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 6.3, *)
extension MutableSpan: Sequence {
  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeNewIterator() -> Span<Element> {
    span
  }
}

//===----------------------------------------------------------------------===//
// OutputSpan
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 6.3, *)
extension OutputSpan: Sequence {
  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  @_lifetime(borrow self)
  public func makeNewIterator() -> Span<Element> {
    span
  }
}
