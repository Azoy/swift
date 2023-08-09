//===--- Submodules.cpp - Handles creation of submodules ------------------===//
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
//
// This file implements the handling of parsing source files in the main module
// and creates new submodules for files with 'submodule X' in them.
//
//===----------------------------------------------------------------------===//

#include "swift/AST/DiagnosticsSema.h"
#include "swift/AST/SourceFile.h"
#include "swift/Subsystems.h"
#include "llvm/ADT/StringMap.h"

using namespace swift;

void swift::performSubmoduleCreation(ModuleDecl *module) {
  auto &ctx = module->getASTContext();

  llvm::StringMap<ModuleDecl *> submoduleMap;
  SmallVector<FileUnit *> mainModuleFiles;

  for (auto file : module->getFiles()) {
    bool isSubmoduleFile = false;

    SmallVector<Decl *> topLevelDecls;
    file->getTopLevelDecls(topLevelDecls);

    for (auto i : indices(topLevelDecls)) {
      auto submoduleDecl = dyn_cast<SubmoduleDecl>(topLevelDecls[i]);

      if (!submoduleDecl) {
        continue;
      }

      // Submodule decls can only appear at the beginning of a file unit.
      if (i != 0) {
        submoduleDecl->diagnose(diag::submodule_not_at_top);
        return;
      }

      isSubmoduleFile = true;

      // Check if we've already created this module, and if we have add this
      // file.
      auto entry = submoduleMap.find(submoduleDecl->getName().str());
      if (entry != submoduleMap.end()) {
        entry->getValue()->addFile(*file);
        break;
      }

      // Otherwise, this is a new submodule.
      auto submodule = ModuleDecl::create(submoduleDecl->getName(), ctx,
                                          module->getImplicitImportInfo());

      submodule->setParent(module);
      submodule->setResilienceStrategy(module->getResilienceStrategy());
      submodule->addFile(*file);
      file->setParent(submodule);

      submoduleMap[submoduleDecl->getName().str()] = submodule;
      module->addSubmodule(submodule);
      continue;
    }

    // If we didn't create a submodule from this file, append it to this
    // module's list of files.
    if (!isSubmoduleFile) {
      mainModuleFiles.push_back(file);
    }
  }

  module->removeFiles();

  // Add all of the non-submodule defining files back to this module.
  for (auto mainModuleFile : mainModuleFiles) {
    module->addFile(*mainModuleFile);
  }
}
