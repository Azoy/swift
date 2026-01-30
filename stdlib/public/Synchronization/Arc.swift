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

#if _pointerBitWidth(_64)
@usableFromInline
typealias HalfWord = UInt32
#elseif _pointerBitWidth(_32)
@usableFromInline
typealias HalfWord = UInt16
#else
#error("Unsupported platform")
#endif

@available(SwiftStdlib 6.4, *)
extension Arc where Value: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @frozen
  public struct _Storage: ~Copyable {
    @usableFromInline
    let strong = Atomic<HalfWord>(1)

    @usableFromInline
    let weak = Atomic<HalfWord>(1)

    @usableFromInline
    let value: Value

    @available(SwiftStdlib 6.4, *)
    @_alwaysEmitIntoClient
    @_transparent
    init(_ initialValue: consuming Value) {
      value = initialValue
    }
  }
}

@available(SwiftStdlib 6.4, *)
@frozen
@safe
public struct Arc<Value: ~Copyable>: ~Copyable {
  @usableFromInline
  let pointer: UnsafeMutablePointer<_Storage>

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  public init(_ initialValue: consuming Value) {
    unsafe pointer = .allocate(capacity: 1)
    unsafe pointer.initialize(to: _Storage(initialValue))
  }

  @available(SwiftStdlib 6.4, *)
  @unsafe
  @_alwaysEmitIntoClient
  @_transparent
  init(_ other: UnsafeMutablePointer<_Storage>) {
    unsafe pointer = other
  }

  @_alwaysEmitIntoClient
  @_transparent
  deinit {
    // FIXME: I would like to write storage.value.strong here
    let (ov, _) = unsafe pointer.pointee.strong.wrappingSubtract(1, ordering: .releasing)

    if ov != 1 {
      return
    }

    atomicMemoryFence(ordering: .acquiring)

    unsafe pointer.deinitialize(count: 1)

    // We let our implicit weak reference deallocate the storage if we're the
    // last weak owner. Otherwise, some other weak instance will get rid of it.
    let _ = unsafe Weak(pointer)
  }
}

@available(SwiftStdlib 6.4, *)
extension Arc where Value: ~Copyable {
  // Note: This is safe because 'Arc' will always have at least shared access to
  //       the storage allocation which has already been initialized.
  @_alwaysEmitIntoClient
  @_transparent
  internal var storage: Borrow<_Storage> {
    unsafe Borrow(unsafeAddress: pointer, borrowing: self)
  }
}

@available(SwiftStdlib 6.4, *)
extension Arc where Value: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  public var isUnique: Bool {
    storage.value.strong.load(ordering: .relaxed) == 1
  }

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_transparent
  public var value: Value {
    @_unsafeSelfDependentResult
    borrow {
      unsafe pointer.pointee.value
    }
  }
}

@available(SwiftStdlib 6.4, *)
extension Arc where Value: ~Copyable {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  @_transparent
  public func borrow() -> Borrow<Value> {
    // _Storage's first word is both the strong and weak ref count, so offset by
    // a word to get the pointer to the value.
    let offsetPtr = unsafe UnsafeRawPointer(pointer) + MemoryLayout<Int>.size
    let valuePtr = unsafe UnsafePointer<Value>(offsetPtr._rawValue)
    return unsafe Borrow(unsafeAddress: valuePtr, borrowing: self)
  }

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  public func clone() -> Arc<Value> {
    let (_, nv) = storage.value.strong.wrappingAdd(1, ordering: .relaxed)

    if nv == 0 {
      Builtin.int_trap()
    }

    return unsafe Arc(pointer)
  }

  public func demote() -> Weak<Value> {
    let (ov, _) = storage.value.weak.wrappingAdd(1, ordering: .relaxed)

    // We overflowed the weak count; bail.
    if ov == .max {
      Builtin.int_trap()
    }

    return unsafe Weak(pointer)
  }

  @available(SwiftStdlib 6.4, *)
  @discardableResult
  @_alwaysEmitIntoClient
  public mutating func ensureUnique(
    cloner: (borrowing Value) -> Value
  ) -> Bool {
    if isUnique {
      return true
    }

    replace(using: cloner)
    return false
  }

  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  public mutating func replace(using body: (borrowing Value) -> Value) {
    self = Arc(body(value))
  }
}

@available(SwiftStdlib 6.4, *)
extension Arc /* where Value: Clonable */ {
  @available(SwiftStdlib 6.4, *)
  @_alwaysEmitIntoClient
  public mutating func makeUnique() {
    ensureUnique {
      $0
    }
  }
}
