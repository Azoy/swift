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

/// A type that supports atomic operations through a separate atomic storage
/// representation.
public protocol AtomicValue {
  /// The atomic storage representation for this value.
  associatedtype AtomicRepresentation: AtomicStorage
  /* where Self is a subtype of AtomicRepresentation.Value */
}

/// An atomic value.
@frozen
public struct Atomic<Value: AtomicValue>: ~Copyable
where Value.AtomicRepresentation.Value == Value
{
  @usableFromInline
  internal typealias _Storage = Value.AtomicRepresentation

  @usableFromInline
  internal var _value = UnsafeCell<Value.AtomicRepresentation>()

  @inlinable
  public init(_ initialValue: consuming Value) {
    _value.address.initialize(to: _Storage(initialValue))
  }

  @inlinable
  deinit {
    _value.address.deinitialize(count: 1)
  }
}

extension Atomic {
  /// Atomically loads and returns the current value, applying the specified
  /// memory ordering.
  ///
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The current value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func load(
    ordering: AtomicLoadOrdering
  ) -> Value {
    _Storage.atomicLoad(at: _value.address, ordering: ordering)
  }

  /// Atomically sets the current value to `desired`, applying the specified
  /// memory ordering.
  ///
  /// - Parameter desired: The desired new value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func store(
    _ desired: consuming Value,
    ordering: AtomicStoreOrdering
  ) {
    _Storage.atomicStore(desired, at: _value.address, ordering: ordering)
  }

  /// Atomically sets the current value to `desired` and returns the original
  /// value, applying the specified memory ordering.
  ///
  /// - Parameter desired: The desired new value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func exchange(
    _ desired: consuming Value,
    ordering: AtomicUpdateOrdering
  ) -> Value {
    _Storage.atomicExchange(desired, at: _value.address, ordering: ordering)
  }

  /// Perform an atomic compare and exchange operation on the current value,
  /// applying the specified memory ordering.
  ///
  /// This operation performs the following algorithm as a single atomic
  /// transaction:
  ///
  /// ```
  /// atomic(self) { currentValue in
  ///   let original = currentValue
  ///   guard original == expected else { return (false, original) }
  ///   currentValue = desired
  ///   return (true, original)
  /// }
  /// ```
  ///
  /// This method implements a "strong" compare and exchange operation
  /// that does not permit spurious failures.
  ///
  /// - Parameter expected: The expected current value.
  /// - Parameter desired: The desired new value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: A tuple `(exchanged, original)`, where `exchanged` is true if
  ///   the exchange was successful, and `original` is the original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func compareExchange(
    expected: Value,
    desired: consuming Value,
    ordering: AtomicUpdateOrdering
  ) -> (exchanged: Bool, original: Value) {
    _Storage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _value.address,
      ordering: ordering)
  }

  /// Perform an atomic compare and exchange operation on the current value,
  /// applying the specified success/failure memory orderings.
  ///
  /// This operation performs the following algorithm as a single atomic
  /// transaction:
  ///
  /// ```
  /// atomic(self) { currentValue in
  ///   let original = currentValue
  ///   guard original == expected else { return (false, original) }
  ///   currentValue = desired
  ///   return (true, original)
  /// }
  /// ```
  ///
  /// The `successOrdering` argument specifies the memory ordering to use when
  /// the operation manages to update the current value, while `failureOrdering`
  /// will be used when the operation leaves the value intact.
  ///
  /// This method implements a "strong" compare and exchange operation
  /// that does not permit spurious failures.
  ///
  /// - Parameter expected: The expected current value.
  /// - Parameter desired: The desired new value.
  /// - Parameter successOrdering: The memory ordering to apply if this
  ///    operation performs the exchange.
  /// - Parameter failureOrdering: The memory ordering to apply on this
  ///    operation does not perform the exchange.
  /// - Returns: A tuple `(exchanged, original)`, where `exchanged` is true if
  ///   the exchange was successful, and `original` is the original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func compareExchange(
    expected: Value,
    desired: consuming Value,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Value) {
    _Storage.atomicCompareExchange(
      expected: expected,
      desired: desired,
      at: _value.address,
      successOrdering: successOrdering,
      failureOrdering: failureOrdering)
  }

  /// Perform an atomic weak compare and exchange operation on the current
  /// value, applying the memory ordering. This compare-exchange variant is
  /// allowed to spuriously fail; it is designed to be called in a loop until
  /// it indicates a successful exchange has happened.
  ///
  /// This operation performs the following algorithm as a single atomic
  /// transaction:
  ///
  /// ```
  /// atomic(self) { currentValue in
  ///   let original = currentValue
  ///   guard original == expected else { return (false, original) }
  ///   currentValue = desired
  ///   return (true, original)
  /// }
  /// ```
  ///
  /// (In this weak form, transient conditions may cause the `original ==
  /// expected` check to sometimes return false when the two values are in fact
  /// the same.)
  ///
  /// - Parameter expected: The expected current value.
  /// - Parameter desired: The desired new value.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: A tuple `(exchanged, original)`, where `exchanged` is true if
  ///   the exchange was successful, and `original` is the original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func weakCompareExchange(
    expected: Value,
    desired: consuming Value,
    ordering: AtomicUpdateOrdering
  ) -> (exchanged: Bool, original: Value) {
    _Storage.atomicWeakCompareExchange(
      expected: expected,
      desired: desired,
      at: _value.address,
      ordering: ordering)
  }

  /// Perform an atomic weak compare and exchange operation on the current
  /// value, applying the specified success/failure memory orderings. This
  /// compare-exchange variant is allowed to spuriously fail; it is designed to
  /// be called in a loop until it indicates a successful exchange has happened.
  ///
  /// This operation performs the following algorithm as a single atomic
  /// transaction:
  ///
  /// ```
  /// atomic(self) { currentValue in
  ///   let original = currentValue
  ///   guard original == expected else { return (false, original) }
  ///   currentValue = desired
  ///   return (true, original)
  /// }
  /// ```
  ///
  /// (In this weak form, transient conditions may cause the `original ==
  /// expected` check to sometimes return false when the two values are in fact
  /// the same.)
  ///
  /// The `ordering` argument specifies the memory ordering to use when the
  /// operation manages to update the current value, while `failureOrdering`
  /// will be used when the operation leaves the value intact.
  ///
  /// - Parameter expected: The expected current value.
  /// - Parameter desired: The desired new value.
  /// - Parameter successOrdering: The memory ordering to apply if this
  ///    operation performs the exchange.
  /// - Parameter failureOrdering: The memory ordering to apply on this
  ///    operation does not perform the exchange.
  /// - Returns: A tuple `(exchanged, original)`, where `exchanged` is true if
  ///   the exchange was successful, and `original` is the original value.
  @_semantics("atomics.requires_constant_orderings")
  @_transparent @_alwaysEmitIntoClient
  public func weakCompareExchange(
    expected: Value,
    desired: consuming Value,
    successOrdering: AtomicUpdateOrdering,
    failureOrdering: AtomicLoadOrdering
  ) -> (exchanged: Bool, original: Value) {
    _Storage.atomicWeakCompareExchange(
      expected: expected,
      desired: desired,
      at: _value.address,
      successOrdering: successOrdering,
      failureOrdering: failureOrdering)
  }
}

