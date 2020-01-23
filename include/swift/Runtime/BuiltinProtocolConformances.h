//===--- BuiltinProtocolWitnessTable.h --------------------------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2020 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
//
// Swift runtime support for builtin protocol witnesses and related items.
//
//===----------------------------------------------------------------------===//

#include "swift/ABI/Metadata.h"

namespace swift {

// public protocol Equatable {}
#define SWIFT_EQUATABLE_MANGLING SQ
// public protocol Comparable: Equatable {}
#define SWIFT_COMPARABLE_MANGLING SL
// public protocol Hashable: Equatable {}
#define SWIFT_HASHABLE_MANGLING SH

// == infix(T, T) -> Swift.Bool
#define SWIFT_EQUAL_OPERATOR_MANGLING 2eeoiySbx_xtFZ
// < infix(T, T) -> Swift.Bool
#define SWIFT_LT_OPERATOR_MANGLING 1loiySbx_xtFZ

// (A...)
#define VARIADIC_TUPLE_MANGLING xd_t

#define PROTOCOL_DESCRIPTOR_MANGLING Mp
#define BUILTIN_PROTOCOL_WITNESS_TABLE_MANGLING WB
#define BUILTIN_PROTOCOL_WITNESS_MANGLING TB
#define BUILTIN_PROTOCOL_CONFORMANCE_DESCRIPTOR_MANGLING Mb

#define PROTOCOL_DESCRIPTOR_SYM(Proto) \
          MANGLE_SYM(MANGLING_CONCAT2(Proto, PROTOCOL_DESCRIPTOR_MANGLING))

// Note: This is currently only used for conformances found within Swift.
//       (Hence the s module)
#define BUILTIN_PROTOCOL_WITNESS_TABLE_SYM(Ty, Proto) \
          MANGLE_SYM(MANGLING_CONCAT3(Ty, \
                                      MANGLING_CONCAT2(Proto, s), \
                                      BUILTIN_PROTOCOL_WITNESS_TABLE_MANGLING))

// Note: This is currently only used for conformances found within Swift.
//       (Hence the s module)
#define BUILTIN_PROTOCOL_WITNESS_SYM(Ty, Proto, Func) \
          MANGLE_SYM(MANGLING_CONCAT2(_PROTOCOL_CONFORMANCE_SYM(Ty, Proto, s), \
                                      MANGLING_CONCAT3(Proto, Func, \
                                        BUILTIN_PROTOCOL_WITNESS_MANGLING)))

#define _PROTOCOL_CONFORMANCE_SYM(Ty, Proto, Mod) \
          MANGLING_CONCAT3(Ty, Proto, Mod)

// Note: This is currently only used for conformances found within Swift.
//       (Hence the s module)
#define BUILTIN_PROTOCOL_CONFORMANCE_DESCRIPTOR_SYM(Ty, Proto) \
          MANGLE_SYM(MANGLING_CONCAT2(_PROTOCOL_CONFORMANCE_SYM(Ty, Proto, s), \
                              BUILTIN_PROTOCOL_CONFORMANCE_DESCRIPTOR_MANGLING))

template<unsigned int NumWitnesses>
struct _WitnessTable {
  const ProtocolConformanceDescriptor *Conformance;
  const void *Witnesses[NumWitnesses];
};

template<unsigned int NumTables, unsigned int NumWitnesses>
struct _DependentWitnessTable {
  const ProtocolConformanceDescriptor *Conformance;
  const WitnessTable *Tables[NumTables];
  const void *Witnesses[NumWitnesses];
};

/// The builtin protocol conformance witness table for (A...) : Swift.Equatable
// in Swift.
SWIFT_RUNTIME_EXPORT
const _WitnessTable<1>
BUILTIN_PROTOCOL_WITNESS_TABLE_SYM(VARIADIC_TUPLE_MANGLING,
                                   SWIFT_EQUATABLE_MANGLING);

/// The protocol witness for static Swift.Equatable.== infix(A, A) -> Swift.Bool
/// in conformance (A...): Swift.Equatable in Swift.
SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
bool BUILTIN_PROTOCOL_WITNESS_SYM(VARIADIC_TUPLE_MANGLING,
                                  SWIFT_EQUATABLE_MANGLING,
                                  SWIFT_EQUAL_OPERATOR_MANGLING)
(OpaqueValue *tuple1, OpaqueValue *tuple2, SWIFT_CONTEXT Metadata *swiftSelf,
 Metadata *Self, void *witnessTable);

/// The builtin protocol conformance witness table for (A...) : Swift.Comparable
/// in Swift.
SWIFT_RUNTIME_EXPORT
const _DependentWitnessTable<1, 4>
BUILTIN_PROTOCOL_WITNESS_TABLE_SYM(VARIADIC_TUPLE_MANGLING,
                                   SWIFT_COMPARABLE_MANGLING);

/// The protocol witness for static Swift.Comparable.< infix(A, A) -> Swift.Bool
/// in conformance (A...): Swift.Comparable in Swift.
SWIFT_RUNTIME_EXPORT SWIFT_CC(swift)
bool BUILTIN_PROTOCOL_WITNESS_SYM(VARIADIC_TUPLE_MANGLING,
                                  SWIFT_COMPARABLE_MANGLING,
                                  SWIFT_LT_OPERATOR_MANGLING)
(OpaqueValue *tuple1, OpaqueValue *tuple2, SWIFT_CONTEXT Metadata *swiftSelf,
 Metadata *Self, void *witnessTable);

} // end namespace swift
