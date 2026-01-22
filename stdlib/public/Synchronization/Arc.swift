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
  init(_ other: borrowing Self) {
    unsafe pointer = other.pointer
  }

  @_alwaysEmitIntoClient
  @_transparent
  deinit {
    let (ov, _) = unsafe pointer.pointee.strong.wrappingSubtract(1, ordering: .releasing)

    if ov != 1 {
      return
    }

    atomicMemoryFence(ordering: .acquiring)

    unsafe pointer.deinitialize(count: 1)
    unsafe pointer.deallocate()
  }
}

@available(SwiftStdlib 6.4, *)
extension Arc where Value: ~Copyable {
  public var value: Value {
    @_unsafeSelfDependentResult
    borrow {
      unsafe pointer.pointee.value
    }
  }

  @available(SwiftStdlib 6.4, *)
  // @_alwaysEmitIntoClient
  // @_transparent
  public func clone() -> Arc<Value> {
    let (_, nv) = unsafe pointer.pointee.strong.wrappingAdd(1, ordering: .relaxed)

    if nv == 0 {
      Builtin.int_trap()
    }

    return unsafe Arc(self)
  }
}

@available(SwiftStdlib 6.4, *)
public func dumb(_ arc: borrowing Arc<Int>) -> Arc<Int> {
  arc.clone()
}
