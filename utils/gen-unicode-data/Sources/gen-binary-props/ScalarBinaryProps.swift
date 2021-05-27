//===----------------------------------------------------------------------===//
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

struct ScalarBinaryProps: OptionSet {
  let rawValue: UInt64
  
  static let changesWhenCaseFolded       = ScalarBinaryProps(rawValue: 1 << 0)
  static let changesWhenCaseMapped       = ScalarBinaryProps(rawValue: 1 << 1)
  static let changesWhenLowercased       = ScalarBinaryProps(rawValue: 1 << 2)
  static let changesWhenNFKCCaseFolded   = ScalarBinaryProps(rawValue: 1 << 3)
  static let changesWhenTitlecased       = ScalarBinaryProps(rawValue: 1 << 4)
  static let changesWhenUppercased       = ScalarBinaryProps(rawValue: 1 << 5)
  static let isASCIIHexDigit             = ScalarBinaryProps(rawValue: 1 << 6)
  static let isAlphabetic                = ScalarBinaryProps(rawValue: 1 << 7)
  static let isBidiControl               = ScalarBinaryProps(rawValue: 1 << 8)
  static let isBidiMirrored              = ScalarBinaryProps(rawValue: 1 << 9)
  static let isCaseIgnorable             = ScalarBinaryProps(rawValue: 1 << 10)
  static let isCased                     = ScalarBinaryProps(rawValue: 1 << 11)
  static let isDash                      = ScalarBinaryProps(rawValue: 1 << 12)
  static let isDefaultIgnorableCodePoint = ScalarBinaryProps(rawValue: 1 << 13)
  static let isDeprecated                = ScalarBinaryProps(rawValue: 1 << 14)
  static let isDiacritic                 = ScalarBinaryProps(rawValue: 1 << 15)
  static let isEmoji                     = ScalarBinaryProps(rawValue: 1 << 16)
  static let isEmojiModifier             = ScalarBinaryProps(rawValue: 1 << 17)
  static let isEmojiModifierBase         = ScalarBinaryProps(rawValue: 1 << 18)
  static let isEmojiPresentation         = ScalarBinaryProps(rawValue: 1 << 19)
  static let isExtender                  = ScalarBinaryProps(rawValue: 1 << 20)
  static let isFullCompositionExclusion  = ScalarBinaryProps(rawValue: 1 << 21)
  static let isGraphemeBase              = ScalarBinaryProps(rawValue: 1 << 22)
  static let isGraphemeExtend            = ScalarBinaryProps(rawValue: 1 << 23)
  static let isHexDigit                  = ScalarBinaryProps(rawValue: 1 << 24)
  static let isIDContinue                = ScalarBinaryProps(rawValue: 1 << 25)
  static let isIDSBinaryOperator         = ScalarBinaryProps(rawValue: 1 << 26)
  static let isIDSTrinaryOperator        = ScalarBinaryProps(rawValue: 1 << 27)
  static let isIDStart                   = ScalarBinaryProps(rawValue: 1 << 28)
  static let isIdeographic               = ScalarBinaryProps(rawValue: 1 << 29)
  static let isJoinControl               = ScalarBinaryProps(rawValue: 1 << 30)
  static let isLogicalOrderException     = ScalarBinaryProps(rawValue: 1 << 31)
  static let isLowercase                 = ScalarBinaryProps(rawValue: 1 << 32)
  static let isMath                      = ScalarBinaryProps(rawValue: 1 << 33)
  static let isNoncharacterCodePoint     = ScalarBinaryProps(rawValue: 1 << 34)
  static let isPatternSyntax             = ScalarBinaryProps(rawValue: 1 << 35)
  static let isPatternWhitespace         = ScalarBinaryProps(rawValue: 1 << 36)
  static let isQuotationMark             = ScalarBinaryProps(rawValue: 1 << 37)
  static let isRadical                   = ScalarBinaryProps(rawValue: 1 << 38)
  static let isSentenceTerminal          = ScalarBinaryProps(rawValue: 1 << 39)
  static let isSoftDotted                = ScalarBinaryProps(rawValue: 1 << 40)
  static let isTerminalPunctuation       = ScalarBinaryProps(rawValue: 1 << 41)
  static let isUnifiedIdeograph          = ScalarBinaryProps(rawValue: 1 << 42)
  static let isUppercase                 = ScalarBinaryProps(rawValue: 1 << 43)
  static let isVariationSelector         = ScalarBinaryProps(rawValue: 1 << 44)
  static let isWhitespace                = ScalarBinaryProps(rawValue: 1 << 45)
  static let isXIDContinue               = ScalarBinaryProps(rawValue: 1 << 46)
  static let isXIDStart                  = ScalarBinaryProps(rawValue: 1 << 47)
}

extension ScalarBinaryProps: Hashable {}

