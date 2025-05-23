// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_CONSTANTS_ARM64_H_
#define RUNTIME_VM_CONSTANTS_ARM64_H_

#ifndef RUNTIME_VM_CONSTANTS_H_
#error Do not include constants_arm64.h directly; use constants.h instead.
#endif

#include "platform/assert.h"
#include "platform/globals.h"
#include "platform/utils.h"

#include "vm/constants_base.h"

namespace dart {

// LR register should not be used directly in handwritten assembly patterns,
// because it might contain return address. Instead use macross CLOBBERS_LR,
// SPILLS_RETURN_ADDRESS_FROM_LR_TO_REGISTER,
// RESTORES_RETURN_ADDRESS_FROM_REGISTER_TO_LR, SPILLS_LR_TO_FRAME,
// RESTORES_LR_FROM_FRAME, READS_RETURN_ADDRESS_FROM_LR,
// WRITES_RETURN_ADDRESS_TO_LR to get access to LR constant in a checked way.
//
// To prevent accidental use of LR constant we rename it to
// LR_DO_NOT_USE_DIRECTLY (while keeping the code in this file and other files
// which are permitted to access LR constant the same by defining LR as
// LR_DO_NOT_USE_DIRECTLY). You can also use LINK_REGISTER if you need
// to compare LR register code.
#define LR LR_DO_NOT_USE_DIRECTLY

enum Register {
  R0 = 0,
  R1 = 1,
  R2 = 2,
  R3 = 3,
  R4 = 4,
  R5 = 5,
  R6 = 6,
  R7 = 7,
  R8 = 8,
  R9 = 9,
  R10 = 10,
  R11 = 11,
  R12 = 12,
  R13 = 13,
  R14 = 14,
  R15 = 15,  // SP in Dart code.
  R16 = 16,  // IP0 aka TMP
  R17 = 17,  // IP1 aka TMP2
  R18 = 18,  // reserved on iOS, shadow call stack on Fuchsia, TEB on Windows.
  R19 = 19,
  R20 = 20,
  R21 = 21,  // DISPATCH_TABLE_REG (AOT only)
  R22 = 22,  // NULL_REG
  R23 = 23,
  R24 = 24,  // CODE_REG
  R25 = 25,
  R26 = 26,  // THR
  R27 = 27,  // PP
  R28 = 28,  // HEAP_BITS
  R29 = 29,  // FP
  R30 = 30,  // LR
  R31 = 31,  // ZR, CSP
  kNumberOfCpuRegisters = 32,
  kNoRegister = -1,
  kNoRegister2 = -2,

  // These registers both use the encoding R31, but to avoid mistakes we give
  // them different values, and then translate before encoding.
  CSP = 32,
  ZR = 33,

  // Aliases.
  IP0 = R16,
  IP1 = R17,
  SP = R15,
  FP = R29,
  LR = R30,  // Note: direct access to this constant is not allowed. See above.
};

enum VRegister {
  // v0 Volatile; Parameter/scratch register, result register.
  V0 = 0,
  // v1-v7 Volatile; Parameter/scratch register.
  V1 = 1,
  V2 = 2,
  V3 = 3,
  V4 = 4,
  V5 = 5,
  V6 = 6,
  V7 = 7,
  // v8-v15 Non-volatile; Scratch registers
  // Only the bottom 64 bits are non-volatile! [ARM IHI 0055B, 5.1.2]
  V8 = 8,
  V9 = 9,
  V10 = 10,
  V11 = 11,
  V12 = 12,
  V13 = 13,
  V14 = 14,
  V15 = 15,
  // v16-v31 Volatile; Scratch registers.
  V16 = 16,
  V17 = 17,
  V18 = 18,
  V19 = 19,
  V20 = 20,
  V21 = 21,
  V22 = 22,
  V23 = 23,
  V24 = 24,
  V25 = 25,
  V26 = 26,
  V27 = 27,
  V28 = 28,
  V29 = 29,
  V30 = 30,
  V31 = 31,
  kNumberOfVRegisters = 32,
  kNoVRegister = -1,
};

// Register alias for floating point scratch register.
const VRegister VTMP = V31;

// Architecture independent aliases.
typedef VRegister FpuRegister;
const FpuRegister FpuTMP = VTMP;
const int kFpuRegisterSize = 16;
typedef simd128_value_t fpu_register_t;
const int kNumberOfFpuRegisters = kNumberOfVRegisters;
const FpuRegister kNoFpuRegister = kNoVRegister;

extern const char* const cpu_reg_names[kNumberOfCpuRegisters];
extern const char* const cpu_reg_abi_names[kNumberOfCpuRegisters];
extern const char* const fpu_reg_names[kNumberOfFpuRegisters];

// Register aliases.
const Register TMP = R16;  // Used as scratch register by assembler.
const Register TMP2 = R17;
const Register PP = R27;  // Caches object pool pointer in generated code.
const Register DISPATCH_TABLE_REG = R21;  // Dispatch table register.
const Register CODE_REG = R24;
// Set when calling Dart functions in JIT mode, used by LazyCompileStub.
const Register FUNCTION_REG = R0;
const Register FPREG = FP;          // Frame pointer register.
const Register SPREG = R15;         // Stack pointer register.
const Register IC_DATA_REG = R5;    // ICData/MegamorphicCache register.
const Register ARGS_DESC_REG = R4;  // Arguments descriptor register.
const Register THR = R26;           // Caches current thread in generated code.
const Register CALLEE_SAVED_TEMP = R19;
const Register CALLEE_SAVED_TEMP2 = R20;
const Register HEAP_BITS = R28;  // write_barrier_mask << 32 | heap_base >> 32
const Register NULL_REG = R22;   // Caches NullObject() value.
#define DART_ASSEMBLER_HAS_NULL_REG 1

// ABI for catch-clause entry point.
const Register kExceptionObjectReg = R0;
const Register kStackTraceObjectReg = R1;

// ABI for write barrier stub.
const Register kWriteBarrierObjectReg = R1;
const Register kWriteBarrierValueReg = R0;
const Register kWriteBarrierSlotReg = R25;

// Common ABI for shared slow path stubs.
struct SharedSlowPathStubABI {
  static constexpr Register kResultReg = R0;
};

// ABI for instantiation stubs.
struct InstantiationABI {
  static constexpr Register kUninstantiatedTypeArgumentsReg = R3;
  static constexpr Register kInstantiatorTypeArgumentsReg = R2;
  static constexpr Register kFunctionTypeArgumentsReg = R1;
  static constexpr Register kResultTypeArgumentsReg = R0;
  static constexpr Register kResultTypeReg = R0;
  static constexpr Register kScratchReg = R8;
};

// Registers in addition to those listed in InstantiationABI used inside the
// implementation of the InstantiateTypeArguments stubs.
struct InstantiateTAVInternalRegs {
  // The set of registers that must be pushed/popped when probing a hash-based
  // cache due to overlap with the registers in InstantiationABI.
  static constexpr intptr_t kSavedRegisters = 0;

  // Additional registers used to probe hash-based caches.
  static constexpr Register kEntryStartReg = R9;
  static constexpr Register kProbeMaskReg = R7;
  static constexpr Register kProbeDistanceReg = R6;
  static constexpr Register kCurrentEntryIndexReg = R10;
};

// Registers in addition to those listed in TypeTestABI used inside the
// implementation of type testing stubs that are _not_ preserved.
struct TTSInternalRegs {
  static constexpr Register kInstanceTypeArgumentsReg = R7;
  static constexpr Register kScratchReg = R9;
  static constexpr Register kSubTypeArgumentReg = R5;
  static constexpr Register kSuperTypeArgumentReg = R6;

  // Must be pushed/popped whenever generic type arguments are being checked as
  // they overlap with registers in TypeTestABI.
  static constexpr intptr_t kSavedTypeArgumentRegisters = 0;

  static constexpr intptr_t kInternalRegisters =
      ((1 << kInstanceTypeArgumentsReg) | (1 << kScratchReg) |
       (1 << kSubTypeArgumentReg) | (1 << kSuperTypeArgumentReg)) &
      ~kSavedTypeArgumentRegisters;
};

// Registers in addition to those listed in TypeTestABI used inside the
// implementation of subtype test cache stubs that are _not_ preserved.
struct STCInternalRegs {
  static constexpr Register kInstanceCidOrSignatureReg = R6;
  static constexpr Register kInstanceInstantiatorTypeArgumentsReg = R5;
  static constexpr Register kInstanceParentFunctionTypeArgumentsReg = R9;
  static constexpr Register kInstanceDelayedFunctionTypeArgumentsReg = R10;
  static constexpr Register kCacheEntriesEndReg = R11;
  static constexpr Register kCacheContentsSizeReg = R12;
  static constexpr Register kProbeDistanceReg = R13;

