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

// FIXME: This shouldn't be necessary, ideally we can say
// `UnsafePointer<__HeapObject>`.
struct UnsafeHeapObjectPointer {
  var raw: UnsafeRawPointer

  var bitPattern: UInt {
    UInt(bitPattern: raw)
  }

  var pointee: __HeapObject {
    @_transparent unsafeAddress {
      Builtin.reinterpretCast(self)
    }
  }

  init(_ raw: UnsafeRawPointer) {
    self.raw = raw
  }
}

// FIXME: This shouldn't be necessary, ideally we can say
// `UnsafePointer<__HeapObjectSideTableEntry>`.
struct UnsafeSideTablePointer {
  var raw: UnsafeRawPointer

  var bitPattern: UInt {
    UInt(bitPattern: raw)
  }

  var pointee: __HeapObjectSideTableEntry {
    @_transparent unsafeAddress {
      Builtin.reinterpretCast(self)
    }
  }

  init(_ raw: UnsafeRawPointer) {
    self.raw = raw
  }
}

protocol RefCountOffsets {
  associatedtype BitsType: FixedWidthInteger & UnsignedInteger

  static var pureSwiftDeallocMask: BitsType { get }
  static var unownedRefCountMask: BitsType { get }
  static var isImmortalMask: BitsType { get }
  static var isDeinitingMask: BitsType { get }

  static var strongExtraRefCountShift: BitsType { get }
  static var strongExtraRefCountMask: BitsType { get }

  static var useSlowRCMask: BitsType { get }
  static var sideTableMask: BitsType { get }
  static var sideTableMarkMask: BitsType { get }
}

protocol RefCountBits {
  associatedtype BitsType: AtomicValue & FixedWidthInteger & UnsignedInteger
  associatedtype SignedBitsType: FixedWidthInteger & SignedInteger
  associatedtype Offsets: RefCountOffsets where Offsets.BitsType == BitsType

  var bits: BitsType { get set }

  init(_ bits: BitsType)

  var hasSideTable: Bool { get }
  var sideTable: UnsafeSideTablePointer { get }
  var usesSlowRC: Bool { get }
  func isImmortal(checkSlowRCBit: Bool) -> Bool
  mutating func incrementStrongExtraRefCount(by n: BitsType) -> Bool
}

extension RefCountBits {
  var hasSideTable: Bool {
    usesSlowRC && !isImmortal(checkSlowRCBit: false)
  }

  var sideTable: UnsafeSideTablePointer {
    let bitPattern = UInt(truncatingIfNeeded: bits & Offsets.sideTableMask)
    let raw = UnsafeRawPointer(bitPattern: bitPattern)._unsafelyUnwrappedUnchecked
    return UnsafeSideTablePointer(raw)
  }

  var usesSlowRC: Bool {
    bits & Offsets.useSlowRCMask != 0
  }

  func isImmortal(checkSlowRCBit: Bool) -> Bool {
    let isImmortalFast = bits & Offsets.isImmortalMask == Offsets.isImmortalMask

    if checkSlowRCBit {
      return isImmortalFast && usesSlowRC
    }

    return isImmortalFast
  }

  mutating func incrementStrongExtraRefCount(by n: BitsType) -> Bool {
    // This intentionally overflows into the UseSlowRC bit.
    bits &+= n &<< Offsets.strongExtraRefCountShift
    return SignedBitsType(truncatingIfNeeded: bits) >= 0
  }
}

struct Inline64BitRefCountOffsets: RefCountOffsets {
  typealias BitsType = UInt64

  @_transparent
  static var pureSwiftDeallocMask: BitsType {
    (1 &<< 1) &- 1
  }

  @_transparent
  static var unownedRefCountMask: BitsType {
    ((1 &<< 31) &- 1) &<< 1
  }

  @_transparent
  static var isImmortalMask: BitsType {
    (1 &<< 32) &- 1
  }

  @_transparent
  static var isDeinitingMask: BitsType {
    ((1 &<< 1) &- 1) &<< 32
  }

  @_transparent
  static var strongExtraRefCountShift: BitsType {
    33
  }

  @_transparent
  static var strongExtraRefCountMask: BitsType {
    ((1 &<< 30) - 1) &<< Self.strongExtraRefCountShift
  }

  @_transparent
  static var useSlowRCMask: BitsType {
    ((1 &<< 1) &- 1) &<< 63
  }

  @_transparent
  static var sideTableMask: BitsType {
    (1 &<< 62) &- 1
  }

  @_transparent
  static var sideTableMarkMask: BitsType {
    ((1 &<< 1) &- 1) &<< 62
  }
}

struct Inline32BitRefCountOffsets: RefCountOffsets {
  typealias BitsType = UInt32

  @_transparent
  static var pureSwiftDeallocMask: BitsType {
    (1 &<< 1) &- 1
  }

  @_transparent
  static var unownedRefCountMask: BitsType {
    ((1 &<< 7) &- 1) &<< 1
  }

  @_transparent
  static var isImmortalMask: BitsType {
    (1 &<< 8) &- 1
  }

  @_transparent
  static var isDeinitingMask: BitsType {
    ((1 &<< 1) &- 1) &<< 8
  }

  @_transparent
  static var strongExtraRefCountShift: BitsType {
    9
  }

  @_transparent
  static var strongExtraRefCountMask: BitsType {
    ((1 &<< 22) - 1) &<< Self.strongExtraRefCountShift
  }

