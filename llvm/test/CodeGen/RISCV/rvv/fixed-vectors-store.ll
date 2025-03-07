; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py UTC_ARGS: --version 2
; RUN: llc -mtriple=riscv32 -mattr=+v,+zfh,+experimental-zvfh -verify-machineinstrs < %s | FileCheck -check-prefixes=CHECK,RV32 %s
; RUN: llc -mtriple=riscv64 -mattr=+v,+zfh,+experimental-zvfh -verify-machineinstrs < %s | FileCheck -check-prefixes=CHECK,RV64 %s

define void @store_v5i8(ptr %p, <5 x i8> %v) {
; CHECK-LABEL: store_v5i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e8, mf2, ta, ma
; CHECK-NEXT:    vslidedown.vi v9, v8, 4
; CHECK-NEXT:    addi a1, a0, 4
; CHECK-NEXT:    vse8.v v9, (a1)
; CHECK-NEXT:    vsetivli zero, 1, e32, mf2, ta, ma
; CHECK-NEXT:    vse32.v v8, (a0)
; CHECK-NEXT:    ret
  store <5 x i8> %v, ptr %p
  ret void
}

define void @store_v5i8_align1(ptr %p, <5 x i8> %v) {
; CHECK-LABEL: store_v5i8_align1:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e8, mf2, ta, ma
; CHECK-NEXT:    vslidedown.vi v9, v8, 4
; CHECK-NEXT:    addi a1, a0, 4
; CHECK-NEXT:    vse8.v v9, (a1)
; CHECK-NEXT:    vsetivli zero, 0, e32, mf2, ta, ma
; CHECK-NEXT:    vmv.x.s a1, v8
; CHECK-NEXT:    sb a1, 0(a0)
; CHECK-NEXT:    srli a2, a1, 24
; CHECK-NEXT:    sb a2, 3(a0)
; CHECK-NEXT:    srli a2, a1, 16
; CHECK-NEXT:    sb a2, 2(a0)
; CHECK-NEXT:    srli a1, a1, 8
; CHECK-NEXT:    sb a1, 1(a0)
; CHECK-NEXT:    ret
  store <5 x i8> %v, ptr %p, align 1
  ret void
}


define void @store_v6i8(ptr %p, <6 x i8> %v) {
; CHECK-LABEL: store_v6i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 1, e32, mf2, ta, ma
; CHECK-NEXT:    vse32.v v8, (a0)
; CHECK-NEXT:    vsetivli zero, 1, e16, mf2, ta, ma
; CHECK-NEXT:    vslidedown.vi v8, v8, 2
; CHECK-NEXT:    addi a0, a0, 4
; CHECK-NEXT:    vse16.v v8, (a0)
; CHECK-NEXT:    ret
  store <6 x i8> %v, ptr %p
  ret void
}

define void @store_v12i8(ptr %p, <12 x i8> %v) {
; RV32-LABEL: store_v12i8:
; RV32:       # %bb.0:
; RV32-NEXT:    vsetivli zero, 1, e32, m1, ta, ma
; RV32-NEXT:    vslidedown.vi v9, v8, 2
; RV32-NEXT:    addi a1, a0, 8
; RV32-NEXT:    vse32.v v9, (a1)
; RV32-NEXT:    vsetivli zero, 8, e8, mf2, ta, ma
; RV32-NEXT:    vse8.v v8, (a0)
; RV32-NEXT:    ret
;
; RV64-LABEL: store_v12i8:
; RV64:       # %bb.0:
; RV64-NEXT:    vsetivli zero, 1, e64, m1, ta, ma
; RV64-NEXT:    vse64.v v8, (a0)
; RV64-NEXT:    vsetivli zero, 1, e32, m1, ta, ma
; RV64-NEXT:    vslidedown.vi v8, v8, 2
; RV64-NEXT:    addi a0, a0, 8
; RV64-NEXT:    vse32.v v8, (a0)
; RV64-NEXT:    ret
  store <12 x i8> %v, ptr %p
  ret void
}

define void @store_v6i16(ptr %p, <6 x i16> %v) {
; RV32-LABEL: store_v6i16:
; RV32:       # %bb.0:
; RV32-NEXT:    vsetivli zero, 1, e32, m1, ta, ma
; RV32-NEXT:    vslidedown.vi v9, v8, 2
; RV32-NEXT:    addi a1, a0, 8
; RV32-NEXT:    vse32.v v9, (a1)
; RV32-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; RV32-NEXT:    vse16.v v8, (a0)
; RV32-NEXT:    ret
;
; RV64-LABEL: store_v6i16:
; RV64:       # %bb.0:
; RV64-NEXT:    vsetivli zero, 1, e64, m1, ta, ma
; RV64-NEXT:    vse64.v v8, (a0)
; RV64-NEXT:    vsetivli zero, 1, e32, m1, ta, ma
; RV64-NEXT:    vslidedown.vi v8, v8, 2
; RV64-NEXT:    addi a0, a0, 8
; RV64-NEXT:    vse32.v v8, (a0)
; RV64-NEXT:    ret
  store <6 x i16> %v, ptr %p
  ret void
}