  static constexpr intptr_t kInternalRegisters =
      (1 << kInstanceCidOrSignatureReg) |
      (1 << kInstanceInstantiatorTypeArgumentsReg) |
      (1 << kInstanceParentFunctionTypeArgumentsReg) |
      (1 << kInstanceDelayedFunctionTypeArgumentsReg) |
      (1 << kCacheEntriesEndReg) | (1 << kCacheContentsSizeReg) |
      (1 << kProbeDistanceReg);
};

// Calling convention when calling TypeTestingStub and SubtypeTestCacheStub.
struct TypeTestABI {
  static constexpr Register kInstanceReg = R0;
  static constexpr Register kDstTypeReg = R8;
  static constexpr Register kInstantiatorTypeArgumentsReg = R2;
  static constexpr Register kFunctionTypeArgumentsReg = R1;
  static constexpr Register kSubtypeTestCacheReg = R3;
  static constexpr Register kScratchReg = R4;

  // For calls to SubtypeNTestCacheStub. Must be distinct from the registers
  // listed above.
  static constexpr Register kSubtypeTestCacheResultReg = R7;
  // For calls to InstanceOfStub.
  static constexpr Register kInstanceOfResultReg = kInstanceReg;

  static constexpr intptr_t kPreservedAbiRegisters =
      (1 << kInstanceReg) | (1 << kDstTypeReg) |
      (1 << kInstantiatorTypeArgumentsReg) | (1 << kFunctionTypeArgumentsReg);

  static constexpr intptr_t kNonPreservedAbiRegisters =
      TTSInternalRegs::kInternalRegisters |
      STCInternalRegs::kInternalRegisters | (1 << kSubtypeTestCacheReg) |
      (1 << kScratchReg) | (1 << kSubtypeTestCacheResultReg) | (1 << CODE_REG);

  static constexpr intptr_t kAbiRegisters =
      kPreservedAbiRegisters | kNonPreservedAbiRegisters;
};

// Calling convention when calling AssertSubtypeStub.
struct AssertSubtypeABI {
  static constexpr Register kSubTypeReg = R0;
  static constexpr Register kSuperTypeReg = R8;
  static constexpr Register kInstantiatorTypeArgumentsReg = R2;
  static constexpr Register kFunctionTypeArgumentsReg = R1;
  static constexpr Register kDstNameReg = R3;

  static constexpr intptr_t kAbiRegisters =
      (1 << kSubTypeReg) | (1 << kSuperTypeReg) |
      (1 << kInstantiatorTypeArgumentsReg) | (1 << kFunctionTypeArgumentsReg) |
      (1 << kDstNameReg);

  // No result register, as AssertSubtype is only run for side effect
  // (throws if the subtype check fails).
};

// ABI for InitStaticFieldStub.
struct InitStaticFieldABI {
  static constexpr Register kFieldReg = R2;
  static constexpr Register kResultReg = R0;
};

// Registers used inside the implementation of InitLateStaticFieldStub.
struct InitLateStaticFieldInternalRegs {
  static constexpr Register kAddressReg = R3;
  static constexpr Register kScratchReg = R4;
};

// ABI for InitInstanceFieldStub.
struct InitInstanceFieldABI {
  static constexpr Register kInstanceReg = R1;
  static constexpr Register kFieldReg = R2;
  static constexpr Register kResultReg = R0;
};

// Registers used inside the implementation of InitLateInstanceFieldStub.
struct InitLateInstanceFieldInternalRegs {
  static constexpr Register kAddressReg = R3;
  static constexpr Register kScratchReg = R4;
};

// ABI for LateInitializationError stubs.
struct LateInitializationErrorABI {
  static constexpr Register kFieldReg = R9;
};

// ABI for FieldAccessError stubs.
struct FieldAccessErrorABI {
  static constexpr Register kFieldReg = R9;
};

// ABI for ThrowStub.
struct ThrowABI {
  static constexpr Register kExceptionReg = R0;
};

// ABI for ReThrowStub.
struct ReThrowABI {
  static constexpr Register kExceptionReg = R0;
  static constexpr Register kStackTraceReg = R1;
};

// ABI for RangeErrorStub.
struct RangeErrorABI {
  static constexpr Register kLengthReg = R0;
  static constexpr Register kIndexReg = R1;
};

// ABI for AllocateObjectStub.
struct AllocateObjectABI {
  static constexpr Register kResultReg = R0;
  static constexpr Register kTypeArgumentsReg = R1;
  static constexpr Register kTagsReg = R2;
};

// ABI for AllocateClosureStub.
struct AllocateClosureABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kFunctionReg = R1;
  static constexpr Register kContextReg = R2;
  static constexpr Register kInstantiatorTypeArgsReg = R3;
  static constexpr Register kScratchReg = R4;
};

// ABI for AllocateMintShared*Stub.
struct AllocateMintABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kTempReg = R1;
};

// ABI for Allocate{Mint,Double,Float32x4,Float64x2}Stub.
struct AllocateBoxABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kTempReg = R1;
};

// ABI for AllocateArrayStub.
struct AllocateArrayABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kLengthReg = R2;
  static constexpr Register kTypeArgumentsReg = R1;
};

// ABI for AllocateRecordStub.
struct AllocateRecordABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kShapeReg = R1;
  static constexpr Register kTemp1Reg = R2;
  static constexpr Register kTemp2Reg = R3;
};

// ABI for AllocateSmallRecordStub (AllocateRecord2, AllocateRecord2Named,
// AllocateRecord3, AllocateRecord3Named).
struct AllocateSmallRecordABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kShapeReg = R1;
  static constexpr Register kValue0Reg = R2;
  static constexpr Register kValue1Reg = R3;
  static constexpr Register kValue2Reg = R4;
  static constexpr Register kTempReg = R5;
};

// ABI for AllocateTypedDataArrayStub.
struct AllocateTypedDataArrayABI {
  static constexpr Register kResultReg = AllocateObjectABI::kResultReg;
  static constexpr Register kLengthReg = R4;
};

// ABI for BoxDoubleStub.
struct BoxDoubleStubABI {
  static constexpr FpuRegister kValueReg = V0;
  static constexpr Register kTempReg = R1;
  static constexpr Register kResultReg = R0;
};

// ABI for DoubleToIntegerStub.
struct DoubleToIntegerStubABI {
  static constexpr FpuRegister kInputReg = V0;
  static constexpr Register kRecognizedKindReg = R0;
  static constexpr Register kResultReg = R0;
};

// ABI for SuspendStub (AwaitStub, AwaitWithTypeCheckStub, YieldAsyncStarStub,
// SuspendSyncStarAtStartStub, SuspendSyncStarAtYieldStub).
struct SuspendStubABI {
  static constexpr Register kArgumentReg = R0;
  static constexpr Register kTypeArgsReg = R1;  // Can be the same as kTempReg
  static constexpr Register kTempReg = R1;
  static constexpr Register kFrameSizeReg = R2;
  static constexpr Register kSuspendStateReg = R3;
  static constexpr Register kFunctionDataReg = R4;
  static constexpr Register kSrcFrameReg = R5;
  static constexpr Register kDstFrameReg = R6;

  // Number of bytes to skip after
  // suspend stub return address in order to resume.
  static constexpr intptr_t kResumePcDistance = 0;
};

// ABI for InitSuspendableFunctionStub (InitAsyncStub, InitAsyncStarStub,
// InitSyncStarStub).
struct InitSuspendableFunctionStubABI {
  static constexpr Register kTypeArgsReg = R0;
};

// ABI for ResumeStub
struct ResumeStubABI {
  static constexpr Register kSuspendStateReg = R2;
  static constexpr Register kTempReg = R0;
  // Registers for the frame copying (the 1st part).
  static constexpr Register kFrameSizeReg = R1;
  static constexpr Register kSrcFrameReg = R3;
  static constexpr Register kDstFrameReg = R4;
  // Registers for control transfer.
  // (the 2nd part, can reuse registers from the 1st part)
  static constexpr Register kResumePcReg = R1;
  // Can also reuse kSuspendStateReg but should not conflict with CODE_REG/PP.
  static constexpr Register kExceptionReg = R3;
  static constexpr Register kStackTraceReg = R4;
};

// ABI for ReturnStub (ReturnAsyncStub, ReturnAsyncNotFutureStub,
// ReturnAsyncStarStub).
struct ReturnStubABI {
  static constexpr Register kSuspendStateReg = R2;
};

// ABI for AsyncExceptionHandlerStub.
struct AsyncExceptionHandlerStubABI {
  static constexpr Register kSuspendStateReg = R2;
};