  @_transparent
  static var useSlowRCMask: BitsType {
    ((1 &<< 1) &- 1) &<< 31
  }

  @_transparent
  static var sideTableMask: BitsType {
    (1 &<< 30) &- 1
  }

  @_transparent
  static var sideTableMarkMask: BitsType {
    ((1 &<< 1) &- 1) &<< 30
  }
}

struct InlineRefCountBits: RefCountBits {
#if _pointerBitWidth(_64)
  typealias BitsType = UInt64
  typealias SignedBitsType = Int64
  typealias Offsets = Inline64BitRefCountOffsets
#elseif _pointerBitWidth(_32)
  typealias BitsType = UInt32
  typealias BitsType = Int32
  typealias Offsets = Inline32BitRefCountOffsets
#else
#error("Unsupported platform")
#endif

  var bits: BitsType

  init(_ bits: BitsType) {
    self.bits = bits
  }
}

struct SideTableRefCountBits: RefCountBits {
  typealias BitsType = UInt64
  typealias SignedBitsType = Int64
  typealias Offsets = Inline64BitRefCountOffsets

  var bits: BitsType

  init(_ bits: BitsType) {
    self.bits = bits
  }
}

struct RefCounts<Bits: RefCountBits>: ~Copyable
where Bits.BitsType.AtomicRepresentation.Value == Bits.BitsType
{
  let refCounts: Atomic<Bits.BitsType>

  var heapObject: UnsafeHeapObjectPointer {
    let offset = MemoryLayout<UnsafeRawPointer>.size
    let thisAddr = UnsafeRawPointer(refCounts._value.address)
    return UnsafeHeapObjectPointer(thisAddr - offset)
  }

  borrowing func increment(by n: Int) -> UnsafeHeapObjectPointer {
    let oldBits = Bits(refCounts.load(ordering: .relaxed))

    if n != 1, oldBits.isImmortal(checkSlowRCBit: true) {
      return heapObject
    }

    var newBits: Bits

    repeat {
      newBits = oldBits
      let fast = newBits.incrementStrongExtraRefCount(
        by: Bits.BitsType(truncatingIfNeeded: n)
      )

      if _slowPath(!fast) {
        if oldBits.isImmortal(checkSlowRCBit: false) {
          return heapObject
        }

        return incrementSlow(oldBits, by: n)
      }
    } while !refCounts.compareExchange(
      expected: oldBits.bits,
      desired: newBits.bits,
      ordering: .relaxed
    ).exchanged

    return heapObject
  }

  borrowing func incrementSlow(
    _ oldBits: Bits,
    by n: Int
  ) -> UnsafeHeapObjectPointer {
    if oldBits.isImmortal(checkSlowRCBit: false) {
      return heapObject
    }

    if oldBits.hasSideTable {
      let side = oldBits.sideTable
      side.pointee.incrementStrong(by: n)
    } else {
      _unreachable()
    }

    return heapObject
  }
}

// HeapObject is defined in SwiftShims and _HeapObject is some typealias in
// ManagedBuffer zzz
struct __HeapObject: ~Copyable {
  let isa: UnsafeRawPointer
  let refCounts: RefCounts<InlineRefCountBits>
}

struct __HeapObjectSideTableEntry: ~Copyable {
  // Can't use `UnsafePointer<__HeapObject>` and can't use
  // `UnsafeHeapObjectPointer` either as adding the conformance to `AtomicValue`
  // is non-trivial.
  let object: Atomic<UnsafeRawPointer>
  let refCounts: RefCounts<SideTableRefCountBits>

  borrowing func incrementStrong(by n: Int) {
    _ = refCounts.increment(by: n)
  }
}

func isValidPointerForNativeRetain(
  _ object: UnsafeHeapObjectPointer
) -> Bool {
#if arch(arm64_32)
  return UInt(bitPattern: object.raw) != 0
#elseif os(Android) && arch(arm64)
  return (UInt(bitPattern: object.raw) << 8) > 0
#elseif arch(x86_64) || arch(arm64)
  return UInt(bitPattern: object.raw) > 0
#else
  return UInt(bitPattern: object.raw) != 0
#endif
}

// Dummy function to force dead stripping not to strip RefCounts because
// actually increment a heap object's ref count doesn't work in swift_retain
// below because of some compiler crash.
public func __incrementRefCount() -> UnsafeRawPointer {
  // Everything in this function is wrong and incorrect, again I'm just trying
  // to force the emisson of RefCounts into the resulting object file.
  let object = __HeapObject(
    isa: UnsafeRawPointer(bitPattern: 1)._unsafelyUnwrappedUnchecked,
    refCounts: RefCounts<InlineRefCountBits>(refCounts: Atomic<UInt64>(0))
  )

  return object.refCounts.increment(by: 1).raw
}

@_silgen_name("swift_retain2")
public func swift_retain(
  _ object: UnsafeRawPointer
) -> UnsafeRawPointer? {
  let object = unsafeBitCast(object, to: UnsafeHeapObjectPointer.self)

  guard isValidPointerForNativeRetain(object) else {
    return object.raw
  }

  // This crashes the compiler, probably due to the fact that we managed to
  // trick it to make a `UnsafePointer<__HeapObject>`..?
  //return object.pointee.refCounts.increment(by: 1).raw
  return nil
}
