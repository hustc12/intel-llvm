set(LLVM_LINK_COMPONENTS
  ${LLVM_TARGETS_TO_BUILD}
  Analysis
  AsmParser
  AsmPrinter
  CodeGen
  CodeGenTypes
  Core
  FileCheck
  MC
  MIRParser
  Passes
  SelectionDAG
  Support
  SYCLLowerIR
  Target
  TargetParser
  )

add_llvm_unittest(CodeGenTests
  AArch64SelectionDAGTest.cpp
  AllocationOrderTest.cpp
  AMDGPUMetadataTest.cpp
  AsmPrinterDwarfTest.cpp
  CCStateTest.cpp
  DIEHashTest.cpp
  DIETest.cpp
  DwarfStringPoolEntryRefTest.cpp
  InstrRefLDVTest.cpp
  LowLevelTypeTest.cpp
  LexicalScopesTest.cpp
  MachineBasicBlockTest.cpp
  MachineInstrBundleIteratorTest.cpp
  MachineInstrTest.cpp
  MachineOperandTest.cpp
  RegAllocScoreTest.cpp
  PassManagerTest.cpp
  ScalableVectorMVTsTest.cpp
  SelectionDAGAddressAnalysisTest.cpp
  TypeTraitsTest.cpp
  TargetOptionsTest.cpp
  TestAsmPrinter.cpp
  MLRegallocDevelopmentFeatures.cpp
  )

add_subdirectory(GlobalISel)

target_link_libraries(CodeGenTests PRIVATE LLVMTestingSupport)
