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
@frozen
@safe
public struct Borrow<Value: ~Copyable>: Copyable, ~Escapable {
  @usableFromInline
  let builtin: Builtin.Borrow<Value>

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: borrowing Value) {
    builtin = Builtin.makeBorrow(value)
  }
}

@available(SwiftStdlib 6.4, *)
extension Borrow where Value: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_transparent
  public var value: Value {
    borrow {
      Builtin.dereferenceBorrow(builtin)
    }
  }
}
