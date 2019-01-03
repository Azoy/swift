//===-------------- AsmParserCallback.h -------------------------*- C++ -*-===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2018 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#ifndef ASM_PARSER_CALLBACK_H
#define ASM_PARSER_CALLBACK_H

#include "TypeChecker.h"
#include "swift/AST/Expr.h"
#include "swift/Parse/Token.h"
#include "llvm/MC/MCParser/MCAsmParser.h"
#include "llvm/Support/SourceMgr.h"

namespace swift {

class TypeChecker;

// This is called when we start parsing the asm during sema. We don't parse the
// asm during parsing because we need the type checker to validate expressions
// within the asm.
class AsmParserCallback : public llvm::MCAsmParserSemaCallback {
protected:
  TypeChecker &TC;
  DeclContext *DC;
  SourceLoc Loc;
  StringRef AsmString;
  ArrayRef<Token> Toks;
  ArrayRef<unsigned> TokOffsets;
  
public:
  AsmParserCallback(TypeChecker &TC, DeclContext *DC, SourceLoc loc,
                    StringRef asmString, ArrayRef<Token> toks,
                    ArrayRef<unsigned> tokOffsets) 
      : TC(TC), DC(DC), Loc(loc), AsmString(asmString), Toks(toks),
        TokOffsets(tokOffsets) {
    assert(toks.size() == tokOffsets.size());
  };
  
  bool LookupInlineAsmField(StringRef Base, StringRef Member,
                            unsigned &Offset) override;
  
  void LookupInlineAsmIdentifier(StringRef &LineBuf,
                                 llvm::InlineAsmIdentifierInfo &Info,
                                 bool IsUnevaluatedContext) override;
                                 
  StringRef LookupInlineAsmLabel(StringRef Identifier, llvm::SourceMgr &SM,
                                 llvm::SMLoc Location, bool Create) override;
                                 
  static void DiagHandlerCallback(const llvm::SMDiagnostic &D, void *Context) {
    static_cast<AsmParserCallback *>(Context)->handleDiagnostic(D);
  }
  
private:
  void findTokensForString(StringRef str, SmallVectorImpl<Token> &tmpToks,
                           const Token *&firstTok,
                           unsigned &firstTokIndex) const;

  Expr *parseIdentifier(ArrayRef<Token> lineToks,
                        const Token *&firstTok,
                        unsigned &toksConsumed);

  SourceLoc translateLocation(const llvm::SourceMgr &SM, llvm::SMLoc Loc);

  void handleDiagnostic(const llvm::SMDiagnostic &D);
};

}

#endif
