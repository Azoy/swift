//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

@_rawLayout(like: T)
@frozen
public struct UnsafeCell<T>: ~Copyable {
  @inlinable
  public var address: UnsafeMutablePointer<T> {
    .init(Builtin.unprotectedAddressOfBorrow(self))
  }

  @inlinable
  public init() {}
}

@frozen
public struct Cell<T>: ~Copyable {
  @usableFromInline
  var value = UnsafeCell<T>()

  @inlinable
  public init(_ initialValue: consuming T) {
    value.address.initialize(to: initialValue)
  }

  @inlinable
  deinit {
    value.address.deinitialize(count: 1)
  }
}
