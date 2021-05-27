//===--- UnicodeProperties.h - Defines the binary prop data -----*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2021 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#ifndef SWIFT_STDLIB_SHIMS_UNICODEPROPERTIES_H
#define SWIFT_STDLIB_SHIMS_UNICODEPROPERTIES_H

#include "SwiftStdbool.h"
#include "SwiftStdint.h"
#include "Visibility.h"

#ifdef __cplusplus
extern "C" {
#endif

SWIFT_RUNTIME_STDLIB_API
__swift_bool _swift_stdlib_scalar_hasBinaryProperty(__swift_uint32_t scalar,
                                                __swift_uint64_t propertyMask);

#ifdef __cplusplus
} // extern "C"
#endif

#endif // SWIFT_STDLIB_SHIMS_UNICODEPROPERTIES_H