define void @store_v6f16(ptr %p, <6 x half> %v) {
; RV32-LABEL: store_v6f16:
; RV32:       # %bb.0:
; RV32-NEXT:    vsetivli zero, 1, e32, m1, ta, ma
; RV32-NEXT:    vslidedown.vi v9, v8, 2
; RV32-NEXT:    addi a1, a0, 8
; RV32-NEXT:    vse32.v v9, (a1)
; RV32-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; RV32-NEXT:    vse16.v v8, (a0)
; RV32-NEXT:    ret
;
; RV64-LABEL: store_v6f16:
; RV64:       # %bb.0:
; RV64-NEXT:    vsetivli zero, 1, e64, m1, ta, ma
; RV64-NEXT:    vse64.v v8, (a0)
; RV64-NEXT:    vsetivli zero, 1, e32, m1, ta, ma
; RV64-NEXT:    vslidedown.vi v8, v8, 2
; RV64-NEXT:    addi a0, a0, 8
; RV64-NEXT:    vse32.v v8, (a0)
; RV64-NEXT:    ret
  store <6 x half> %v, ptr %p
  ret void
}

define void @store_v6f32(ptr %p, <6 x float> %v) {
; RV32-LABEL: store_v6f32:
; RV32:       # %bb.0:
; RV32-NEXT:    vsetivli zero, 2, e32, m2, ta, ma
; RV32-NEXT:    vslidedown.vi v10, v8, 4
; RV32-NEXT:    addi a1, a0, 16
; RV32-NEXT:    vsetivli zero, 2, e32, mf2, ta, ma
; RV32-NEXT:    vse32.v v10, (a1)
; RV32-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV32-NEXT:    vse32.v v8, (a0)
; RV32-NEXT:    ret
;
; RV64-LABEL: store_v6f32:
; RV64:       # %bb.0:
; RV64-NEXT:    vsetivli zero, 1, e64, m2, ta, ma
; RV64-NEXT:    vslidedown.vi v10, v8, 2
; RV64-NEXT:    addi a1, a0, 16
; RV64-NEXT:    vse64.v v10, (a1)
; RV64-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; RV64-NEXT:    vse32.v v8, (a0)
; RV64-NEXT:    ret
  store <6 x float> %v, ptr %p
  ret void
}

define void @store_v6f64(ptr %p, <6 x double> %v) {
; CHECK-LABEL: store_v6f64:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e64, m4, ta, ma
; CHECK-NEXT:    vslidedown.vi v12, v8, 4
; CHECK-NEXT:    addi a1, a0, 32
; CHECK-NEXT:    vsetivli zero, 2, e64, m1, ta, ma
; CHECK-NEXT:    vse64.v v12, (a1)
; CHECK-NEXT:    vsetivli zero, 4, e64, m2, ta, ma
; CHECK-NEXT:    vse64.v v8, (a0)
; CHECK-NEXT:    ret
  store <6 x double> %v, ptr %p
  ret void
}

define void @store_v6i1(ptr %p, <6 x i1> %v) {
; CHECK-LABEL: store_v6i1:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 8, e8, mf2, ta, ma
; CHECK-NEXT:    vfirst.m a1, v0
; CHECK-NEXT:    seqz a1, a1
; CHECK-NEXT:    vmv.x.s a2, v0
; CHECK-NEXT:    andi a3, a2, 2
; CHECK-NEXT:    or a1, a1, a3
; CHECK-NEXT:    andi a3, a2, 4
; CHECK-NEXT:    andi a4, a2, 8
; CHECK-NEXT:    or a3, a3, a4
; CHECK-NEXT:    or a1, a1, a3
; CHECK-NEXT:    andi a3, a2, 16
; CHECK-NEXT:    andi a2, a2, -32
; CHECK-NEXT:    or a2, a3, a2
; CHECK-NEXT:    or a1, a1, a2
; CHECK-NEXT:    andi a1, a1, 63
; CHECK-NEXT:    sb a1, 0(a0)
; CHECK-NEXT:    ret
  store <6 x i1> %v, ptr %p
  ret void
}

define void @store_constant_v2i8(ptr %p) {
; CHECK-LABEL: store_constant_v2i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    li a1, 1539
; CHECK-NEXT:    sh a1, 0(a0)
; CHECK-NEXT:    ret
  store <2 x i8> <i8 3, i8 6>, ptr %p
  ret void
}

define void @store_constant_v2i16(ptr %p) {
; RV32-LABEL: store_constant_v2i16:
; RV32:       # %bb.0:
; RV32-NEXT:    lui a1, 96
; RV32-NEXT:    addi a1, a1, 3
; RV32-NEXT:    sw a1, 0(a0)
; RV32-NEXT:    ret
;
; RV64-LABEL: store_constant_v2i16:
; RV64:       # %bb.0:
; RV64-NEXT:    lui a1, 96
; RV64-NEXT:    addiw a1, a1, 3
; RV64-NEXT:    sw a1, 0(a0)
; RV64-NEXT:    ret
  store <2 x i16> <i16 3, i16 6>, ptr %p
  ret void
}