// ABI for CloneSuspendStateStub.
struct CloneSuspendStateStubABI {
  static constexpr Register kSourceReg = R0;
  static constexpr Register kDestinationReg = R1;
  static constexpr Register kTempReg = R2;
  static constexpr Register kFrameSizeReg = R3;
  static constexpr Register kSrcFrameReg = R4;
  static constexpr Register kDstFrameReg = R5;
};

// ABI for FfiAsyncCallbackSendStub.
struct FfiAsyncCallbackSendStubABI {
  static constexpr Register kArgsReg = R0;
};

// ABI for DispatchTableNullErrorStub and consequently for all dispatch
// table calls (though normal functions will not expect or use this
// register). This ABI is added to distinguish memory corruption errors from
// null errors.
struct DispatchTableNullErrorABI {
  static constexpr Register kClassIdReg = R0;
};

// TODO(regis): Add ABIs for type testing stubs and is-type test stubs instead
// of reusing the constants of the instantiation stubs ABI.

// Masks, sizes, etc.
const int kXRegSizeInBits = 64;
const int kWRegSizeInBits = 32;
const int64_t kXRegMask = 0xffffffffffffffffL;
const int64_t kWRegMask = 0x00000000ffffffffL;

// List of registers used in load/store multiple.
typedef uint32_t RegList;
const RegList kAllCpuRegistersList = 0xFFFFFFFF;
const RegList kAllFpuRegistersList = 0xFFFFFFFF;

// See "Procedure Call Standard for the ARM 64-bit Architecture", document
// number "ARM IHI 0055B", May 22 2013.

#define R(reg) (static_cast<RegList>(1) << (reg))

// C++ ABI call registers.
const RegList kAbiArgumentCpuRegs =
    R(R0) | R(R1) | R(R2) | R(R3) | R(R4) | R(R5) | R(R6) | R(R7);
const RegList kAbiVolatileCpuRegs = kAbiArgumentCpuRegs | R(R8) | R(R9) |
                                    R(R10) | R(R11) | R(R12) | R(R13) | R(R14) |
                                    R(R15) | R(R16) | R(R17) | R(LR);
#if defined(DART_TARGET_OS_FUCHSIA)
// We rely on R18 not being touched by Dart generated assembly or stubs at all.
// We rely on that any calls into C++ also preserve R18.
const RegList kAbiPreservedCpuRegs = R(R18) | R(R19) | R(R20) | R(R21) |
                                     R(R22) | R(R23) | R(R24) | R(R25) |
                                     R(R26) | R(R27) | R(R28);
const Register kAbiFirstPreservedCpuReg = R18;
const Register kAbiLastPreservedCpuReg = R28;
const int kAbiPreservedCpuRegCount = 11;
#else
const RegList kAbiPreservedCpuRegs = R(R19) | R(R20) | R(R21) | R(R22) |
                                     R(R23) | R(R24) | R(R25) | R(R26) |
                                     R(R27) | R(R28);
const Register kAbiFirstPreservedCpuReg = R19;
const Register kAbiLastPreservedCpuReg = R28;
const int kAbiPreservedCpuRegCount = 10;
#endif
const VRegister kAbiFirstPreservedFpuReg = V8;
const VRegister kAbiLastPreservedFpuReg = V15;
const int kAbiPreservedFpuRegCount = 8;

// R18 is reserved on Mac/iOS, Fuchsia, Windows and sometimes Android. Although
// it is available on Linux, we mark it as reserved unconditionally to avoid
// adding another dimenision for OS into the extracted runtime offsets.
const RegList kReservedCpuRegisters = R(SPREG) |  // Dart SP
                                      R(FPREG) | R(TMP) | R(TMP2) | R(PP) |
                                      R(THR) | R(LR) | R(HEAP_BITS) |
                                      R(NULL_REG) | R(R31) |  // C++ SP
                                      R(R18) | R(DISPATCH_TABLE_REG);
constexpr intptr_t kNumberOfReservedCpuRegisters =
    Utils::CountOneBits32(kReservedCpuRegisters);
// CPU registers available to Dart allocator.
const RegList kDartAvailableCpuRegs =
    kAllCpuRegistersList & ~kReservedCpuRegisters;
constexpr int kNumberOfDartAvailableCpuRegs =
    kNumberOfCpuRegisters - kNumberOfReservedCpuRegisters;
// No reason to prefer certain registers on ARM64.
constexpr int kRegisterAllocationBias = 0;
// Registers available to Dart that are not preserved by runtime calls.
const RegList kDartVolatileCpuRegs =
    kDartAvailableCpuRegs & ~kAbiPreservedCpuRegs;
const Register kDartFirstVolatileCpuReg = R0;
const Register kDartLastVolatileCpuReg = R14;
const int kDartVolatileCpuRegCount = 15;
const int kDartVolatileFpuRegCount = 24;

const RegList kAbiVolatileFpuRegs =
    R(V0) | R(V1) | R(V2) | R(V3) | R(V4) | R(V5) | R(V6) | R(V7) | R(V16) |
    R(V17) | R(V18) | R(V19) | R(V20) | R(V21) | R(V22) | R(V23) | R(V24) |
    R(V25) | R(V26) | R(V27) | R(V28) | R(V29) | R(V30) | R(V31);

constexpr int kStoreBufferWrapperSize = 32;

class CallingConventions {
 public:
  static constexpr intptr_t kArgumentRegisters = kAbiArgumentCpuRegs;
  static const Register ArgumentRegisters[];
  static constexpr intptr_t kNumArgRegs = 8;
  // The native ABI uses R8 to pass the pointer to the memory preallocated for
  // struct return values. Arm64 is the only ABI in which this pointer is _not_
  // in ArgumentRegisters[0] or on the stack.
  static constexpr Register kPointerToReturnStructRegisterCall = R8;
  static constexpr Register kPointerToReturnStructRegisterReturn = R8;

  static const FpuRegister FpuArgumentRegisters[];
  static constexpr intptr_t kFpuArgumentRegisters =
      R(V0) | R(V1) | R(V2) | R(V3) | R(V4) | R(V5) | R(V6) | R(V7);
  static constexpr intptr_t kNumFpuArgRegs = 8;

  static constexpr bool kArgumentIntRegXorFpuReg = false;

  static constexpr intptr_t kCalleeSaveCpuRegisters = kAbiPreservedCpuRegs;

  // Whether larger than wordsize arguments are aligned to even registers.
  static constexpr AlignmentStrategy kArgumentRegisterAlignment =
      kAlignedToWordSize;
  static constexpr AlignmentStrategy kArgumentRegisterAlignmentVarArgs =
      kArgumentRegisterAlignment;

  // How stack arguments are aligned.
#if defined(DART_TARGET_OS_MACOS_IOS) || defined(DART_TARGET_OS_MACOS)
  // > Function arguments may consume slots on the stack that are not multiples
  // > of 8 bytes.
  // https://developer.apple.com/documentation/xcode/writing_arm64_code_for_apple_platforms
  static constexpr AlignmentStrategy kArgumentStackAlignment =
      kAlignedToValueSize;
  //  Varargs are aligned to wordsize.
  static constexpr AlignmentStrategy kArgumentStackAlignmentVarArgs =
      kAlignedToWordSize;
#else
  static constexpr AlignmentStrategy kArgumentStackAlignment =
      kAlignedToWordSize;
  static constexpr AlignmentStrategy kArgumentStackAlignmentVarArgs =
      kArgumentStackAlignment;
#endif

  // How fields in compounds are aligned.
  static constexpr AlignmentStrategy kFieldAlignment = kAlignedToValueSize;

  // Whether 1 or 2 byte-sized arguments or return values are passed extended
  // to 4 bytes.
#if defined(DART_TARGET_OS_MACOS_IOS) || defined(DART_TARGET_OS_MACOS)
  static constexpr ExtensionStrategy kReturnRegisterExtension = kExtendedTo4;
  static constexpr ExtensionStrategy kArgumentRegisterExtension = kExtendedTo4;
#else
  static constexpr ExtensionStrategy kReturnRegisterExtension = kNotExtended;
  static constexpr ExtensionStrategy kArgumentRegisterExtension = kNotExtended;
#endif
  static constexpr ExtensionStrategy kArgumentStackExtension = kNotExtended;

  static constexpr Register kReturnReg = R0;
  static constexpr Register kSecondReturnReg = R1;
  static constexpr FpuRegister kReturnFpuReg = V0;

  static constexpr Register kFfiAnyNonAbiRegister = R19;
  static constexpr Register kFirstNonArgumentRegister = R9;
  static constexpr Register kSecondNonArgumentRegister = R10;
  static constexpr Register kStackPointerRegister = SPREG;

