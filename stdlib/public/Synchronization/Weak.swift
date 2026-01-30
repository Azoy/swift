//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift Atomics open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Builtin

@available(SwiftStdlib 6.4, *)
@frozen
@safe
public struct Weak<Value: ~Copyable>: ~Copyable {
  @usableFromInline
  let pointer: UnsafeMutablePointer<Arc<Value>._Storage>?

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_transparent
  init(_ other: UnsafeMutablePointer<Arc<Value>._Storage>) {
    unsafe pointer = other
  }

  @_alwaysEmitIntoClient
  @_transparent
  deinit {

  }
}

@available(SwiftStdlib 6.4, *)
extension Weak where Value: ~Copyable {
  // Note: This is safe because 'Arc' will always have at least shared access to
  //       the storage allocation which has already been initialized.
  @_alwaysEmitIntoClient
  @_transparent
  internal var storage: Borrow<Arc<Value>._Storage>? {
    guard let ptr = pointer else {
      return nil
    }

    return unsafe Borrow(unsafeAddress: ptr, borrowing: self)
  }
}

@available(SwiftStdlib 6.4, *)
extension Weak where Value: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  public func promote() -> Arc<Value>? {
    var result = (
      exchanged: false,
      original: storage.value.strong.load(ordering: .relaxed)
    )

    repeat {
      // If we see that our strong count is already 0, then the value has already
      // been deinitialized.
      if result.original == 0 {
        return nil
      }

      // This promotion would've overflowed the strong count, bail.
      if result.original == .max {
        return nil
      }

      result = storage.value.strong.weakCompareExchange(
        expected: result.original,
        desired: result.original &+ 1,
        successOrdering: .acquiring,
        failureOrdering: .relaxed
      )
    } while !result.exchanged

    return unsafe Arc(pointer)
  }
}
