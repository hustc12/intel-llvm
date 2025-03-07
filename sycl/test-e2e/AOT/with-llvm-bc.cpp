//==----- with-llvm-bc.cpp - SYCL kernel with LLVM IR bitcode as binary ----==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

// Only CPU supports LLVM IR bitcode as a binary
// REQUIRES: cpu, dump_ir

// RUN: %clangxx -fsycl -fsycl-targets=spir64 -c %S/Inputs/aot.cpp -o %t.o
// RUN: %clangxx -fsycl -fsycl-link-targets=spir64 %t.o -o %t.spv
// RUN: llvm-spirv -r %t.spv -o %t.bc
// RUN: %clangxx -fsycl -fsycl-add-targets=spir64:%t.bc %t.o -o %t.out
//
// RUN: %{run} %t.out