  COMPILE_ASSERT(
      ((R(kFirstNonArgumentRegister) | R(kSecondNonArgumentRegister)) &
       (kArgumentRegisters | R(kPointerToReturnStructRegisterCall))) == 0);
};

// Register based calling convention used for Dart functions.
//
// See |compiler::ComputeCallingConvention| for more details.
struct DartCallingConvention {
  static constexpr Register kCpuRegistersForArgs[] = {R1, R2, R3, R5, R6, R7};
  static constexpr FpuRegister kFpuRegistersForArgs[] = {V0, V1, V2,
                                                         V3, V4, V5};
};

#undef R

static inline Register ConcreteRegister(Register r) {
  return ((r == ZR) || (r == CSP)) ? R31 : r;
}

// Values for the condition field as defined in section A3.2.
enum Condition {
  kNoCondition = -1,
  EQ = 0,   // equal
  NE = 1,   // not equal
  CS = 2,   // carry set/unsigned higher or same
  CC = 3,   // carry clear/unsigned lower
  MI = 4,   // minus/negative
  PL = 5,   // plus/positive or zero
  VS = 6,   // overflow
  VC = 7,   // no overflow
  HI = 8,   // unsigned higher
  LS = 9,   // unsigned lower or same
  GE = 10,  // signed greater than or equal
  LT = 11,  // signed less than
  GT = 12,  // signed greater than
  LE = 13,  // signed less than or equal
  AL = 14,  // always (unconditional)
  NV = 15,  // special condition (refer to section C1.2.3)
  kNumberOfConditions = 16,

  // Platform-independent variants declared for all platforms
  EQUAL = EQ,
  ZERO = EQUAL,
  NOT_EQUAL = NE,
  NOT_ZERO = NOT_EQUAL,
  LESS = LT,
  LESS_EQUAL = LE,
  GREATER_EQUAL = GE,
  GREATER = GT,
  UNSIGNED_LESS = CC,
  UNSIGNED_LESS_EQUAL = LS,
  UNSIGNED_GREATER = HI,
  UNSIGNED_GREATER_EQUAL = CS,
  OVERFLOW = VS,
  NO_OVERFLOW = VC,

  kInvalidCondition = 16
};

static inline Condition InvertCondition(Condition c) {
  COMPILE_ASSERT((EQ ^ NE) == 1);
  COMPILE_ASSERT((CS ^ CC) == 1);
  COMPILE_ASSERT((MI ^ PL) == 1);
  COMPILE_ASSERT((VS ^ VC) == 1);
  COMPILE_ASSERT((HI ^ LS) == 1);
  COMPILE_ASSERT((GE ^ LT) == 1);
  COMPILE_ASSERT((GT ^ LE) == 1);
  COMPILE_ASSERT((AL ^ NV) == 1);
  ASSERT(c != AL);
  ASSERT(c != kInvalidCondition);
  return static_cast<Condition>(c ^ 1);
}

constexpr int32_t B0 = (1 << 0);
constexpr int32_t B1 = (1 << 1);
constexpr int32_t B2 = (1 << 2);
constexpr int32_t B3 = (1 << 3);
constexpr int32_t B4 = (1 << 4);
constexpr int32_t B5 = (1 << 5);
constexpr int32_t B6 = (1 << 6);
constexpr int32_t B7 = (1 << 7);
constexpr int32_t B8 = (1 << 8);
constexpr int32_t B9 = (1 << 9);
constexpr int32_t B10 = (1 << 10);
constexpr int32_t B11 = (1 << 11);
constexpr int32_t B12 = (1 << 12);
constexpr int32_t B13 = (1 << 13);
constexpr int32_t B14 = (1 << 14);
constexpr int32_t B15 = (1 << 15);
constexpr int32_t B16 = (1 << 16);
constexpr int32_t B17 = (1 << 17);
constexpr int32_t B18 = (1 << 18);
constexpr int32_t B19 = (1 << 19);
constexpr int32_t B20 = (1 << 20);
constexpr int32_t B21 = (1 << 21);
constexpr int32_t B22 = (1 << 22);
constexpr int32_t B23 = (1 << 23);
constexpr int32_t B24 = (1 << 24);
constexpr int32_t B25 = (1 << 25);
constexpr int32_t B26 = (1 << 26);
constexpr int32_t B27 = (1 << 27);
constexpr int32_t B28 = (1 << 28);
constexpr int32_t B29 = (1 << 29);
constexpr int32_t B30 = (1 << 30);
constexpr int32_t B31 = (1 << 31);

// Opcodes from C3
// C3.1.
enum MainOp {
  DPImmediateMask = 0x1c000000,
  DPImmediateFixed = B28,

  CompareBranchMask = 0x1c000000,
  CompareBranchFixed = B28 | B26,

  LoadStoreMask = B27 | B25,
  LoadStoreFixed = B27,

  DPRegisterMask = 0x0e000000,
  DPRegisterFixed = B27 | B25,

  DPSimd1Mask = 0x1e000000,
  DPSimd1Fixed = B27 | B26 | B25,

  DPSimd2Mask = 0x1e000000,
  DPSimd2Fixed = B28 | DPSimd1Fixed,

  FPMask = 0x5e000000,
  FPFixed = B28 | B27 | B26 | B25,
};

// C3.2.1
enum CompareAndBranchOp {
  CompareAndBranchMask = 0x7e000000,
  CompareAndBranchFixed = CompareBranchFixed | B29,
  CBZ = CompareAndBranchFixed,
  CBNZ = CompareAndBranchFixed | B24,
};

// C.3.2.2
enum ConditionalBranchOp {
  ConditionalBranchMask = 0xfe000000,
  ConditionalBranchFixed = CompareBranchFixed | B30,
  BCOND = ConditionalBranchFixed,
};

// C3.2.3
enum ExceptionGenOp {
  ExceptionGenMask = 0xff000000,
  ExceptionGenFixed = CompareBranchFixed | B31 | B30,
  SVC = ExceptionGenFixed | B0,
  BRK = ExceptionGenFixed | B21,
  HLT = ExceptionGenFixed | B22,
};

// C3.2.4
enum SystemOp {
  SystemMask = 0xffc00000,
  SystemFixed = CompareBranchFixed | B31 | B30 | B24,
  HINT = SystemFixed | B17 | B16 | B13 | B4 | B3 | B2 | B1 | B0,
  CLREX = SystemFixed | B17 | B16 | B13 | B12 | B11 | B10 | B9 | B8 | B6 | B4 |
          B3 | B2 | B1 | B0,
};

// C3.2.5
enum TestAndBranchOp {
  TestAndBranchMask = 0x7e000000,
  TestAndBranchFixed = CompareBranchFixed | B29 | B25,
  TBZ = TestAndBranchFixed,
  TBNZ = TestAndBranchFixed | B24,
};

// C3.2.6
enum UnconditionalBranchOp {
  UnconditionalBranchMask = 0x7c000000,
  UnconditionalBranchFixed = CompareBranchFixed,
  B = UnconditionalBranchFixed,
  BL = UnconditionalBranchFixed | B31,
};

// C3.2.7
enum UnconditionalBranchRegOp {
  UnconditionalBranchRegMask = 0xfe000000,
  UnconditionalBranchRegFixed = CompareBranchFixed | B31 | B30 | B25,
  BR = UnconditionalBranchRegFixed | B20 | B19 | B18 | B17 | B16,
  BLR = BR | B21,
  RET = BR | B22,
};

// C3.3.5
enum LoadRegLiteralOp {
  LoadRegLiteralMask = 0x3b000000,
  LoadRegLiteralFixed = LoadStoreFixed | B28,
  LDRpc = LoadRegLiteralFixed,
};

// C3.3.6
enum LoadStoreExclusiveOp {
  LoadStoreExclusiveMask = 0x3f000000,
  LoadStoreExclusiveFixed = B27,
  LDXR = LoadStoreExclusiveFixed | B22,
  STXR = LoadStoreExclusiveFixed,
  LDAR = LoadStoreExclusiveFixed | B23 | B22 | B15,
  STLR = LoadStoreExclusiveFixed | B23 | B15,
};

enum AtomicMemoryOp {
  AtomicMemoryMask = 0x3f200c00,
  AtomicMemoryFixed = B29 | B28 | B27 | B21,
  LDCLR = AtomicMemoryFixed | B12,
  LDSET = AtomicMemoryFixed | B13 | B12,
};

// C3.3.7-10
enum LoadStoreRegOp {
  LoadStoreRegMask = 0x3a000000,
  LoadStoreRegFixed = LoadStoreFixed | B29 | B28,
  STR = LoadStoreRegFixed,
  LDR = LoadStoreRegFixed | B22,
  LDRS = LoadStoreRegFixed | B23,
  FSTR = STR | B26,
  FLDR = LDR | B26,
  FSTRQ = STR | B26 | B23,
  FLDRQ = LDR | B26 | B23,
};