func getScalarBinaryProps(for scalar: Unicode.Scalar) -> ScalarBinaryProps {
  var binaryProps: ScalarBinaryProps = []

  if scalar.properties.changesWhenCaseFolded {
    binaryProps.insert(.changesWhenCaseFolded)
  }
  if scalar.properties.changesWhenCaseMapped {
    binaryProps.insert(.changesWhenCaseMapped)
  }
  if scalar.properties.changesWhenLowercased {
    binaryProps.insert(.changesWhenLowercased)
  }
  if scalar.properties.changesWhenNFKCCaseFolded {
    binaryProps.insert(.changesWhenNFKCCaseFolded)
  }
  if scalar.properties.changesWhenTitlecased {
    binaryProps.insert(.changesWhenTitlecased)
  }
  if scalar.properties.changesWhenUppercased {
    binaryProps.insert(.changesWhenUppercased)
  }
  if scalar.properties.isASCIIHexDigit {
    binaryProps.insert(.isASCIIHexDigit)
  }
  if scalar.properties.isAlphabetic {
    binaryProps.insert(.isAlphabetic)
  }
  if scalar.properties.isBidiControl {
    binaryProps.insert(.isBidiControl)
  }
  if scalar.properties.isBidiMirrored {
    binaryProps.insert(.isBidiMirrored)
  }
  if scalar.properties.isCaseIgnorable {
    binaryProps.insert(.isCaseIgnorable)
  }
  if scalar.properties.isCased {
    binaryProps.insert(.isCased)
  }
  if scalar.properties.isDash {
    binaryProps.insert(.isDash)
  }
  if scalar.properties.isDefaultIgnorableCodePoint {
    binaryProps.insert(.isDefaultIgnorableCodePoint)
  }
  if scalar.properties.isDeprecated {
    binaryProps.insert(.isDeprecated)
  }
  if scalar.properties.isDiacritic {
    binaryProps.insert(.isDiacritic)
  }
  if scalar.properties.isEmoji {
    binaryProps.insert(.isEmoji)
  }
  if scalar.properties.isEmojiModifier {
    binaryProps.insert(.isEmojiModifier)
  }
  if scalar.properties.isEmojiModifierBase {
    binaryProps.insert(.isEmojiModifierBase)
  }
  if scalar.properties.isEmojiPresentation {
    binaryProps.insert(.isEmojiPresentation)
  }
  if scalar.properties.isExtender {
    binaryProps.insert(.isExtender)
  }
  if scalar.properties.isFullCompositionExclusion {
    binaryProps.insert(.isFullCompositionExclusion)
  }
  if scalar.properties.isGraphemeBase {
    binaryProps.insert(.isGraphemeBase)
  }
  if scalar.properties.isGraphemeExtend {
    binaryProps.insert(.isGraphemeExtend)
  }
  if scalar.properties.isHexDigit {
    binaryProps.insert(.isHexDigit)
  }
  if scalar.properties.isIDContinue {
    binaryProps.insert(.isIDContinue)
  }
  if scalar.properties.isIDSBinaryOperator {
    binaryProps.insert(.isIDSBinaryOperator)
  }
  if scalar.properties.isIDSTrinaryOperator {
    binaryProps.insert(.isIDSTrinaryOperator)
  }
  if scalar.properties.isIDStart {
    binaryProps.insert(.isIDStart)
  }
  if scalar.properties.isIdeographic {
    binaryProps.insert(.isIdeographic)
  }
  if scalar.properties.isJoinControl {
    binaryProps.insert(.isJoinControl)
  }
  if scalar.properties.isLogicalOrderException {
    binaryProps.insert(.isLogicalOrderException)
  }
  if scalar.properties.isLowercase {
    binaryProps.insert(.isLowercase)
  }
  if scalar.properties.isMath {
    binaryProps.insert(.isMath)
  }
  if scalar.properties.isNoncharacterCodePoint {
    binaryProps.insert(.isNoncharacterCodePoint)
  }
  if scalar.properties.isPatternSyntax {
    binaryProps.insert(.isPatternSyntax)
  }
  if scalar.properties.isPatternWhitespace {
    binaryProps.insert(.isPatternWhitespace)
  }
  if scalar.properties.isQuotationMark {
    binaryProps.insert(.isQuotationMark)
  }
  if scalar.properties.isRadical {
    binaryProps.insert(.isRadical)
  }
  if scalar.properties.isSentenceTerminal {
    binaryProps.insert(.isSentenceTerminal)
  }
  if scalar.properties.isSoftDotted {
    binaryProps.insert(.isSoftDotted)
  }
  if scalar.properties.isTerminalPunctuation {
    binaryProps.insert(.isTerminalPunctuation)
  }
  if scalar.properties.isUnifiedIdeograph {
    binaryProps.insert(.isUnifiedIdeograph)
  }
  if scalar.properties.isUppercase {
    binaryProps.insert(.isUppercase)
  }
  if scalar.properties.isVariationSelector {
    binaryProps.insert(.isVariationSelector)
  }
  if scalar.properties.isWhitespace {
    binaryProps.insert(.isWhitespace)
  }
  if scalar.properties.isXIDContinue {
    binaryProps.insert(.isXIDContinue)
  }
  if scalar.properties.isXIDStart {
    binaryProps.insert(.isXIDStart)
  }

  return binaryProps
}
