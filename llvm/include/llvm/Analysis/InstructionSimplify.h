//===-- InstructionSimplify.h - Fold instrs into simpler forms --*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares routines for folding instructions into simpler forms
// that do not require creating new instructions.  This does constant folding
// ("add i32 1, 1" -> "2") but can also handle non-constant operands, either
// returning a constant ("and i32 %x, 0" -> "0") or an already existing value
// ("and i32 %x, %x" -> "%x").  If the simplification is also an instruction
// then it dominates the original instruction.
//
// These routines implicitly resolve undef uses. The easiest way to be safe when
// using these routines to obtain simplified values for existing instructions is
// to always replace all uses of the instructions with the resulting simplified
// values. This will prevent other code from seeing the same undef uses and
// resolving them to different values.
//
// These routines are designed to tolerate moderately incomplete IR, such as
// instructions that are not connected to basic blocks yet. However, they do
// require that all the IR that they encounter be valid. In particular, they
// require that all non-constant values be defined in the same function, and the
// same call context of that function (and not split between caller and callee
// contexts of a directly recursive call, for example).
//
// Additionally, these routines can't simplify to the instructions that are not
// def-reachable, meaning we can't just scan the basic block for instructions
// to simplify to.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_ANALYSIS_INSTRUCTIONSIMPLIFY_H
#define LLVM_ANALYSIS_INSTRUCTIONSIMPLIFY_H

#include "llvm/IR/PatternMatch.h"

namespace llvm {

template <typename T, typename... TArgs> class AnalysisManager;
template <class T> class ArrayRef;
class AssumptionCache;
class BinaryOperator;
class CallBase;
class DataLayout;
class DominatorTree;
class Function;
class Instruction;
struct LoopStandardAnalysisResults;
class MDNode;
class Pass;
template <class T, unsigned n> class SmallSetVector;
class TargetLibraryInfo;
class Type;
class Value;

/// InstrInfoQuery provides an interface to query additional information for
/// instructions like metadata or keywords like nsw, which provides conservative
/// results if the users specified it is safe to use.
struct InstrInfoQuery {
  InstrInfoQuery(bool UMD) : UseInstrInfo(UMD) {}
  InstrInfoQuery() = default;
  bool UseInstrInfo = true;

  MDNode *getMetadata(const Instruction *I, unsigned KindID) const {
    if (UseInstrInfo)
      return I->getMetadata(KindID);
    return nullptr;
  }

  template <class InstT> bool hasNoUnsignedWrap(const InstT *Op) const {
    if (UseInstrInfo)
      return Op->hasNoUnsignedWrap();
    return false;
  }

  template <class InstT> bool hasNoSignedWrap(const InstT *Op) const {
    if (UseInstrInfo)
      return Op->hasNoSignedWrap();
    return false;
  }

  bool isExact(const BinaryOperator *Op) const {
    if (UseInstrInfo && isa<PossiblyExactOperator>(Op))
      return cast<PossiblyExactOperator>(Op)->isExact();
    return false;
  }
};

struct SimplifyQuery {
  const DataLayout &DL;
  const TargetLibraryInfo *TLI = nullptr;
  const DominatorTree *DT = nullptr;
  AssumptionCache *AC = nullptr;
  const Instruction *CxtI = nullptr;

  // Wrapper to query additional information for instructions like metadata or
  // keywords like nsw, which provides conservative results if those cannot
  // be safely used.
  const InstrInfoQuery IIQ;

  /// Controls whether simplifications are allowed to constrain the range of
  /// possible values for uses of undef. If it is false, simplifications are not
  /// allowed to assume a particular value for a use of undef for example.
  bool CanUseUndef = true;

  SimplifyQuery(const DataLayout &DL, const Instruction *CXTI = nullptr)
      : DL(DL), CxtI(CXTI) {}