// C3.3.14-16
enum LoadStoreRegPairOp {
  LoadStoreRegPairMask = 0x3a000000,
  LoadStoreRegPairFixed = LoadStoreFixed | B29,
  STP = LoadStoreRegPairFixed,
  LDP = LoadStoreRegPairFixed | B22,
  FSTP = STP | B26,
  FLDP = LDP | B26,
};

// C3.4.1
enum AddSubImmOp {
  AddSubImmMask = 0x1f000000,
  AddSubImmFixed = DPImmediateFixed | B24,
  ADDI = AddSubImmFixed,
  SUBI = AddSubImmFixed | B30,
};

// C3.4.2
enum BitfieldOp {
  BitfieldMask = 0x1f800000,
  BitfieldFixed = 0x13000000,
  SBFM = BitfieldFixed,
  BFM = BitfieldFixed | B29,
  UBFM = BitfieldFixed | B30,
  Bitfield64 = B31 | B22,
};

// C3.4.4
enum LogicalImmOp {
  LogicalImmMask = 0x1f800000,
  LogicalImmFixed = DPImmediateFixed | B25,
  ANDI = LogicalImmFixed,
  ORRI = LogicalImmFixed | B29,
  EORI = LogicalImmFixed | B30,
  ANDIS = LogicalImmFixed | B30 | B29,
};

// C3.4.5
enum MoveWideOp {
  MoveWideMask = 0x1f800000,
  MoveWideFixed = DPImmediateFixed | B25 | B23,
  MOVN = MoveWideFixed,
  MOVZ = MoveWideFixed | B30,
  MOVK = MoveWideFixed | B30 | B29,
};

// C3.4.6
enum PCRelOp {
  PCRelMask = 0x1f000000,
  PCRelFixed = DPImmediateFixed,
  ADR = PCRelFixed,
  ADRP = PCRelFixed | B31,
};

// C3.5.1
enum AddSubShiftExtOp {
  AddSubShiftExtMask = 0x1f000000,
  AddSubShiftExtFixed = DPRegisterFixed | B24,
  ADD = AddSubShiftExtFixed,
  SUB = AddSubShiftExtFixed | B30,
};

// C3.5.3
enum AddSubWithCarryOp {
  AddSubWithCarryMask = 0x1fe00000,
  AddSubWithCarryFixed = DPRegisterFixed | B28,
  ADC = AddSubWithCarryFixed,
  SBC = AddSubWithCarryFixed | B30,
};

// C3.5.6
enum ConditionalSelectOp {
  ConditionalSelectMask = 0x1fe00000,
  ConditionalSelectFixed = DPRegisterFixed | B28 | B23,
  CSEL = ConditionalSelectFixed,
  CSINC = ConditionalSelectFixed | B10,
  CSINV = ConditionalSelectFixed | B30,
  CSNEG = ConditionalSelectFixed | B10 | B30,
};

// C3.5.7
enum MiscDP1SourceOp {
  MiscDP1SourceMask = 0x5fe00000,
  MiscDP1SourceFixed = DPRegisterFixed | B30 | B28 | B23 | B22,
  CLZ = MiscDP1SourceFixed | B12,
  RBIT = MiscDP1SourceFixed,  // opc = '00'
};

// C3.5.8
enum MiscDP2SourceOp {
  MiscDP2SourceMask = 0x5fe00000,
  MiscDP2SourceFixed = DPRegisterFixed | B28 | B23 | B22,
  UDIV = MiscDP2SourceFixed | B11,
  SDIV = MiscDP2SourceFixed | B11 | B10,
  LSLV = MiscDP2SourceFixed | B13,
  LSRV = MiscDP2SourceFixed | B13 | B10,
  ASRV = MiscDP2SourceFixed | B13 | B11,
};

// C3.5.9
enum MiscDP3SourceOp {
  MiscDP3SourceMask = 0x1f000000,
  MiscDP3SourceFixed = DPRegisterFixed | B28 | B24,
  MADDW = MiscDP3SourceFixed,
  MADD = MiscDP3SourceFixed | B31,
  MSUBW = MiscDP3SourceFixed | B15,
  MSUB = MiscDP3SourceFixed | B31 | B15,
  SMULH = MiscDP3SourceFixed | B31 | B22,
  UMULH = MiscDP3SourceFixed | B31 | B23 | B22,
  SMADDL = MiscDP3SourceFixed | B31 | B21,
  UMADDL = MiscDP3SourceFixed | B31 | B23 | B21,
  SMSUBL = MiscDP3SourceFixed | B31 | B21 | B15,
  UMSUBL = MiscDP3SourceFixed | B31 | B23 | B21 | B15,
};

// C3.5.10
enum LogicalShiftOp {
  LogicalShiftMask = 0x1f000000,
  LogicalShiftFixed = DPRegisterFixed,
  AND = LogicalShiftFixed,
  BIC = LogicalShiftFixed | B21,
  ORR = LogicalShiftFixed | B29,
  ORN = LogicalShiftFixed | B29 | B21,
  EOR = LogicalShiftFixed | B30,
  EON = LogicalShiftFixed | B30 | B21,
  ANDS = LogicalShiftFixed | B30 | B29,
  BICS = LogicalShiftFixed | B30 | B29 | B21,
};

// C.3.6.5
enum SIMDCopyOp {
  SIMDCopyMask = 0x9fe08400,
  SIMDCopyFixed = DPSimd1Fixed | B10,
  VDUPI = SIMDCopyFixed | B30 | B11,
  VINSI = SIMDCopyFixed | B30 | B12 | B11,
  VMOVW = SIMDCopyFixed | B13 | B12 | B11,
  VMOVX = SIMDCopyFixed | B30 | B13 | B12 | B11,
  VDUP = SIMDCopyFixed | B30,
  VINS = SIMDCopyFixed | B30 | B29,
};

// C.3.6.16
enum SIMDThreeSameOp {
  SIMDThreeSameMask = 0x9f200400,
  SIMDThreeSameFixed = DPSimd1Fixed | B21 | B10,
  VAND = SIMDThreeSameFixed | B30 | B12 | B11,
  VORR = SIMDThreeSameFixed | B30 | B23 | B12 | B11,
  VEOR = SIMDThreeSameFixed | B30 | B29 | B12 | B11,
  VADDW = SIMDThreeSameFixed | B30 | B23 | B15,
  VADDX = SIMDThreeSameFixed | B30 | B23 | B22 | B15,
  VSUBW = SIMDThreeSameFixed | B30 | B29 | B23 | B15,
  VSUBX = SIMDThreeSameFixed | B30 | B29 | B23 | B22 | B15,
  VADDS = SIMDThreeSameFixed | B30 | B15 | B14 | B12,
  VADDD = SIMDThreeSameFixed | B30 | B22 | B15 | B14 | B12,
  VSUBS = SIMDThreeSameFixed | B30 | B23 | B15 | B14 | B12,
  VSUBD = SIMDThreeSameFixed | B30 | B23 | B22 | B15 | B14 | B12,
  VMULS = SIMDThreeSameFixed | B30 | B29 | B15 | B14 | B12 | B11,
  VMULD = SIMDThreeSameFixed | B30 | B29 | B22 | B15 | B14 | B12 | B11,
  VDIVS = SIMDThreeSameFixed | B30 | B29 | B15 | B14 | B13 | B12 | B11,
  VDIVD = SIMDThreeSameFixed | B30 | B29 | B22 | B15 | B14 | B13 | B12 | B11,
  VCEQS = SIMDThreeSameFixed | B30 | B15 | B14 | B13,
  VCEQD = SIMDThreeSameFixed | B30 | B22 | B15 | B14 | B13,
  VCGES = SIMDThreeSameFixed | B30 | B29 | B15 | B14 | B13,
  VCGED = SIMDThreeSameFixed | B30 | B29 | B22 | B15 | B14 | B13,
  VCGTS = SIMDThreeSameFixed | B30 | B29 | B23 | B15 | B14 | B13,
  VCGTD = SIMDThreeSameFixed | B30 | B29 | B23 | B22 | B15 | B14 | B13,
  VMAXS = SIMDThreeSameFixed | B30 | B15 | B14 | B13 | B12,
  VMAXD = SIMDThreeSameFixed | B30 | B22 | B15 | B14 | B13 | B12,
  VMINS = SIMDThreeSameFixed | B30 | B23 | B15 | B14 | B13 | B12,
  VMIND = SIMDThreeSameFixed | B30 | B23 | B22 | B15 | B14 | B13 | B12,
  VRECPSS = SIMDThreeSameFixed | B30 | B15 | B14 | B13 | B12 | B11,
  VRSQRTSS = SIMDThreeSameFixed | B30 | B23 | B15 | B14 | B13 | B12 | B11,
};