define void @store_constant_v2i32(ptr %p) {
; CHECK-LABEL: store_constant_v2i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e32, mf2, ta, ma
; CHECK-NEXT:    vmv.v.i v8, 3
; CHECK-NEXT:    vid.v v9
; CHECK-NEXT:    li a1, 3
; CHECK-NEXT:    vmadd.vx v9, a1, v8
; CHECK-NEXT:    vse32.v v9, (a0)
; CHECK-NEXT:    ret
  store <2 x i32> <i32 3, i32 6>, ptr %p
  ret void
}

define void @store_constant_v4i8(ptr %p) {
; RV32-LABEL: store_constant_v4i8:
; RV32:       # %bb.0:
; RV32-NEXT:    lui a1, 4176
; RV32-NEXT:    addi a1, a1, 1539
; RV32-NEXT:    sw a1, 0(a0)
; RV32-NEXT:    ret
;
; RV64-LABEL: store_constant_v4i8:
; RV64:       # %bb.0:
; RV64-NEXT:    lui a1, 4176
; RV64-NEXT:    addiw a1, a1, 1539
; RV64-NEXT:    sw a1, 0(a0)
; RV64-NEXT:    ret
  store <4 x i8> <i8 3, i8 6, i8 5, i8 1>, ptr %p
  ret void
}

define void @store_constant_v4i16(ptr %p) {
; CHECK-LABEL: store_constant_v4i16:
; CHECK:       # %bb.0:
; CHECK-NEXT:    lui a1, %hi(.LCPI13_0)
; CHECK-NEXT:    addi a1, a1, %lo(.LCPI13_0)
; CHECK-NEXT:    vsetivli zero, 4, e16, mf2, ta, ma
; CHECK-NEXT:    vle16.v v8, (a1)
; CHECK-NEXT:    vse16.v v8, (a0)
; CHECK-NEXT:    ret
  store <4 x i16> <i16 3, i16 6, i16 5, i16 1>, ptr %p
  ret void
}

define void @store_constant_v4i32(ptr %p) {
; CHECK-LABEL: store_constant_v4i32:
; CHECK:       # %bb.0:
; CHECK-NEXT:    lui a1, %hi(.LCPI14_0)
; CHECK-NEXT:    addi a1, a1, %lo(.LCPI14_0)
; CHECK-NEXT:    vsetivli zero, 4, e32, m1, ta, ma
; CHECK-NEXT:    vle32.v v8, (a1)
; CHECK-NEXT:    vse32.v v8, (a0)
; CHECK-NEXT:    ret
  store <4 x i32> <i32 3, i32 6, i32 5, i32 1>, ptr %p
  ret void
}

define void @store_id_v4i8(ptr %p) {
; RV32-LABEL: store_id_v4i8:
; RV32:       # %bb.0:
; RV32-NEXT:    lui a1, 12320
; RV32-NEXT:    addi a1, a1, 256
; RV32-NEXT:    sw a1, 0(a0)
; RV32-NEXT:    ret
;
; RV64-LABEL: store_id_v4i8:
; RV64:       # %bb.0:
; RV64-NEXT:    lui a1, 12320
; RV64-NEXT:    addiw a1, a1, 256
; RV64-NEXT:    sw a1, 0(a0)
; RV64-NEXT:    ret
  store <4 x i8> <i8 0, i8 1, i8 2, i8 3>, ptr %p
  ret void
}

define void @store_constant_v2i8_align1(ptr %p) {
; CHECK-LABEL: store_constant_v2i8_align1:
; CHECK:       # %bb.0:
; CHECK-NEXT:    vsetivli zero, 2, e8, mf8, ta, ma
; CHECK-NEXT:    vmv.v.i v8, 3
; CHECK-NEXT:    vid.v v9
; CHECK-NEXT:    li a1, 3
; CHECK-NEXT:    vmadd.vx v9, a1, v8
; CHECK-NEXT:    vse8.v v9, (a0)
; CHECK-NEXT:    ret
  store <2 x i8> <i8 3, i8 6>, ptr %p, align 1
  ret void
}

define void @store_constant_splat_v2i8(ptr %p) {
; CHECK-LABEL: store_constant_splat_v2i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    li a1, 771
; CHECK-NEXT:    sh a1, 0(a0)
; CHECK-NEXT:    ret
  store <2 x i8> <i8 3, i8 3>, ptr %p
  ret void
}

define void @store_constant_undef_v2i8(ptr %p) {
; CHECK-LABEL: store_constant_undef_v2i8:
; CHECK:       # %bb.0:
; CHECK-NEXT:    li a1, 768
; CHECK-NEXT:    sh a1, 0(a0)
; CHECK-NEXT:    ret
  store <2 x i8> <i8 undef, i8 3>, ptr %p
  ret void
}
