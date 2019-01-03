//===------------- AsmParserCallback.cpp ----------------------------------===//
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

#include "AsmParserCallback.h"
#include "swift/AST/DiagnosticsParse.h"
#include "swift/AST/DiagnosticsSema.h"

using namespace swift;

bool AsmParserCallback::LookupInlineAsmField(StringRef Base, StringRef Member,
                          unsigned &Offset) {
  return false;
}

void AsmParserCallback::LookupInlineAsmIdentifier(StringRef &LineBuf,
                               llvm::InlineAsmIdentifierInfo &Info,
                               bool IsUnevaluatedContext) {
  SmallVector<Token, 16> lineToks;
  const Token *firstTok = nullptr;
  unsigned firstTokIndex = 0;
  findTokensForString(LineBuf, lineToks, firstTok, firstTokIndex);
  
  unsigned toksConsumed = 0;
  auto expr = parseIdentifier(lineToks, firstTok, toksConsumed);
  
  // If we consumed any tokens (besides the whole line), consume them in linebuf
  if (toksConsumed > 0 && toksConsumed < lineToks.size()) {
    unsigned lastIndex = firstTokIndex + toksConsumed - 1;
    
    unsigned totalOffset = TokOffsets[lastIndex] +
                           Toks[lastIndex].getLength() -
                           TokOffsets[firstTokIndex];
    LineBuf = LineBuf.substr(0, totalOffset);
  }

  if (!expr)
    return;

  TC.fillAsmIdentifierInfo(expr, Info);
}

StringRef AsmParserCallback::LookupInlineAsmLabel(StringRef Identifier,
                                                  llvm::SourceMgr &SM,
                                                  llvm::SMLoc Location,
                                                  bool Create) {
  return "";
}

void AsmParserCallback::findTokensForString(StringRef str,
                                            SmallVectorImpl<Token> &tmpToks,
                                            const Token *&firstTok,
                                            unsigned &firstTokIndex) const {
  assert(!std::less<const char *>()(str.begin(), AsmString.begin()) &&
         !std::less<const char *>()(AsmString.end(), str.end()));
         
  unsigned firstCharOffset = str.begin() - AsmString.begin();
  const unsigned *firstTokOffset = std::lower_bound(TokOffsets.begin(),
                                                    TokOffsets.end(),
                                                    firstCharOffset);

  assert(*firstTokOffset == firstCharOffset);

  firstTokIndex = firstTokOffset - TokOffsets.begin();
  firstTok = &Toks[firstTokIndex];
  unsigned lastCharOffset = str.end() - AsmString.begin();
  for (unsigned i = firstTokIndex; i != TokOffsets.size(); i++) {
    if (TokOffsets[i] >= lastCharOffset)
      break;
    tmpToks.push_back(Toks[i]);
  }
}

Expr *AsmParserCallback::parseIdentifier(ArrayRef<Token> lineToks,
                                         const Token *&firstTok,
                                         unsigned &toksConsumed) {
  DeclName name = TC.Context.getIdentifier(firstTok->getText());
  DeclNameLoc nameLoc(firstTok->getLoc());
  Expr *result = new (TC.Context) UnresolvedDeclRefExpr(name,
                                                        DeclRefKind::Ordinary,
                                                        nameLoc);
  auto tmpLineToks = lineToks.drop_front();

  SWIFT_DEFER {
    // Figure out how much of the line we consumed.
    if (tmpLineToks.empty()) {
      toksConsumed = lineToks.size();
    } else {
      for (auto tok : lineToks) {
        if (tok.getLoc() != tmpLineToks[0].getLoc()) {
          toksConsumed += 1;
        } else {
          break;
        }
      }
    }
  };

  TC.typeCheckExpression(result, DC, nullptr);

  // If this is the only token, we're done.
  if (lineToks.size() == 1) {
    return result;
  }

  // If the next token is not a '.' for a member, we're done. (We just checked
  // lineToks' size, so it is safe to access the second element).
  if (lineToks[1].isNot(tok::period)) {
    return result;
  }
  
  while (tmpLineToks[0].is(tok::period)) {
    unsigned lineSize = tmpLineToks.size();

    // If next token is a '.', but theres nothing after it, diagnose extra '.'
    if (lineSize < 2 || tmpLineToks[1].isNot(tok::identifier)) {
      TC.diagnose(tmpLineToks.front().getLoc(), diag::expected_member_name);
      break;
    }

    DeclName name = TC.Context.getIdentifier(tmpLineToks[1].getText());
    DeclNameLoc nameLoc(tmpLineToks[1].getLoc());
    result = new (TC.Context) UnresolvedDotExpr(result, tmpLineToks[0].getLoc(),
                                                name, nameLoc,
                                                /*implicit*/ false);
    tmpLineToks = tmpLineToks.drop_front(2);
    
    if (tmpLineToks.size() < 2)
      break;
  }
  
  TC.typeCheckExpression(result, DC, nullptr);
  
  return result;
}

SourceLoc AsmParserCallback::translateLocation(const llvm::SourceMgr &SM,
                                               llvm::SMLoc SMLoc) {
  const llvm::MemoryBuffer *buf = 
      SM.getMemoryBuffer(SM.FindBufferContainingLoc(SMLoc));
  unsigned offset = SMLoc.getPointer() - buf->getBufferStart();
  
  const unsigned *tokOffsetPtr = std::lower_bound(TokOffsets.begin(),
                                                  TokOffsets.end(), offset);
  unsigned tokIndex = tokOffsetPtr - TokOffsets.begin();
  unsigned tokOffset = *tokOffsetPtr;
  
  SourceLoc loc = Loc;
  if (tokIndex < Toks.size()) {
    const Token &tok = Toks[tokIndex];
    loc = tok.getLoc();
    loc = loc.getAdvancedLoc(offset - tokOffset);
  }
  
  return loc;
}

void AsmParserCallback::handleDiagnostic(const llvm::SMDiagnostic &D) {
  const llvm::SourceMgr &SM = *D.getSourceMgr();
  SourceLoc loc = translateLocation(SM, D.getLoc());
  TC.diagnose(loc, diag::asm_parsing_failed, D.getMessage());
}