// C.3.6.17
enum SIMDTwoRegOp {
  SIMDTwoRegMask = 0x9f3e0c00,
  SIMDTwoRegFixed = DPSimd1Fixed | B21 | B11,
  VNOT = SIMDTwoRegFixed | B30 | B29 | B14 | B12,
  VABSS = SIMDTwoRegFixed | B30 | B23 | B15 | B14 | B13 | B12,
  VNEGS = SIMDTwoRegFixed | B30 | B29 | B23 | B15 | B14 | B13 | B12,
  VABSD = SIMDTwoRegFixed | B30 | B23 | B22 | B15 | B14 | B13 | B12,
  VNEGD = SIMDTwoRegFixed | B30 | B29 | B23 | B22 | B15 | B14 | B13 | B12,
  VSQRTS = SIMDTwoRegFixed | B30 | B29 | B23 | B16 | B15 | B14 | B13 | B12,
  VSQRTD =
      SIMDTwoRegFixed | B30 | B29 | B23 | B22 | B16 | B15 | B14 | B13 | B12,
  VRECPES = SIMDTwoRegFixed | B30 | B23 | B16 | B15 | B14 | B12,
  VRSQRTES = SIMDTwoRegFixed | B30 | B29 | B23 | B16 | B15 | B14 | B12,
};

// C.3.6.22
enum FPCompareOp {
  FPCompareMask = 0xffa0fc07,
  FPCompareFixed = FPFixed | B21 | B13,
  FCMPD = FPCompareFixed | B22,
  FCMPZD = FPCompareFixed | B22 | B3,
};

// C3.6.25
enum FPOneSourceOp {
  FPOneSourceMask = 0x5f207c00,
  FPOneSourceFixed = FPFixed | B21 | B14,
  FMOVDD = FPOneSourceFixed | B22,
  FABSD = FPOneSourceFixed | B22 | B15,
  FNEGD = FPOneSourceFixed | B22 | B16,
  FSQRTD = FPOneSourceFixed | B22 | B16 | B15,
  FCVTDS = FPOneSourceFixed | B15 | B17,
  FCVTSD = FPOneSourceFixed | B22 | B17,
};

// C3.6.26
enum FPTwoSourceOp {
  FPTwoSourceMask = 0xff200c00,
  FPTwoSourceFixed = FPFixed | B21 | B11,
  FMULD = FPTwoSourceFixed | B22,
  FDIVD = FPTwoSourceFixed | B22 | B12,
  FADDD = FPTwoSourceFixed | B22 | B13,
  FSUBD = FPTwoSourceFixed | B22 | B13 | B12,
};

// C3.6.28
enum FPImmOp {
  FPImmMask = 0x5f201c00,
  FPImmFixed = FPFixed | B21 | B12,
  FMOVSI = FPImmFixed,
  FMOVDI = FPImmFixed | B22,
};

// C3.6.30
enum FPIntCvtOp {
  FPIntCvtMask = 0x5f00fc00,
  FPIntCvtFixed = FPFixed | B21,
  FMOVRS = FPIntCvtFixed | B18 | B17,
  FMOVSR = FPIntCvtFixed | B18 | B17 | B16,
  FMOVRD = FPIntCvtFixed | B22 | B18 | B17,
  FMOVDR = FPIntCvtFixed | B22 | B18 | B17 | B16,
  FCVTZS_D = FPIntCvtFixed | B22 | B20 | B19,
  FCVTMS_D = FPIntCvtFixed | B22 | B20,
  FCVTPS_D = FPIntCvtFixed | B22 | B19,
  SCVTFD = FPIntCvtFixed | B22 | B17,
};

#define APPLY_OP_LIST(_V)                                                      \
  _V(DPImmediate)                                                              \
  _V(CompareBranch)                                                            \
  _V(LoadStore)                                                                \
  _V(DPRegister)                                                               \
  _V(DPSimd1)                                                                  \
  _V(DPSimd2)                                                                  \
  _V(FP)                                                                       \
  _V(CompareAndBranch)                                                         \
  _V(ConditionalBranch)                                                        \
  _V(ExceptionGen)                                                             \
  _V(System)                                                                   \
  _V(TestAndBranch)                                                            \
  _V(UnconditionalBranch)                                                      \
  _V(UnconditionalBranchReg)                                                   \
  _V(LoadStoreReg)                                                             \
  _V(LoadStoreRegPair)                                                         \
  _V(LoadRegLiteral)                                                           \
  _V(LoadStoreExclusive)                                                       \
  _V(AtomicMemory)                                                             \
  _V(AddSubImm)                                                                \
  _V(Bitfield)                                                                 \
  _V(LogicalImm)                                                               \
  _V(MoveWide)                                                                 \
  _V(PCRel)                                                                    \
  _V(AddSubShiftExt)                                                           \
  _V(AddSubWithCarry)                                                          \
  _V(ConditionalSelect)                                                        \
  _V(MiscDP1Source)                                                            \
  _V(MiscDP2Source)                                                            \
  _V(MiscDP3Source)                                                            \
  _V(LogicalShift)                                                             \
  _V(SIMDCopy)                                                                 \
  _V(SIMDThreeSame)                                                            \
  _V(SIMDTwoReg)                                                               \
  _V(FPCompare)                                                                \
  _V(FPOneSource)                                                              \
  _V(FPTwoSource)                                                              \
  _V(FPImm)                                                                    \
  _V(FPIntCvt)

enum Shift {
  kNoShift = -1,
  LSL = 0,  // Logical shift left
  LSR = 1,  // Logical shift right
  ASR = 2,  // Arithmetic shift right
  ROR = 3,  // Rotate right
  kMaxShift = 4,
};

enum Extend {
  kNoExtend = -1,
  UXTB = 0,  // Zero extend byte.
  UXTH = 1,  // Zero extend halfword (16 bits).
  UXTW = 2,  // Zero extend word (32 bits).
  UXTX = 3,  // Zero extend doubleword (64 bits).
  SXTB = 4,  // Sign extend byte.
  SXTH = 5,  // Sign extend halfword (16 bits).
  SXTW = 6,  // Sign extend word (32 bits).
  SXTX = 7,  // Sign extend doubleword (64 bits).
  kMaxExtend = 8,
};

enum R31Type {
  R31IsSP,
  R31IsZR,
};

// Constants used for the decoding or encoding of the individual fields of
// instructions. Based on the "Figure 3-1 ARM instruction set summary".
enum InstructionFields {
  // S-bit (modify condition register)
  kSShift = 29,
  kSBits = 1,

  // sf field.
  kSFShift = 31,
  kSFBits = 1,

  // size field,
  kSzShift = 30,
  kSzBits = 2,

  // Registers.
  kRdShift = 0,
  kRdBits = 5,
  kRnShift = 5,
  kRnBits = 5,
  kRaShift = 10,
  kRaBits = 5,
  kRmShift = 16,
  kRmBits = 5,
  kRtShift = 0,
  kRtBits = 5,
  kRt2Shift = 10,
  kRt2Bits = 5,
  kRsShift = 16,
  kRsBits = 5,

  // V Registers.
  kVdShift = 0,
  kVdBits = 5,
  kVnShift = 5,
  kVnBits = 5,
  kVmShift = 16,
  kVmBits = 5,
  kVtShift = 0,
  kVtBits = 5,
  kVt2Shift = 10,
  kVt2Bits = 5,

  // Immediates.
  kImm3Shift = 10,
  kImm3Bits = 3,
  kImm4Shift = 11,
  kImm4Bits = 4,
  kImm5Shift = 16,
  kImm5Bits = 5,
  kImm6Shift = 10,
  kImm6Bits = 6,
  kImm7Shift = 15,
  kImm7Bits = 7,
  kImm7Mask = 0x7f << kImm7Shift,
  kImm8Shift = 13,
  kImm8Bits = 8,
  kImm9Shift = 12,
  kImm9Bits = 9,
  kImm12Shift = 10,
  kImm12Bits = 12,
  kImm12Mask = 0xfff << kImm12Shift,
  kImm12ShiftShift = 22,
  kImm12ShiftBits = 2,
  kImm14Shift = 5,
  kImm14Bits = 14,
  kImm14Mask = 0x3fff << kImm14Shift,
  kImm16Shift = 5,
  kImm16Bits = 16,
  kImm16Mask = 0xffff << kImm16Shift,
  kImm19Shift = 5,
  kImm19Bits = 19,
  kImm19Mask = 0x7ffff << kImm19Shift,
  kImm26Shift = 0,
  kImm26Bits = 26,
  kImm26Mask = 0x03ffffff << kImm26Shift,