  SimplifyQuery(const DataLayout &DL, const TargetLibraryInfo *TLI,
                const DominatorTree *DT = nullptr,
                AssumptionCache *AC = nullptr,
                const Instruction *CXTI = nullptr, bool UseInstrInfo = true,
                bool CanUseUndef = true)
      : DL(DL), TLI(TLI), DT(DT), AC(AC), CxtI(CXTI), IIQ(UseInstrInfo),
        CanUseUndef(CanUseUndef) {}
  SimplifyQuery getWithInstruction(Instruction *I) const {
    SimplifyQuery Copy(*this);
    Copy.CxtI = I;
    return Copy;
  }
  SimplifyQuery getWithoutUndef() const {
    SimplifyQuery Copy(*this);
    Copy.CanUseUndef = false;
    return Copy;
  }

  /// If CanUseUndef is true, returns whether \p V is undef.
  /// Otherwise always return false.
  bool isUndefValue(Value *V) const {
    if (!CanUseUndef)
      return false;

    using namespace PatternMatch;
    return match(V, m_Undef());
  }
};

// NOTE: the explicit multiple argument versions of these functions are
// deprecated.
// Please use the SimplifyQuery versions in new code.

/// Given operands for an Add, fold the result or return null.
Value *simplifyAddInst(Value *LHS, Value *RHS, bool IsNSW, bool IsNUW,
                       const SimplifyQuery &Q);

/// Given operands for a Sub, fold the result or return null.
Value *simplifySubInst(Value *LHS, Value *RHS, bool IsNSW, bool IsNUW,
                       const SimplifyQuery &Q);

/// Given operands for a Mul, fold the result or return null.
Value *simplifyMulInst(Value *LHS, Value *RHS, bool IsNSW, bool IsNUW,
                       const SimplifyQuery &Q);

/// Given operands for an SDiv, fold the result or return null.
Value *simplifySDivInst(Value *LHS, Value *RHS, bool IsExact,
                        const SimplifyQuery &Q);

/// Given operands for a UDiv, fold the result or return null.
Value *simplifyUDivInst(Value *LHS, Value *RHS, bool IsExact,
                        const SimplifyQuery &Q);

/// Given operands for an SRem, fold the result or return null.
Value *simplifySRemInst(Value *LHS, Value *RHS, const SimplifyQuery &Q);

/// Given operands for a URem, fold the result or return null.
Value *simplifyURemInst(Value *LHS, Value *RHS, const SimplifyQuery &Q);

/// Given operand for an FNeg, fold the result or return null.
Value *simplifyFNegInst(Value *Op, FastMathFlags FMF, const SimplifyQuery &Q);


/// Given operands for an FAdd, fold the result or return null.
Value *
simplifyFAddInst(Value *LHS, Value *RHS, FastMathFlags FMF,
                 const SimplifyQuery &Q,
                 fp::ExceptionBehavior ExBehavior = fp::ebIgnore,
                 RoundingMode Rounding = RoundingMode::NearestTiesToEven);

/// Given operands for an FSub, fold the result or return null.
Value *
simplifyFSubInst(Value *LHS, Value *RHS, FastMathFlags FMF,
                 const SimplifyQuery &Q,
                 fp::ExceptionBehavior ExBehavior = fp::ebIgnore,
                 RoundingMode Rounding = RoundingMode::NearestTiesToEven);

/// Given operands for an FMul, fold the result or return null.
Value *
simplifyFMulInst(Value *LHS, Value *RHS, FastMathFlags FMF,
                 const SimplifyQuery &Q,
                 fp::ExceptionBehavior ExBehavior = fp::ebIgnore,
                 RoundingMode Rounding = RoundingMode::NearestTiesToEven);

/// Given operands for the multiplication of a FMA, fold the result or return
/// null. In contrast to simplifyFMulInst, this function will not perform
/// simplifications whose unrounded results differ when rounded to the argument
/// type.
Value *simplifyFMAFMul(Value *LHS, Value *RHS, FastMathFlags FMF,
                       const SimplifyQuery &Q,
                       fp::ExceptionBehavior ExBehavior = fp::ebIgnore,
                       RoundingMode Rounding = RoundingMode::NearestTiesToEven);

/// Given operands for an FDiv, fold the result or return null.
Value *
simplifyFDivInst(Value *LHS, Value *RHS, FastMathFlags FMF,
                 const SimplifyQuery &Q,
                 fp::ExceptionBehavior ExBehavior = fp::ebIgnore,
                 RoundingMode Rounding = RoundingMode::NearestTiesToEven);

/// Given operands for an FRem, fold the result or return null.
Value *
simplifyFRemInst(Value *LHS, Value *RHS, FastMathFlags FMF,
                 const SimplifyQuery &Q,
                 fp::ExceptionBehavior ExBehavior = fp::ebIgnore,
                 RoundingMode Rounding = RoundingMode::NearestTiesToEven);

/// Given operands for a Shl, fold the result or return null.
Value *simplifyShlInst(Value *Op0, Value *Op1, bool IsNSW, bool IsNUW,
                       const SimplifyQuery &Q);

/// Given operands for a LShr, fold the result or return null.
Value *simplifyLShrInst(Value *Op0, Value *Op1, bool IsExact,
                        const SimplifyQuery &Q);

/// Given operands for a AShr, fold the result or return nulll.
Value *simplifyAShrInst(Value *Op0, Value *Op1, bool IsExact,
                        const SimplifyQuery &Q);

/// Given operands for an And, fold the result or return null.
Value *simplifyAndInst(Value *LHS, Value *RHS, const SimplifyQuery &Q);

/// Given operands for an Or, fold the result or return null.
Value *simplifyOrInst(Value *LHS, Value *RHS, const SimplifyQuery &Q);

/// Given operands for an Xor, fold the result or return null.
Value *simplifyXorInst(Value *LHS, Value *RHS, const SimplifyQuery &Q);

/// Given operands for an ICmpInst, fold the result or return null.
Value *simplifyICmpInst(unsigned Predicate, Value *LHS, Value *RHS,
                        const SimplifyQuery &Q);

/// Given operands for an FCmpInst, fold the result or return null.
Value *simplifyFCmpInst(unsigned Predicate, Value *LHS, Value *RHS,
                        FastMathFlags FMF, const SimplifyQuery &Q);

/// Given operands for a SelectInst, fold the result or return null.
Value *simplifySelectInst(Value *Cond, Value *TrueVal, Value *FalseVal,
                          const SimplifyQuery &Q);

/// Given operands for a GetElementPtrInst, fold the result or return null.
Value *simplifyGEPInst(Type *SrcTy, Value *Ptr, ArrayRef<Value *> Indices,
                       bool InBounds, const SimplifyQuery &Q);

/// Given operands for an InsertValueInst, fold the result or return null.
Value *simplifyInsertValueInst(Value *Agg, Value *Val, ArrayRef<unsigned> Idxs,
                               const SimplifyQuery &Q);

/// Given operands for an InsertElement, fold the result or return null.
Value *simplifyInsertElementInst(Value *Vec, Value *Elt, Value *Idx,
                                 const SimplifyQuery &Q);

/// Given operands for an ExtractValueInst, fold the result or return null.
Value *simplifyExtractValueInst(Value *Agg, ArrayRef<unsigned> Idxs,
                                const SimplifyQuery &Q);

/// Given operands for an ExtractElementInst, fold the result or return null.
Value *simplifyExtractElementInst(Value *Vec, Value *Idx,
                                  const SimplifyQuery &Q);

/// Given operands for a CastInst, fold the result or return null.
Value *simplifyCastInst(unsigned CastOpc, Value *Op, Type *Ty,
                        const SimplifyQuery &Q);

/// Given operands for a ShuffleVectorInst, fold the result or return null.
/// See class ShuffleVectorInst for a description of the mask representation.
Value *simplifyShuffleVectorInst(Value *Op0, Value *Op1, ArrayRef<int> Mask,
                                 Type *RetTy, const SimplifyQuery &Q);

//=== Helper functions for higher up the class hierarchy.

/// Given operands for a CmpInst, fold the result or return null.
Value *simplifyCmpInst(unsigned Predicate, Value *LHS, Value *RHS,
                       const SimplifyQuery &Q);

/// Given operand for a UnaryOperator, fold the result or return null.
Value *simplifyUnOp(unsigned Opcode, Value *Op, const SimplifyQuery &Q);

/// Given operand for a UnaryOperator, fold the result or return null.
/// Try to use FastMathFlags when folding the result.
Value *simplifyUnOp(unsigned Opcode, Value *Op, FastMathFlags FMF,
                    const SimplifyQuery &Q);

/// Given operands for a BinaryOperator, fold the result or return null.
Value *simplifyBinOp(unsigned Opcode, Value *LHS, Value *RHS,
                     const SimplifyQuery &Q);

/// Given operands for a BinaryOperator, fold the result or return null.
/// Try to use FastMathFlags when folding the result.
Value *simplifyBinOp(unsigned Opcode, Value *LHS, Value *RHS, FastMathFlags FMF,
                     const SimplifyQuery &Q);

/// Given a callsite, callee, and arguments, fold the result or return null.
Value *simplifyCall(CallBase *Call, Value *Callee, ArrayRef<Value *> Args,
                    const SimplifyQuery &Q);

/// Given a constrained FP intrinsic call, tries to compute its simplified
/// version. Returns a simplified result or null.
///
/// This function provides an additional contract: it guarantees that if
/// simplification succeeds that the intrinsic is side effect free. As a result,
/// successful simplification can be used to delete the intrinsic not just
/// replace its result.
Value *simplifyConstrainedFPCall(CallBase *Call, const SimplifyQuery &Q);

/// Given an operand for a Freeze, see if we can fold the result.
/// If not, this returns null.
Value *simplifyFreezeInst(Value *Op, const SimplifyQuery &Q);

/// Given a load instruction and its pointer operand, fold the result or return
/// null.
Value *simplifyLoadInst(LoadInst *LI, Value *PtrOp, const SimplifyQuery &Q);

/// See if we can compute a simplified version of this instruction. If not,
/// return null.
Value *simplifyInstruction(Instruction *I, const SimplifyQuery &Q);

/// Like \p simplifyInstruction but the operands of \p I are replaced with
/// \p NewOps. Returns a simplified value, or null if none was found.
Value *
simplifyInstructionWithOperands(Instruction *I, ArrayRef<Value *> NewOps,
                                const SimplifyQuery &Q);

/// See if V simplifies when its operand Op is replaced with RepOp. If not,
/// return null.
/// AllowRefinement specifies whether the simplification can be a refinement
/// (e.g. 0 instead of poison), or whether it needs to be strictly identical.
/// Op and RepOp can be assumed to not be poison when determining refinement.
Value *simplifyWithOpReplaced(Value *V, Value *Op, Value *RepOp,
                              const SimplifyQuery &Q, bool AllowRefinement);

/// Replace all uses of 'I' with 'SimpleV' and simplify the uses recursively.
///
/// This first performs a normal RAUW of I with SimpleV. It then recursively
/// attempts to simplify those users updated by the operation. The 'I'
/// instruction must not be equal to the simplified value 'SimpleV'.
/// If UnsimplifiedUsers is provided, instructions that could not be simplified
/// are added to it.
///
/// The function returns true if any simplifications were performed.
bool replaceAndRecursivelySimplify(
    Instruction *I, Value *SimpleV, const TargetLibraryInfo *TLI = nullptr,
    const DominatorTree *DT = nullptr, AssumptionCache *AC = nullptr,
    SmallSetVector<Instruction *, 8> *UnsimplifiedUsers = nullptr);

// These helper functions return a SimplifyQuery structure that contains as
// many of the optional analysis we use as are currently valid.  This is the
// strongly preferred way of constructing SimplifyQuery in passes.
const SimplifyQuery getBestSimplifyQuery(Pass &, Function &);
template <class T, class... TArgs>
const SimplifyQuery getBestSimplifyQuery(AnalysisManager<T, TArgs...> &,
                                         Function &);
const SimplifyQuery getBestSimplifyQuery(LoopStandardAnalysisResults &,
                                         const DataLayout &);
} // end namespace llvm

#endif
