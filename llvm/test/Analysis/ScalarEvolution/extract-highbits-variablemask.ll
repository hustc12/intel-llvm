; NOTE: Assertions have been autogenerated by utils/update_analyze_test_checks.py
; RUN: opt -S -disable-output "-passes=print<scalar-evolution>" < %s 2>&1 | FileCheck %s

; These testcases aren't *identical* but they have the same/similar meaning.

; The obvious case.
define i32 @div(i32 %val, i32 %num) nounwind {
; CHECK-LABEL: 'div'
; CHECK-NEXT:  Classifying expressions for: @div
; CHECK-NEXT:    %tmp1 = udiv i32 %val, %num
; CHECK-NEXT:    --> (%val /u %num) U: full-set S: full-set
; CHECK-NEXT:    %tmp2 = mul i32 %tmp1, %num
; CHECK-NEXT:    --> ((%val /u %num) * %num)<nuw> U: full-set S: full-set
; CHECK-NEXT:  Determining loop execution counts for: @div
;
  %tmp1 = udiv i32 %val, %num
  %tmp2 = mul i32 %tmp1, %num
  ret i32 %tmp2
}

define i32 @sdiv(i32 %val, i32 %num) nounwind {
; CHECK-LABEL: 'sdiv'
; CHECK-NEXT:  Classifying expressions for: @sdiv
; CHECK-NEXT:    %tmp1 = sdiv i32 %val, %num
; CHECK-NEXT:    --> %tmp1 U: full-set S: full-set
; CHECK-NEXT:    %tmp2 = mul i32 %tmp1, %num
; CHECK-NEXT:    --> (%num * %tmp1) U: full-set S: full-set
; CHECK-NEXT:  Determining loop execution counts for: @sdiv
;
  %tmp1 = sdiv i32 %val, %num
  %tmp2 = mul i32 %tmp1, %num
  ret i32 %tmp2
}

; Or, it could be a number of equivalent patterns with mask:
;   b) x &  (-1 << nbits)
;   d) x >> (32 - y) << (32 - y)

define i32 @mask_b(i32 %val, i32 %numlowbits) nounwind {
; CHECK-LABEL: 'mask_b'
; CHECK-NEXT:  Classifying expressions for: @mask_b
; CHECK-NEXT:    %mask = shl i32 -1, %numlowbits
; CHECK-NEXT:    --> %mask U: full-set S: full-set
; CHECK-NEXT:    %masked = and i32 %mask, %val
; CHECK-NEXT:    --> %masked U: full-set S: full-set
; CHECK-NEXT:  Determining loop execution counts for: @mask_b
;
  %mask = shl i32 -1, %numlowbits
  %masked = and i32 %mask, %val
  ret i32 %masked
}

define i32 @mask_d(i32 %val, i32 %lowbits) nounwind {
; CHECK-LABEL: 'mask_d'
; CHECK-NEXT:  Classifying expressions for: @mask_d
; CHECK-NEXT:    %numlowbits = sub i32 32, %lowbits
; CHECK-NEXT:    --> (32 + (-1 * %lowbits)) U: full-set S: full-set
; CHECK-NEXT:    %lowbitscleared = lshr i32 %val, %numlowbits
; CHECK-NEXT:    --> %lowbitscleared U: full-set S: full-set
; CHECK-NEXT:    %masked = shl i32 %lowbitscleared, %numlowbits
; CHECK-NEXT:    --> %masked U: full-set S: full-set
; CHECK-NEXT:  Determining loop execution counts for: @mask_d
;
  %numlowbits = sub i32 32, %lowbits
  %lowbitscleared = lshr i32 %val, %numlowbits
  %masked = shl i32 %lowbitscleared, %numlowbits
  ret i32 %masked
}
