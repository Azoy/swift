//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@available(SwiftStdlib 9999, *)
@frozen
public struct _Box<Value: ~Copyable>: ~Copyable {
  @usableFromInline
  let pointer: UnsafeMutablePointer<Value>

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming Value) {
    pointer = UnsafeMutablePointer<Value>.allocate(capacity: 1)
    pointer.initialize(to: value)
  }

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @inlinable
  deinit {
    pointer.deinitialize(count: 1)
    pointer.deallocate()
  }
}

@available(SwiftStdlib 9999, *)
extension _Box where Value: ~Copyable {
  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public consuming func leak() -> Value {
    let result = pointer.move()
    discard self
    return result
  }

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public borrowing func swap(with newValue: consuming Value) -> Value {
    let result = pointer.move()
    pointer.initialize(to: newValue)
    return result
  }
}
