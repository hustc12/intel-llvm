; Test to ensure that comdat is renamed consistently when comdat leader is
; promoted and renamed due to an import. Required by COFF.

; REQUIRES: x86-registered-target

; RUN: opt -opaque-pointers -thinlto-bc -o %t1.bc %s
; RUN: opt -opaque-pointers -thinlto-bc -o %t2.bc %S/Inputs/comdat.ll
; RUN: llvm-lto2 run -opaque-pointers -save-temps -o %t3 %t1.bc %t2.bc \
; RUN:          -r %t1.bc,lwt_fun,plx \
; RUN:          -r %t2.bc,main,plx \
; RUN:          -r %t2.bc,lwt_fun,
; RUN: llvm-dis -o - %t3.1.3.import.bc | FileCheck %s

target datalayout = "e-m:w-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-windows-msvc19.0.24215"

; CHECK: $lwt.llvm.[[HASH:[0-9]+]] = comdat any
$lwt = comdat any

; CHECK: @lwt_aliasee = private unnamed_addr global {{.*}}, comdat($lwt.llvm.[[HASH]])
@lwt_aliasee = private unnamed_addr global [1 x ptr] [ptr null], comdat($lwt)

; CHECK: @lwt.llvm.[[HASH]] = hidden unnamed_addr alias
@lwt = internal unnamed_addr alias [1 x ptr], ptr @lwt_aliasee

; Below function should get imported into other module, resulting in @lwt being
; promoted and renamed.
define ptr @lwt_fun() {
  %1 = load ptr, ptr @lwt
  ret ptr %1
}