  kCondShift = 0,
  kCondBits = 4,
  kCondMask = 0xf << kCondShift,

  kSelCondShift = 12,
  kSelCondBits = 4,

  // Bitfield immediates.
  kNShift = 22,
  kNBits = 1,
  kImmRShift = 16,
  kImmRBits = 6,
  kImmSShift = 10,
  kImmSBits = 6,

  kHWShift = 21,
  kHWBits = 2,

  // Shift and Extend.
  kAddShiftExtendShift = 21,
  kAddShiftExtendBits = 1,
  kShiftTypeShift = 22,
  kShiftTypeBits = 2,
  kExtendTypeShift = 13,
  kExtendTypeBits = 3,

  // Hint Fields.
  kHintCRmShift = 8,
  kHintCRmBits = 4,
  kHintOp2Shift = 5,
  kHintOp2Bits = 3,
};

// Helper functions for decoding logical immediates.
static inline uint64_t RotateRight(uint64_t value,
                                   uint8_t rotate,
                                   uint8_t width) {
  ASSERT(width <= 64);
  uint8_t right = rotate & 63;
  uint8_t left = (width - rotate) & 63;
  return ((value & ((1ULL << right) - 1ULL)) << left) | (value >> right);
}

static inline uint64_t RepeatBitsAcrossReg(uint8_t reg_size,
                                           uint64_t value,
                                           uint8_t width) {
  ASSERT((width == 2) || (width == 4) || (width == 8) || (width == 16) ||
         (width == 32));
  ASSERT((reg_size == kWRegSizeInBits) || (reg_size == kXRegSizeInBits));
  uint64_t result = value & ((1ULL << width) - 1ULL);
  for (unsigned i = width; i < reg_size; i *= 2) {
    result |= (result << i);
  }
  return result;
}

enum ScaleFactor {
  TIMES_1 = 0,
  TIMES_2 = 1,
  TIMES_4 = 2,
  TIMES_8 = 3,
  TIMES_16 = 4,
// We can't include vm/compiler/runtime_api.h, so just be explicit instead
// of using (dart::)kWordSizeLog2.
#if defined(TARGET_ARCH_IS_64_BIT)
  // Used for Smi-boxed indices.
  TIMES_HALF_WORD_SIZE = kInt64SizeLog2 - 1,
  // Used for unboxed indices.
  TIMES_WORD_SIZE = kInt64SizeLog2,
#else
#error "Unexpected word size"
#endif
#if !defined(DART_COMPRESSED_POINTERS)
  TIMES_COMPRESSED_WORD_SIZE = TIMES_WORD_SIZE,
#else
  TIMES_COMPRESSED_WORD_SIZE = TIMES_HALF_WORD_SIZE,
#endif
  // Used for Smi-boxed indices.
  TIMES_COMPRESSED_HALF_WORD_SIZE = TIMES_COMPRESSED_WORD_SIZE - 1,
};

// The class Instr enables access to individual fields defined in the ARM
// architecture instruction set encoding as described in figure A3-1.
//
// Example: Test whether the instruction at ptr sets the condition code bits.
//
// bool InstructionSetsConditionCodes(byte* ptr) {
//   Instr* instr = Instr::At(ptr);
//   int type = instr->TypeField();
//   return ((type == 0) || (type == 1)) && instr->HasS();
// }
//
class Instr {
 public:
  enum { kInstrSize = 4, kInstrSizeLog2 = 2, kPCReadOffset = 8 };

  enum class WideSize { k32Bits, k64Bits };

  static constexpr int32_t kNopInstruction = HINT;  // hint #0 === nop.

  // Reserved brk and hlt instruction codes.
  static constexpr int32_t kBreakPointCode = 0xdeb0;  // For breakpoint.
  static constexpr int32_t kSimulatorBreakCode =
      0xdeb2;  // For breakpoint in sim.
  static constexpr int32_t kSimulatorRedirectCode = 0xca11;  // For redirection.
  static constexpr int32_t kSimulatorFfiRedirectCode =
      0xca12;  // For redirection.

  // Breakpoint instruction filling assembler code buffers in debug mode.
  static constexpr int32_t kBreakPointInstruction =  // brk(0xdeb0).
      BRK | (kBreakPointCode << kImm16Shift);

  // Breakpoint instruction used by the simulator.
  // Should be distinct from kBreakPointInstruction and from a typical user
  // breakpoint inserted in generated code for debugging, e.g. brk(0).
  static constexpr int32_t kSimulatorBreakpointInstruction =
      HLT | (kSimulatorBreakCode << kImm16Shift);

  // Runtime call redirection instruction used by the simulator.
  static constexpr int32_t kSimulatorRedirectInstruction =
      HLT | (kSimulatorRedirectCode << kImm16Shift);
  static constexpr int32_t kSimulatorFfiRedirectInstruction =
      HLT | (kSimulatorFfiRedirectCode << kImm16Shift);

  // Read one particular bit out of the instruction bits.
  inline int Bit(int nr) const { return (InstructionBits() >> nr) & 1; }

  // Read a bit field out of the instruction bits.
  inline int Bits(int shift, int count) const {
    return (InstructionBits() >> shift) & ((1 << count) - 1);
  }

  // Get the raw instruction bits.
  inline int32_t InstructionBits() const {
    return *reinterpret_cast<const int32_t*>(this);
  }

  // Set the raw instruction bits to value.
  inline void SetInstructionBits(int32_t value) {
    *reinterpret_cast<int32_t*>(this) = value;
  }

  inline void SetMoveWideBits(MoveWideOp op,
                              Register rd,
                              uint16_t imm,
                              int hw,
                              WideSize sz) {
    ASSERT((hw >= 0) && (hw <= 3));
    const int32_t size = (sz == WideSize::k64Bits) ? B31 : 0;
    SetInstructionBits(op | size | (static_cast<int32_t>(rd) << kRdShift) |
                       (static_cast<int32_t>(hw) << kHWShift) |
                       (static_cast<int32_t>(imm) << kImm16Shift));
  }

  inline void SetUnconditionalBranchRegBits(UnconditionalBranchRegOp op,
                                            Register rn) {
    SetInstructionBits(op | (static_cast<int32_t>(rn) << kRnShift));
  }

  inline void SetImm12Bits(int32_t orig, int32_t imm12) {
    ASSERT((imm12 & 0xfffff000) == 0);
    SetInstructionBits((orig & ~kImm12Mask) | (imm12 << kImm12Shift));
  }

  inline int NField() const { return Bit(22); }
  inline int SField() const { return Bit(kSShift); }
  inline int SFField() const { return Bit(kSFShift); }
  inline int SzField() const { return Bits(kSzShift, kSzBits); }
  inline Register RdField() const {
    return static_cast<Register>(Bits(kRdShift, kRdBits));
  }
  inline Register RnField() const {
    return static_cast<Register>(Bits(kRnShift, kRnBits));
  }
  inline Register RaField() const {
    return static_cast<Register>(Bits(kRaShift, kRaBits));
  }
  inline Register RmField() const {
    return static_cast<Register>(Bits(kRmShift, kRmBits));
  }
  inline Register RtField() const {
    return static_cast<Register>(Bits(kRtShift, kRtBits));
  }
  inline Register Rt2Field() const {
    return static_cast<Register>(Bits(kRt2Shift, kRt2Bits));
  }
  inline Register RsField() const {
    return static_cast<Register>(Bits(kRsShift, kRsBits));
  }

  inline VRegister VdField() const {
    return static_cast<VRegister>(Bits(kVdShift, kVdBits));
  }
  inline VRegister VnField() const {
    return static_cast<VRegister>(Bits(kVnShift, kVnBits));
  }
  inline VRegister VmField() const {
    return static_cast<VRegister>(Bits(kVmShift, kVmBits));
  }
  inline VRegister VtField() const {
    return static_cast<VRegister>(Bits(kVtShift, kVtBits));
  }
  inline VRegister Vt2Field() const {
    return static_cast<VRegister>(Bits(kVt2Shift, kVt2Bits));
  }

  // Immediates
  inline int Imm3Field() const { return Bits(kImm3Shift, kImm3Bits); }
  inline int Imm6Field() const { return Bits(kImm6Shift, kImm6Bits); }
  inline int Imm7Field() const { return Bits(kImm7Shift, kImm7Bits); }
  // Sign-extended Imm7Field()
  inline int64_t SImm7Field() const {
    return (static_cast<int32_t>(Imm7Field()) << 25) >> 25;
  }
  inline int Imm8Field() const { return Bits(kImm8Shift, kImm8Bits); }
  inline int Imm9Field() const { return Bits(kImm9Shift, kImm9Bits); }
  // Sign-extended Imm9Field()
  inline int64_t SImm9Field() const {
    return (static_cast<int32_t>(Imm9Field()) << 23) >> 23;
  }

