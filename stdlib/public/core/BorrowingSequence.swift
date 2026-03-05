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
