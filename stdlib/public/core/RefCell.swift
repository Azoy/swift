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

@available(SwiftStdlib 6.3, *)
@frozen
@safe
public struct _RefCell<Value: ~Copyable>: ~Copyable {
  // < 0 = Writing
  // 0 = Unused
  // > 0 = Borrows are outstanding
  @usableFromInline
  let borrows = unsafe _Cell(0)

  @usableFromInline
  let value: _Cell<Value>

  @available(SwiftStdlib 6.3, *)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ initialValue: consuming Value) {
    unsafe value = _Cell(initialValue)
  }
}

@available(SwiftStdlib 6.3, *)
extension _RefCell where Value: ~Copyable {
  @available(SwiftStdlib 6.3, *)
  @frozen
  @safe
  public struct Ref: ~Copyable, ~Escapable {
    @usableFromInline
    let cell: _Borrow<_RefCell<Value>>

    @available(SwiftStdlib 6.3, *)
    @_alwaysEmitIntoClient
    public var value: Value {
      @_transparent
      unsafeAddress {
        unsafe UnsafePointer(cell[].value.address)
      }
    }

    @available(SwiftStdlib 6.3, *)
    @lifetime(copy cell)
    @_alwaysEmitIntoClient
    @_transparent
    internal init(cell: _Borrow<_RefCell<Value>>) {
      self.cell = cell
    }

    @_alwaysEmitIntoClient
    @_transparent
    deinit {
      unsafe cell[].borrows.value -= 1
    }
  }

  @available(SwiftStdlib 6.3, *)
  @lifetime(borrow self)
  @_alwaysEmitIntoClient
  @_transparent
  public func borrow() -> Ref {
    guard borrows.value >= 0 else {
      _preconditionFailure("Exclusivity violation")
    }

    borrows.value += 1
    return Ref(cell: _Borrow(self))
  }
}

@available(SwiftStdlib 6.3, *)
extension _RefCell where Value: ~Copyable {
  @available(SwiftStdlib 6.3, *)
  @frozen
  @safe
  public struct MutRef: ~Copyable, ~Escapable {
    @usableFromInline
    let cell: _Borrow<_RefCell<Value>>

    @available(SwiftStdlib 6.3, *)
    @_alwaysEmitIntoClient
    public var value: Value {
      @_transparent
      unsafeAddress {
        unsafe UnsafePointer(cell[].value.address)
      }

      @_transparent
      nonmutating unsafeMutableAddress {
        unsafe cell[].value.address
      }
    }

    @available(SwiftStdlib 6.3, *)
    @lifetime(copy cell)
    @_alwaysEmitIntoClient
    @_transparent
    internal init(cell: _Borrow<_RefCell<Value>>) {
      self.cell = cell
    }

    @_alwaysEmitIntoClient
    @_transparent
    deinit {
      cell[].borrows.value -= 1
    }
  }

  @available(SwiftStdlib 6.3, *)
  @lifetime(borrow self)
  @_alwaysEmitIntoClient
  @_transparent
  public func mutate() -> MutRef {
    guard borrows.value == 0 else {
      _preconditionFailure("Exclusivity violation")
    }

    borrows.value -= 1
    return MutRef(cell: _Borrow(self))
  }
}
