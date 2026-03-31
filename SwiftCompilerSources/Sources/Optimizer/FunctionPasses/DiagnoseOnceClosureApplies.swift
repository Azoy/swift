//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import SIL

let diagnoseOnceClosureApplies = FunctionPass(name: "diagnose-once-closure-applies") {
  (function: Function, context: FunctionPassContext) in

  var onceClosures = ValueWorklist(context)
  defer { onceClosures.deinitialize() }

  for arg in function.arguments {
    if arg.type.isOnceFunction {
      onceClosures.pushIfNotVisited(arg)
    }
  }

  guard !onceClosures.isEmpty else {
    return
  }

  while let onceClosure = onceClosures.pop() {
    var walker = OnceClosureArgumentWalker()

    if walker.isAppliedOnce(onceClosure) {
      continue
    }

    walker.diagnose(onceClosure as! FunctionArgument, context: context)
  }
}

private struct OnceClosureArgumentWalker: ValueDefUseWalker {
  var walkDownCache = WalkerCache<UnusedWalkingPath>()

  var applies: [ApplySite] = []

  mutating func isAppliedOnce(_ closure: Value) -> Bool {
    let aborted = walkDownUses(ofValue: closure, path: UnusedWalkingPath()) == .abortWalk
    return !aborted && applies.count == 1
  }

  func diagnose(_ closure: FunctionArgument, context: FunctionPassContext) {
    if applies.isEmpty {
      context.diagnosticEngine.diagnose(
        .once_closure_not_called,
        at: closure.sourceLoc!
      )

      return
    }

    // We visit uses from the bottom up, so our first apply is the last one we
    // see.
    let firstCall = applies.last!

    for apply in applies.dropLast().reversed() {
      context.diagnosticEngine.diagnose(
        .once_closure_called_more_than_once,
        at: apply.location
      )

      context.diagnosticEngine.diagnose(
        .once_closure_first_call,
        at: firstCall.location
      )
    }
  }

  mutating func leafUse(value: Operand, path: UnusedWalkingPath) -> WalkResult {
    print("FUNCTION: \(value.instruction.parentFunction.name)")
    print("VALUE: \(value)")

    switch value.instruction {
    case let apply as ApplySite:
      // It doesn't really matter if the closure is the callee of the apply or
      // just an operand because both will be calls.
      applies.append(apply)

    case is DebugValueInst, is DestroyValueInst, is EndBorrowInst:
      return .continueWalk

    default:
      return .abortWalk
    }

    return .continueWalk
  }
}
