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
public struct _Ref<To: ~Copyable>: Copyable, ~Escapable {
  @usableFromInline
  let pointer: UnsafePointer<To>

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ to: borrowing To) -> dependsOn(to) Self {
    pointer = UnsafePointer<To>(Builtin.unprotectedAddressOfBorrow(to))
    return self
  }

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  public subscript() -> To {
    @_transparent
    unsafeAddress {
      pointer
    }
  }
}

@available(SwiftStdlib 9999, *)
@frozen
public struct _MutableRef<To: ~Copyable>: ~Copyable, ~Escapable {
  @usableFromInline
  let pointer: UnsafeMutablePointer<To>

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  @_transparent
  public init(_ to: inout To) -> dependsOn(to) Self {
    pointer = UnsafeMutablePointer<To>(Builtin.unprotectedAddressOf(&to))
    return self
  }

  @available(SwiftStdlib 9999, *)
  @_alwaysEmitIntoClient
  public subscript() -> To {
    @_transparent
    unsafeAddress {
      UnsafePointer<To>(pointer)
    }

    @_transparent
    nonmutating unsafeMutableAddress {
      pointer
    }
  }
}