/// A type that supports atomic integer operations through a separate
/// atomic storage representation.
///
/// Atomic integer types provide a number of additional atomic
/// operations beyond the ones supported by `AtomicValue`, such as
/// atomic increments/decrements as well as atomic bitwise operations.
/// These may be mapped to dedicated instructions that can be more
/// efficient than implementations based on the general compare and
/// exchange operation; however, this depends on the capabilities of
/// the compiler and the underlying hardware.
public protocol AtomicInteger: AtomicValue, FixedWidthInteger
where
  AtomicRepresentation: AtomicIntegerStorage,
  AtomicRepresentation.Value == Self
{}

/// The storage representation for an atomic integer value, providing
/// pointer-based atomic operations.
///
/// This is a low-level implementation detail of atomic types; instead
/// of directly handling conforming types, it is usually better to use
/// the `UnsafeAtomic` or `ManagedAtomic` generics -- these provide a
/// more reliable interface while ensuring that the storage is
/// correctly constructed and destroyed.
public protocol AtomicIntegerStorage: AtomicStorage {
  /// Perform an atomic wrapping increment operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&+=` operator does on integer values.
  ///
  /// - Parameter operand: The value to add to the current value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenWrappingIncrement(
    by operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value

  /// Perform an atomic wrapping decrement operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// Note: This operation silently wraps around on overflow, like the
  /// `&-=` operator does on integer values.
  ///
  /// - Parameter operand: The value to subtract from the current value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenWrappingDecrement(
    by operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value

  /// Perform an atomic bitwise AND operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenBitwiseAnd(
    with operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value

  /// Perform an atomic bitwise OR operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenBitwiseOr(
    with operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value

  /// Perform an atomic bitwise XOR operation on the value referenced by
  /// `pointer` and return the original value, applying the specified memory
  /// ordering.
  ///
  /// - Parameter operand: An integer value.
  /// - Parameter pointer: A memory location previously initialized with a value
  ///   returned by `prepareAtomicRepresentation(for:)`.
  /// - Parameter ordering: The memory ordering to apply on this operation.
  /// - Returns: The original value before the operation.
  @_semantics("atomics.requires_constant_orderings")
  static func atomicLoadThenBitwiseXor(
    with operand: Value,
    at pointer: UnsafeMutablePointer<Self>,
    ordering: AtomicUpdateOrdering
  ) -> Value
}
