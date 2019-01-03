//===------------- TypeCheckAsm.cpp ---------------------------------------===//
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
#include "llvm/IR/InlineAsm.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCObjectFileInfo.h"
#include "llvm/MC/MCParser/MCAsmParser.h"
#include "llvm/MC/MCParser/MCTargetAsmParser.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Support/TargetSelect.h"

using namespace swift;

// Get a list of CPU features as a string
static std::string getCPUFeatures() {
  llvm::SubtargetFeatures subtargetFeatures;
  llvm::StringMap<bool> hostFeatures;
  
  if (llvm::sys::getHostCPUFeatures(hostFeatures))
    for (auto &F : hostFeatures)
      subtargetFeatures.AddFeature(F.first(), F.second);
      
  return subtargetFeatures.getString();
}

// Open up an MCAsmParser to parse the asm string
bool TypeChecker::parseAsmString(AsmStmt *AS, AsmParserCallback *callback,
                          unsigned &OutputCount,
                          unsigned &InputCount, std::string &AsmStringIr,
                          SmallVectorImpl<std::string> &Constraints,
                          SmallVectorImpl<std::string> &Clobbers,
                          SmallVectorImpl<std::pair<void *, bool>> &Exprs) {
  const auto &targetTriple = Context.LangOpts.Target;
  const auto &triple = targetTriple.getTriple();
  const llvm::Target *target = nullptr;

  std::string error;
  target = llvm::TargetRegistry::lookupTarget(triple, error);

  if (!target) {
    diagnose(AS->getLoc(), diag::asm_target_lookup_failed, triple);
    return true;
  }

  std::unique_ptr<llvm::MCRegisterInfo> MRI(target->createMCRegInfo(triple));
  std::unique_ptr<llvm::MCAsmInfo> MAI(target->createMCAsmInfo(*MRI, triple));
  std::unique_ptr<llvm::MCInstrInfo> MII(target->createMCInstrInfo());
  auto MOFI = llvm::make_unique<llvm::MCObjectFileInfo>();

  StringRef CPU = llvm::sys::getHostCPUName();
  std::string features = getCPUFeatures();

  std::unique_ptr<llvm::MCSubtargetInfo> STI(
    target->createMCSubtargetInfo(triple, CPU, features));

  llvm::SourceMgr tmpSrcMgr;
  llvm::MCContext MC(MAI.get(), MRI.get(), MOFI.get(), &tmpSrcMgr);
  MOFI->InitMCObjectFileInfo(targetTriple, false, MC);
  std::unique_ptr<llvm::MemoryBuffer> buffer = 
    llvm::MemoryBuffer::getMemBuffer(AS->getAsmString(), "<inline asm>");

  tmpSrcMgr.AddNewSourceBuffer(std::move(buffer), llvm::SMLoc());

  std::unique_ptr<llvm::MCStreamer> MStr(createNullStreamer(MC));
  std::unique_ptr<llvm::MCAsmParser> MParser(
    createMCAsmParser(tmpSrcMgr, MC, *MStr.get(), *MAI));

  llvm::MCTargetOptions MOptions;
  std::unique_ptr<llvm::MCTargetAsmParser> MTargetParser(
    target->createMCAsmParser(*STI, *MParser, *MII, MOptions));

  std::unique_ptr<llvm::MCInstPrinter> MIP(
    target->createMCInstPrinter(targetTriple, 1, *MAI, *MII, *MRI));

  MParser->setAssemblerDialect(llvm::InlineAsm::AsmDialect::AD_Intel);
  MParser->setTargetParser(*MTargetParser.get());
  MParser->setParsingInlineAsm(true);
  MTargetParser->setParsingInlineAsm(true);

  MTargetParser->setSemaCallback(callback);
  tmpSrcMgr.setDiagHandler(AsmParserCallback::DiagHandlerCallback, callback);

  auto tmpAsmLoc = const_cast<void *>(AS->getLoc().getOpaquePointerValue());

  MParser->parseMSInlineAsm(tmpAsmLoc, AsmStringIr, OutputCount, InputCount,
                            Exprs, Constraints, Clobbers, MII.get(),
                            MIP.get(), *callback);
  return false;
}

void TypeChecker::fillAsmIdentifierInfo(Expr *result,
                                        llvm::InlineAsmIdentifierInfo &info) {
  info.setVar(result, true, 8, 8);
  // If this is a declref to a variable, check if its an integer variable
  /*
  if (auto declRef = dyn_cast<DeclRefExpr>(result)) {
    auto decl = declRef->getDecl();
    assert(decl->getType() && "asm expr decl should be type checked by now");
    if (decl->getType())
  }
  */
}
