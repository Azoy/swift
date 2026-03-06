//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 6.4, *)
public protocol BorrowingSequence<BorrowedElement>: ~Copyable & ~Escapable {
  associatedtype BorrowedElement: ~Copyable & ~Escapable
  associatedtype BorrowingIterator: IteratorProtocol<BorrowedElement> & ~Copyable & ~Escapable

  @_lifetime(borrow self)
  borrowing func makeBorrowingIterator() -> BorrowingIterator
}

@available(SwiftStdlib 6.4, *)
public protocol MutatingSequence<MutableElement>: ~Copyable & ~Escapable {
  associatedtype MutableElement: ~Copyable & ~Escapable
  associatedtype MutatingIterator: IteratorProtocol<MutableElement> & ~Copyable & ~Escapable

  @_lifetime(&self)
  mutating func makeMutatingIterator() -> MutatingIterator
}

@available(SwiftCompatibilitySpan 5.0, *)
@_originallyDefinedIn(module: "Swift;CompatibilitySpan", SwiftCompatibilitySpan 6.2)
extension Span where Element: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  public func _borrowElement(at i: Int) -> Borrow<Element> {
    unsafe Borrow(
      unsafeAddress: _unsafeAddressOfElement(unchecked: i),
      copying: self
    )
  }
}

@available(SwiftStdlib 6.4, *)
extension Span: IteratorProtocol where Element: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @_lifetime(copy self)
  public mutating func next() -> Borrow<Element>? {
    guard !isEmpty else {
      return nil
    }

    let b = _borrowElement(at: 0)
    self = extracting(droppingFirst: 1)
    return b
  }
}

@available(SwiftStdlib 6.4, *)
@frozen
public struct LazyMapIter<
  Iter: IteratorProtocol & ~Copyable & ~Escapable,
  NewElement: ~Copyable & ~Escapable
>: ~Copyable, ~Escapable where Iter.Element: ~Copyable & ~Escapable {
  @usableFromInline
  var iter: Iter

  @usableFromInline
  let fn: (consuming Iter.Element) -> NewElement

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_lifetime(copy iter)
  @_transparent
  init(_ iter: consuming Iter, _ fn: @escaping (consuming Iter.Element) -> NewElement) {
    self.iter = iter
    self.fn = fn
  }
}

@available(SwiftStdlib 6.4, *)
extension LazyMapIter: Copyable where Iter: Copyable & ~Escapable, Iter.Element: ~Copyable & ~Escapable, NewElement: ~Copyable & ~Escapable {}

@available(SwiftStdlib 6.4, *)
extension LazyMapIter: Escapable where Iter: Escapable & ~Copyable, Iter.Element: ~Escapable & ~Copyable, NewElement: ~Copyable & ~Escapable {}

// FIXME: Remove NewElement escapable conformance
@available(SwiftStdlib 6.4, *)
extension LazyMapIter: IteratorProtocol where Iter: ~Copyable & ~Escapable, Iter.Element: ~Copyable & ~Escapable, NewElement: Escapable & ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  public mutating func next() -> NewElement? {
    // FIXME: '_consumingMap' requires escapable result
    iter.next()._consumingMap(fn)
  }
}

@available(SwiftStdlib 6.4, *)
extension IteratorProtocol where Self: ~Copyable & ~Escapable, Element: ~Copyable & ~Escapable {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_lifetime(copy self)
  @_transparent
  public consuming func map<NewElement: ~Copyable>(
    _ fn: @escaping (consuming Element) -> NewElement
  ) -> LazyMapIter<Self, NewElement> {
    LazyMapIter(self, fn)
  }
}