  inline int Imm12Field() const { return Bits(kImm12Shift, kImm12Bits); }
  inline int Imm12ShiftField() const {
    return Bits(kImm12ShiftShift, kImm12ShiftBits);
  }

  inline int Imm16Field() const { return Bits(kImm16Shift, kImm16Bits); }
  inline int HWField() const { return Bits(kHWShift, kHWBits); }

  inline int ImmRField() const { return Bits(kImmRShift, kImmRBits); }
  inline int ImmSField() const { return Bits(kImmSShift, kImmSBits); }

  inline int Imm14Field() const { return Bits(kImm14Shift, kImm14Bits); }
  inline int64_t SImm14Field() const {
    return (static_cast<int32_t>(Imm14Field()) << 18) >> 18;
  }
  inline int Imm19Field() const { return Bits(kImm19Shift, kImm19Bits); }
  inline int64_t SImm19Field() const {
    return (static_cast<int32_t>(Imm19Field()) << 13) >> 13;
  }
  inline int Imm26Field() const { return Bits(kImm26Shift, kImm26Bits); }
  inline int64_t SImm26Field() const {
    return (static_cast<int32_t>(Imm26Field()) << 6) >> 6;
  }

  inline Condition ConditionField() const {
    return static_cast<Condition>(Bits(kCondShift, kCondBits));
  }
  inline Condition SelectConditionField() const {
    return static_cast<Condition>(Bits(kSelCondShift, kSelCondBits));
  }

  // Shift and Extend.
  inline bool IsShift() const {
    return IsLogicalShiftOp() || (Bit(kAddShiftExtendShift) == 0);
  }
  inline bool IsExtend() const {
    return !IsLogicalShiftOp() && (Bit(kAddShiftExtendShift) == 1);
  }
  inline Shift ShiftTypeField() const {
    return static_cast<Shift>(Bits(kShiftTypeShift, kShiftTypeBits));
  }
  inline Extend ExtendTypeField() const {
    return static_cast<Extend>(Bits(kExtendTypeShift, kExtendTypeBits));
  }
  inline int ShiftAmountField() const { return Imm6Field(); }
  inline int ExtShiftAmountField() const { return Imm3Field(); }

// Instruction identification.
#define IS_OP(op)                                                              \
  inline bool Is##op##Op() const {                                             \
    return ((InstructionBits() & op##Mask) == (op##Fixed & op##Mask));         \
  }
  APPLY_OP_LIST(IS_OP)
#undef IS_OP

  inline bool HasS() const { return (SField() == 1); }

  // Indicate whether Rd can be the CSP or ZR. This does not check that the
  // instruction actually has an Rd field.
  R31Type RdMode() const {
    // The following instructions use CSP as Rd:
    //  Add/sub (immediate) when not setting the flags.
    //  Add/sub (extended) when not setting the flags.
    //  Logical (immediate) when not setting the flags.
    // Otherwise, R31 is the ZR.
    if (IsAddSubImmOp() || (IsAddSubShiftExtOp() && IsExtend())) {
      if (HasS()) {
        return R31IsZR;
      } else {
        return R31IsSP;
      }
    }
    if (IsLogicalImmOp()) {
      const int op = Bits(29, 2);
      const bool set_flags = op == 3;
      if (set_flags) {
        return R31IsZR;
      } else {
        return R31IsSP;
      }
    }
    return R31IsZR;
  }

  // Indicate whether Rn can be CSP or ZR. This does not check that the
  // instruction actually has an Rn field.
  R31Type RnMode() const {
    // The following instructions use CSP as Rn:
    //  All loads and stores.
    //  Add/sub (immediate).
    //  Add/sub (extended).
    // Otherwise, r31 is ZR.
    if (IsLoadStoreOp() || IsAddSubImmOp() ||
        (IsAddSubShiftExtOp() && IsExtend())) {
      return R31IsSP;
    }
    return R31IsZR;
  }

  // Logical immediates can't encode zero, so a return value of zero is used to
  // indicate a failure case. Specifically, where the constraints on imm_s are
  // not met.
  uint64_t ImmLogical() {
    const uint8_t reg_size = SFField() == 1 ? kXRegSizeInBits : kWRegSizeInBits;
    const int64_t n = NField();
    const int64_t imm_s = ImmSField();
    const int64_t imm_r = ImmRField();

    // An integer is constructed from the n, imm_s and imm_r bits according to
    // the following table:
    //
    //  N   imms    immr    size        S             R
    //  1  ssssss  rrrrrr    64    UInt(ssssss)  UInt(rrrrrr)
    //  0  0sssss  xrrrrr    32    UInt(sssss)   UInt(rrrrr)
    //  0  10ssss  xxrrrr    16    UInt(ssss)    UInt(rrrr)
    //  0  110sss  xxxrrr     8    UInt(sss)     UInt(rrr)
    //  0  1110ss  xxxxrr     4    UInt(ss)      UInt(rr)
    //  0  11110s  xxxxxr     2    UInt(s)       UInt(r)
    // (s bits must not be all set)
    //
    // A pattern is constructed of size bits, where the least significant S+1
    // bits are set. The pattern is rotated right by R, and repeated across a
    // 32 or 64-bit value, depending on destination register width.

    if (n == 1) {
      if (imm_s == 0x3F) {
        return 0;
      }
      uint64_t bits = (1ULL << (imm_s + 1)) - 1;
      return RotateRight(bits, imm_r, 64);
    } else {
      if ((imm_s >> 1) == 0x1F) {
        return 0;
      }
      for (int width = 0x20; width >= 0x2; width >>= 1) {
        if ((imm_s & width) == 0) {
          int mask = width - 1;
          if ((imm_s & mask) == mask) {
            return 0;
          }
          uint64_t bits = (1ULL << ((imm_s & mask) + 1)) - 1;
          return RepeatBitsAcrossReg(
              reg_size, RotateRight(bits, imm_r & mask, width), width);
        }
      }
    }
    UNREACHABLE();
    return 0;
  }

  static int64_t VFPExpandImm(uint8_t imm8) {
    const int64_t sign = static_cast<int64_t>((imm8 & 0x80) >> 7) << 63;
    const int64_t hi_exp = static_cast<int64_t>(!((imm8 & 0x40) >> 6)) << 62;
    const int64_t mid_exp = (((imm8 & 0x40) >> 6) == 0) ? 0 : (0xffLL << 54);
    const int64_t low_exp = static_cast<int64_t>((imm8 & 0x30) >> 4) << 52;
    const int64_t frac = static_cast<int64_t>(imm8 & 0x0f) << 48;
    return sign | hi_exp | mid_exp | low_exp | frac;
  }

  // Instructions are read out of a code stream. The only way to get a
  // reference to an instruction is to convert a pointer. There is no way
  // to allocate or create instances of class Instr.
  // Use the At(pc) function to create references to Instr.
  static Instr* At(uword pc) { return reinterpret_cast<Instr*>(pc); }

 private:
  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Instr);
};

const uint64_t kBreakInstructionFiller = 0xD4200000D4200000L;  // brk #0; brk #0
constexpr int32_t kDataMemoryBarrier = 0xD5033BBF;             // dmb ish

struct LinkRegister {};

constexpr bool operator==(Register r, LinkRegister) {
  return r == LR;
}

constexpr bool operator!=(Register r, LinkRegister lr) {
  return !(r == lr);
}

inline Register ConcreteRegister(LinkRegister) {
  return LR;
}

#undef LR

#define LINK_REGISTER (LinkRegister())

// There are many different ARM64 CPUs out there with different alignment
// requirements which are mostly not very well documented.
//
// Apple Silicon CPU Optimization Guide explicitly discourages alignment of
// branch targets (see section 4.4.3).
//
// Aligning to 32 seems like a safe bet based on LLVM's implementation:
//
//    https://github.com/llvm/llvm-project/blob/05c1447b3eabe9cc4a27866094e46c57350c5d5a/llvm/lib/Target/AArch64/AArch64Subtarget.cpp#L107
//
#if defined(DART_TARGET_OS_MACOS_IOS) || defined(DART_TARGET_OS_MACOS)
const intptr_t kPreferredLoopAlignment = 1;
#else
const intptr_t kPreferredLoopAlignment = 32;
#endif

}  // namespace dart

#endif  // RUNTIME_VM_CONSTANTS_ARM64_H_
