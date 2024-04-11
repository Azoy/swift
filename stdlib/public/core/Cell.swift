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
@_rawLayout(like: Value)
public struct _Cell<Value: ~Copyable>: ~Copyable {
  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public var address: UnsafeMutablePointer<Value> {
    UnsafeMutablePointer<Value>(rawAddress)
  }

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public var rawAddress: Builtin.RawPointer {
#if $BuiltinAddressOfRawLayout
    Builtin.addressOfRawLayout(self)
#else
    fatalError()
#endif
  }

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ value: consuming Value) {
    address.initialize(to: value)
  }
}

@available(SwiftStdlib 9999, *)
extension _Cell where Value: Copyable {
  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public var value: Value {
    address.pointee
  }
}
