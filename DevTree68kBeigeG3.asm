; ===========================================================================
; Entry point for device tree extraction.
; Called from StartInit.a:BootRetry right before InitSlots.
; ===========================================================================
f_FFC4F420:
    link    a6,#0
    movea.l UnivInfoPtr,a0      ;
    moveq   #$40,d0             ;
    and.l   $28(a0),d0          ; check bit 6 of ExtValid1 (meaning?)
    beq.s   l_FFC4F440          ; go if it's cleared
    moveq   #$14,d0             ;
    _NewPtrSysClear             ; allocate 20 bytes in the system heap
    movea.l ExpandMem,a1        ;
    move.l  a0,$234(a1)         ; and store their ptr in ExpandMem.var234
    jsr     f_FFC537B0          ; process OF device tree

l_FFC4F440:
    unlk    a6
    rts

; ===========================================================================
; Call OF client interface using a special trampoline.
;
; Params: (A7) - pointer to OF client interface argument array
; Returns: D0  - result code (always 0)
; ===========================================================================
f_FFC525F0:
    link    a6,#0               ;
    move.l  d7,-(sp)            ; save D7
    move.l  arg_0(a6),-(sp)     ; propagate argument
    jsr     f_FFC538E4          ; call OF client interface using a special trampoline
    move.l  d0,d7               ; superfluos instr
    move.l  var_4(a6),d7        ; restore D7
    unlk    a6
    rts

    align $10

; ===========================================================================
; Execute OF "finddevice" client interface function.
;
; Params: arg_0 - memory location that will receive device's phandle
;         arg_4 - device specifier (C-string ptr)
; Returns: D0 = 0: no error, -1: device not found
; ===========================================================================
f_FFC52610:
    link    a6,#-$54
    movem.l d7/a3-a4,-(sp)
    lea     var_40(a6),a3       ; A3 - where to put service string
    movea.l arg_0(a6),a4        ; A4 - ptr to the return value
    pea     aFinddevice         ; ptr to static string "finddevice"
    move.l  a3,-(sp)            ; copy service string into the CI argument
    jsr     j_strcpy            ; array + 24
    move.l  a3,var_54(a6)       ; CIArgs.service = A3
    moveq   #1,d0               ;
    move.l  d0,var_50(a6)       ; CIArgs.nArgs = 1
    move.l  d0,var_4C(a6)       ; CIArgs.nRets = 1
    move.l  arg_4(a6),var_48(a6) ; CIArgs.params[0] = device specifier
    moveq   #0,d1               ;
    move.l  d1,var_44(a6)       ; zero return value in CIArgs.params[1]
    move.l  d1,(a4)             ; zero return value at arg_0
    pea     var_54(a6)          ; param = ptr to CI argument array
    jsr     f_FFC525F0          ; call OF client interface
    move.l  d0,d7               ; D7 - result code
    move.l  var_44(a6),(a4)     ; copy device's phandle into arg_0
    bne.s   l_FFC52658          ;
    moveq   #$FFFFFFFF,d7       ; result = -1 if phandle is NULL

l_FFC52658:
    move.w  d7,d0               ; return result in D0
    movem.l var_60(a6),d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aFinddevice:    dc.b 'finddevice',0
                align $10

; ===========================================================================
f_FFC52670:
    link    a6,#-$60
    movem.l d7/a4,-(sp)
    lea     var_40(a6),a4
    pea     aGetprop        ; "getprop"
    move.l  a4,-(sp)
    jsr     j_strcpy
    move.l  a4,var_60(a6)
    moveq   #4,d0
    move.l  d0,var_5C(a6)
    moveq   #1,d1
    move.l  d1,var_58(a6)
    move.l  arg_0(a6),var_54(a6)
    move.l  arg_4(a6),var_50(a6)
    move.l  arg_8(a6),var_4C(a6)
    move.l  arg_C(a6),var_48(a6)
    moveq   #0,d0
    move.l  d0,var_44(a6)
    pea     var_60(a6)
    jsr     f_FFC525F0
    move.l  d0,d7
    moveq   #$FFFFFFFF,d0
    cmp.l   var_44(a6),d0
    bne.s   l_FFC526C8
    moveq   #$FFFFFFFF,d7

l_FFC526C8:
    movea.l arg_10(a6),a0
    move.l  var_44(a6),(a0)
    move.w  d7,d0
    movem.l var_68(a6),d7/a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aGetprop:       dc.b 'getprop',0
                align $10

; ===========================================================================
f_FFC526F0:
    link    a6,#-$58
    movem.l d7/a4,-(sp)
    lea     var_40(a6),a4
    pea     aGetproplen     ; "getproplen"
    move.l  a4,-(sp)
    jsr     j_strcpy
    move.l  a4,var_58(a6)
    moveq   #2,d0
    move.l  d0,var_54(a6)
    moveq   #1,d1
    move.l  d1,var_50(a6)
    move.l  arg_0(a6),var_4C(a6)
    move.l  arg_4(a6),var_48(a6)
    moveq   #0,d0
    move.l  d0,var_44(a6)
    pea     var_58(a6)
    jsr     f_FFC525F0
    move.l  d0,d7
    moveq   #$FFFFFFFF,d0
    cmp.l   var_44(a6),d0
    bne.s   l_FFC5273C
    moveq   #$FFFFFFFF,d7

l_FFC5273C:
    movea.l arg_8(a6),a0
    move.l  var_44(a6),(a0)
    move.w  d7,d0
    movem.l var_60(a6),d7/a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aGetproplen:    dc.b 'getproplen',0
                align $10

; ===========================================================================
f_FFC52760:
    link    a6,#-$7C
    movem.l d7/a3-a4,-(sp)
    lea     var_60(a6),a3
    lea     var_40(a6),a4
    pea     aNextprop       ; "nextprop"
    move.l  a4,-(sp)
    jsr     j_strcpy
    move.l  a4,var_7C(a6)
    moveq   #3,d0
    move.l  d0,var_78(a6)
    moveq   #1,d1
    move.l  d1,var_74(a6)
    move.l  arg_0(a6),var_70(a6)
    move.l  arg_4(a6),var_6C(a6)
    move.l  a3,var_68(a6)
    pea     var_7C(a6)
    jsr     f_FFC525F0
    move.l  d0,d7
    moveq   #$FFFFFFFF,d0
    cmp.l   var_64(a6),d0
    beq.s   l_FFC527B2
    tst.l   var_64(a6)
    bne.s   l_FFC527B4

l_FFC527B2:
    moveq   #$FFFFFFFF,d7

l_FFC527B4:
    move.l  a3,-(sp)
    move.l  arg_8(a6),-(sp)
    jsr     j_strcpy
    move.w  d7,d0
    movem.l var_88(a6),d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aNextprop:      dc.b 'nextprop',0
                align $10

; ===========================================================================
f_FFC527E0:
    link    a6,#-$54
    movem.l d7/a4,-(sp)
    lea     var_40(a6),a4
    pea     aPeer           ; "peer"
    move.l  a4,-(sp)
    jsr     j_strcpy
    move.l  a4,var_54(a6)
    moveq   #1,d0
    move.l  d0,var_50(a6)
    move.l  d0,var_4C(a6)
    move.l  arg_0(a6),var_48(a6)
    pea     var_54(a6)
    jsr     f_FFC525F0
    move.l  d0,d7
    movea.l arg_4(a6),a0
    move.l  var_44(a6),(a0)
    bne.s   l_FFC52820
    moveq   #$FFFFFFFF,d7

l_FFC52820:
    move.w  d7,d0
    movem.l var_5C(a6),d7/a4
    unlk    a6
    rts
; ---------------------------------------------------------------------------
aPeer:          dc.b 'peer',0
                align $10

; ===========================================================================
f_FFC52840:
    link    a6,#-$54
    movem.l d7/a4,-(sp)
    lea     var_40(a6),a4
    pea     aChild          ; "child"
    move.l  a4,-(sp)
    jsr     j_strcpy
    move.l  a4,var_54(a6)
    moveq   #1,d0
    move.l  d0,var_50(a6)
    move.l  d0,var_4C(a6)
    move.l  arg_0(a6),var_48(a6)
    pea     var_54(a6)
    jsr     f_FFC525F0
    move.l  d0,d7
    movea.l arg_4(a6),a0
    move.l  var_44(a6),(a0)
    bne.s   l_FFC52880
    moveq   #$FFFFFFFF,d7

l_FFC52880:
    move.w  d7,d0
    movem.l var_5C(a6),d7/a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aChild:         dc.b 'child',0
                align $10

; ===========================================================================
f_FFC528A0:
    link    a6,#-4
    movem.l d7/a3-a4,-(sp)
    movea.l arg_0(a6),a4
    movea.l ($2B6).w,a0
    movea.l $234(a0),a3
    movea.l arg_4(a6),a0
    moveq   #0,d0
    move.l  d0,(a0)
    move.l  d0,(a4)
    move.l  d0,var_4(a6)
    move.l  a4,-(sp)
    pea     aRoot           ; "root"
    moveq   #1,d0
    move.l  d0,-(sp)
    move.l  var_4(a6),-(sp)
    jsr     f_FFC500F0
    move.w  d0,d7
    lea     $10(sp),sp
    beq.s   l_FFC528E4
    moveq   #0,d0
    move.l  d0,(a3)
    move.w  d7,d0
    bra.s   l_FFC528FE

l_FFC528E4:
    move.l  (a4),(a3)
    subq.l  #2,sp
    move.l  (a4),-(sp)
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     aDevices        ; "Devices"
    move.l  arg_4(a6),-(sp)
    jsr     f_FFC5029E
    move.w  (sp)+,d7
    move.w  d7,d0

l_FFC528FE:
    movem.l var_10(a6),d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aDevices:       dc.b 'Devices',0
aRoot:          dc.b 'root',0
                align $10

; ===========================================================================
f_FFC52920:
    link    a6,#-$A0
    movem.l d5-d7/a3-a4,-(sp)
    move.l  arg_4(a6),d5
    lea     var_48(a6),a4
    tst.l   arg_0(a6)
    bne.s   l_FFC5296C
    pea     var_98(a6)
    pea     var_9C(a6)
    jsr     f_FFC528A0
    move.w  d0,d7
    addq.w  #8,sp
    bne.s   l_FFC52962
    move.l  var_98(a6),d5
    moveq   #0,d0               ;
    move.l  d0,arg_0(a6)        ; zero phandle of the DT root node
    pea     asc_52B9E           ; arg_4 = pathname of the DT root node (= "/")
    pea     arg_0(a6)           ; arg_0 - receives phandle of the DT root node
    jsr     f_FFC52610          ; attempt to get phandle for the DT root node
    move.w  d0,d7               ; D7 - result code
    addq.w  #8,sp               ; remove params from stack

l_FFC52962:
    tst.w   d7                  ;
    bne.w   l_FFC52B4C          ; exit if no root node was found
    moveq   #1,d6
    bra.s   l_FFC5296E

l_FFC5296C:
    clr.b   d6

l_FFC5296E:
    moveq   #$20,d0 ;
    move.l  d0,var_8(a6)
    pea     aName_1         ; "name"
    pea     var_68(a6)
    jsr     j_strcpy
    pea     var_8(a6)
    moveq   #$20,d0 ;
    move.l  d0,-(sp)
    pea     var_88(a6)
    pea     var_68(a6)
    move.l  arg_0(a6),-(sp)
    jsr     f_FFC52670
    move.w  d0,d7
    lea     $1C(sp),sp
    bne.w   l_FFC52B4C
    tst.b   d6
    beq.s   l_FFC529C2
    pea     var_88(a6)
    pea     var_28(a6)
    jsr     j_strcpy
    pea     aDeviceTree     ; "device-tree"
    pea     var_88(a6)
    jsr     j_strcpy
    lea     $10(sp),sp

l_FFC529C2:
    subq.l  #2,sp
    move.l  d5,-(sp)
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     var_88(a6)
    pea     var_A0(a6)
    jsr     f_FFC5029E
    move.w  (sp)+,d7
    tst.b   d6
    beq.s   l_FFC52A1A
    subq.l  #2,sp
    move.l  var_A0(a6),-(sp)
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     aAaplOriginalNa ; "AAPL,original-name"
    pea     var_94(a6)
    jsr     f_FFC502E4
    move.w  (sp)+,d7
    bne.s   l_FFC52A14
    subq.l  #2,sp
    move.l  var_94(a6),-(sp)
    pea     var_28(a6)
    pea     var_28(a6)
    jsr     j_strlen
    addq.l  #1,d0
    addq.l  #4,sp
    move.l  d0,-(sp)
    jsr     f_FFC5002E
    move.w  (sp)+,d7

l_FFC52A14:
    tst.w   d7
    bne.w   l_FFC52B4C

l_FFC52A1A:
    moveq   #0,d0
    movea.l d0,a3
    clr.b   var_68(a6)

l_FFC52A22:
    move.l  a4,-(sp)
    pea     var_68(a6)
    move.l  arg_0(a6),-(sp)
    jsr     f_FFC52760
    move.w  d0,d7
    lea     $C(sp),sp
    bne.w   l_FFC52B06
    move.l  a4,-(sp)
    pea     var_68(a6)
    jsr     j_strcpy
    pea     aName_1         ; "name"
    move.l  a4,-(sp)
    jsr     j_strcmp_0
    tst.l   d0
    lea     $10(sp),sp
    beq.w   l_FFC52B00
    moveq   #0,d0
    move.b  (a4),d0
    tst.l   d0
    beq.w   l_FFC52B06
    moveq   #7,d0
    move.l  d0,-(sp)
    pea     aDriver         ; "driver,"
    move.l  a4,-(sp)
    jsr     j_strncmp
    tst.l   d0
    lea     $C(sp),sp
    bne.s   l_FFC52A88
    pea     aDriverAaplMaco ; "driver,AAPL,MacOS,PowerPC"
    move.l  a4,-(sp)
    jsr     j_strcmp_0
    tst.l   d0
    addq.w  #8,sp
    bne.s   l_FFC52B00

l_FFC52A88:
    subq.l  #2,sp
    move.l  var_A0(a6),-(sp)
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  a4,-(sp)
    pea     var_94(a6)
    jsr     f_FFC502E4
    move.w  (sp)+,d7
    bne.s   l_FFC52B06
    pea     var_4(a6)
    move.l  a4,-(sp)
    move.l  arg_0(a6),-(sp)
    jsr     f_FFC526F0
    move.w  d0,d7
    lea     $C(sp),sp
    bne.s   l_FFC52B06
    tst.l   var_4(a6)
    beq.s   l_FFC52B00
    move.l  var_4(a6),d0
    _NewPtrSys
    movea.l a0,a3
    move.l  a3,d0
    beq.s   l_FFC52B06
    pea     var_4(a6)
    move.l  var_4(a6),-(sp)
    move.l  a3,-(sp)
    move.l  a4,-(sp)
    move.l  arg_0(a6),-(sp)
    jsr     f_FFC52670
    move.w  d0,d7
    lea     $14(sp),sp
    bne.s   l_FFC52B06
    subq.l  #2,sp
    move.l  var_94(a6),-(sp)
    move.l  a3,-(sp)
    move.l  var_4(a6),-(sp)
    jsr     f_FFC5002E
    move.w  (sp)+,d7
    bne.s   l_FFC52B06
    movea.l a3,a0
    _DisposePtr
    moveq   #0,d0
    movea.l d0,a3

l_FFC52B00:
    tst.w   d7
    beq.w   l_FFC52A22

l_FFC52B06:
    move.l  a3,d0
    beq.s   l_FFC52B0E
    movea.l a3,a0
    _DisposePtr

l_FFC52B0E:
    pea     var_90(a6)
    move.l  arg_0(a6),-(sp)
    jsr     f_FFC527E0
    move.w  d0,d7
    addq.w  #8,sp
    bne.s   l_FFC52B2C
    move.l  d5,-(sp)
    move.l  var_90(a6),-(sp)
    jsr     f_FFC52920
    addq.w  #8,sp

l_FFC52B2C:
    pea     var_8C(a6)
    move.l  arg_0(a6),-(sp)
    jsr     f_FFC52840
    move.w  d0,d7
    addq.w  #8,sp
    bne.s   l_FFC52B4C
    move.l  var_A0(a6),-(sp)
    move.l  var_8C(a6),-(sp)
    jsr     f_FFC52920
    addq.w  #8,sp

l_FFC52B4C:
    movem.l var_B4(a6),d5-d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aDriverAaplMaco:dc.b 'driver,AAPL,MacOS,PowerPC',0
aDriver:        dc.b 'driver,',0
aName_1:        dc.b 'name',0

                dc.b   0
aAaplOriginalNa:dc.b 'AAPL,original-name',0
                dc.b   0
aDeviceTree:    dc.b 'device-tree',0
asc_52B9E:      dc.b '/',0

; ===========================================================================
j_strncmp:
    bra.l   strncmp

    align $10

; ===========================================================================
f_FFC52BB0:
    link    a6,#-4
    movem.l d6-d7/a3-a4,-(sp)
    movea.l arg_4(a6),a4
    movea.l arg_8(a6),a0
    moveq   #1,d0
    move.l  d0,(a0)
    movea.l arg_C(a6),a0
    move.l  d0,(a0)
    moveq   #0,d6
    move.l  arg_0(a6),-(sp)
    jsr     f_FFC4F5B0
    movea.l d0,a3
    move.l  8(a3),(a4)
    addq.w  #4,sp
    beq.w   l_FFC52CEA
    move.l  (a4),-(sp)
    jsr     f_FFC4F5B0
    move.l  d0,var_4(a6)
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  d0,-(sp)
    pea     aDeviceType     ; "device_type"
    move.l  var_4(a6),-(sp)
    jsr     f_FFC4F840
    move.l  d0,d7
    lea     $14(sp),sp
    bne.s   l_FFC52C0A
    moveq   #0,d0
    movea.l d0,a4
    bra.s   l_FFC52C18

l_FFC52C0A:
    move.l  d7,-(sp)
    jsr     f_FFC4F5D0
    movea.l d0,a3
    movea.l $14(a3),a4
    addq.w  #4,sp

l_FFC52C18:
    move.l  a4,d0
    beq.s   l_FFC52C42
    move.l  a4,-(sp)
    pea     aPci            ; "pci"
    jsr     j_strcmp_0
    tst.l   d0
    addq.w  #8,sp
    bne.s   l_FFC52C42
    moveq   #1,d6
    movea.l arg_8(a6),a0
    moveq   #3,d0
    move.l  d0,(a0)
    movea.l arg_C(a6),a0
    moveq   #2,d1
    move.l  d1,(a0)
    bra.w   l_FFC52CEA

l_FFC52C42:
    move.l  a4,d0
    beq.s   l_FFC52C7A
    move.l  a4,-(sp)
    pea     aIsa            ; "isa"
    jsr     j_strcmp_0
    tst.l   d0
    addq.w  #8,sp
    beq.s   l_FFC52C66
    move.l  a4,-(sp)
    pea     aEisa           ; "eisa"
    jsr     j_strcmp_0
    tst.l   d0
    addq.w  #8,sp
    bne.s   l_FFC52C7A

l_FFC52C66:
    moveq   #2,d6
    movea.l arg_8(a6),a0
    moveq   #2,d0
    move.l  d0,(a0)
    movea.l arg_C(a6),a0
    moveq   #1,d1
    move.l  d1,(a0)
    bra.s   l_FFC52CEA

l_FFC52C7A:
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  d0,-(sp)
    pea     aSizeCells      ; "#size-cells"
    move.l  var_4(a6),-(sp)
    jsr     f_FFC4F840
    move.l  d0,d7
    lea     $10(sp),sp
    bne.s   l_FFC52C9E
    movea.l arg_C(a6),a0
    moveq   #1,d0
    move.l  d0,(a0)
    bra.s   l_FFC52CB2

l_FFC52C9E:
    move.l  d7,-(sp)
    jsr     f_FFC4F5D0
    movea.l d0,a3
    movea.l $14(a3),a4
    movea.l arg_C(a6),a0
    move.l  (a4),(a0)
    addq.w  #4,sp

l_FFC52CB2:
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  d0,-(sp)
    pea     aAddressCells   ; "#address-cells"
    move.l  var_4(a6),-(sp)
    jsr     f_FFC4F840
    move.l  d0,d7
    lea     $10(sp),sp
    bne.s   l_FFC52CD6
    movea.l arg_8(a6),a0
    moveq   #1,d0
    move.l  d0,(a0)
    bra.s   l_FFC52CEA

l_FFC52CD6:
    move.l  d7,-(sp)
    jsr     f_FFC4F5D0
    movea.l d0,a3
    movea.l $14(a3),a4
    movea.l arg_8(a6),a0
    move.l  (a4),(a0)
    addq.w  #4,sp

l_FFC52CEA:
    move.l  d6,d0
    movem.l var_14(a6),d6-d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aAddressCells:  dc.b '#address-cells',0
                dc.b   0
aSizeCells:     dc.b '#size-cells',0
aEisa:          dc.b 'eisa',0
                dc.b   0
aIsa:           dc.b 'isa',0
aPci:           dc.b 'pci',0
aDeviceType:    dc.b 'device_type',0
                align $10

; ===========================================================================
f_FFC52D30:
    link    a6,#0
    movem.l d3-d7,-(sp)
    move.l  arg_C(a6),d4
    move.l  arg_8(a6),d5
    move.l  arg_0(a6),d6
    moveq   #1,d0
    cmp.l   arg_4(a6),d0
    bne.s   l_FFC52D50
    moveq   #1,d0
    bra.s   l_FFC52DA0

l_FFC52D50:
    moveq   #1,d0
    cmp.l   d4,d0
    bne.s   l_FFC52D82
    tst.l   arg_10(a6)
    seq     d3
    neg.b   d3
    beq.s   l_FFC52D68
    move.l  #$3000000,d0
    bra.s   l_FFC52D6E

l_FFC52D68:
    move.l  #$3FFFFFF,d0

l_FFC52D6E:
    move.l  d0,d7
    and.l   d6,d0
    move.l  d7,d1
    and.l   d5,d1
    cmp.l   d0,d1
    seq     d3
    neg.b   d3
    extb.l  d3
    move.l  d3,d0
    bra.s   l_FFC52DA0

l_FFC52D82:
    moveq   #2,d0
    cmp.l   d4,d0
    bne.s   l_FFC52D9E
    moveq   #3,d7
    move.l  d7,d0
    and.l   d6,d0
    move.l  d7,d1
    and.l   d5,d1
    cmp.l   d0,d1
    seq     d3
    neg.b   d3
    extb.l  d3
    move.l  d3,d0
    bra.s   l_FFC52DA0

l_FFC52D9E:
    moveq   #1,d0

l_FFC52DA0:
    movem.l var_14(a6),d3-d7
    unlk    a6
    rts

    align $10

; ===========================================================================
f_FFC52DB0:
    link    a6,#-$18
    movem.l d3-d7/a2-a4,-(sp)
    move.l  arg_18(a6),d3
    move.l  arg_10(a6),d5
    move.l  arg_8(a6),d6
    movea.l arg_4(a6),a3
    move.l  arg_C(a6),d7
    movea.l arg_14(a6),a4
    move.l  d3,d0
    divu.l  #4,d0
    move.l  d0,d3
    bra.w   l_FFC52E6A

l_FFC52DE0:
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  arg_0(a6),-(sp)
    move.l  (a4),-(sp)
    move.l  d7,-(sp)
    move.l  (a3),-(sp)
    jsr     f_FFC52D30
    tst.l   d0
    lea     $14(sp),sp
    beq.s   l_FFC52E54
    move.l  d7,d0
    subq.l  #1,d0
    move.l  d7,d1
    add.l   d5,d1
    subq.l  #1,d1
    move.l  (a3,d1.l*4),d1
    add.l   (a3,d0.l*4),d1
    move.l  d1,var_8(a6)
    move.l  d7,d0
    subq.l  #1,d0
    move.l  (a4,d0.l*4),d4
    move.l  d7,d0
    add.l   d6,d0
    add.l   d5,d0
    subq.l  #1,d0
    move.l  (a4,d0.l*4),var_14(a6)
    move.l  d7,d0
    add.l   d6,d0
    subq.l  #1,d0
    move.l  (a4,d0.l*4),var_10(a6)
    move.l  d7,d0
    subq.l  #1,d0
    cmp.l   (a3,d0.l*4),d4
    bhi.s   l_FFC52E54
    move.l  var_14(a6),d0
    add.l   d4,d0
    move.l  d0,var_4(a6)
    move.l  var_8(a6),d0
    cmp.l   var_4(a6),d0
    bhi.s   l_FFC52E54
    movea.l a4,a2
    bra.s   l_FFC52E70

l_FFC52E54:
    move.l  d7,d0
    add.l   d6,d0
    add.l   d5,d0
    move.l  d0,var_18(a6)
    sub.l   var_18(a6),d3
    move.l  var_18(a6),d0
    asl.l   #2,d0
    adda.l  d0,a4

l_FFC52E6A:
    tst.l   d3
    bne.w   l_FFC52DE0

l_FFC52E70:
    move.l  a2,d0
    movem.l var_38(a6),d3-d7/a2-a4
    unlk    a6
    rts

    align $10

; ===========================================================================
f_FFC52E80:
    link    a6,#-$34
    movem.l d4-d7/a3-a4,-(sp)
    move.l  arg_0(a6),d4
    move.l  arg_C(a6),d6
    movea.l arg_4(a6),a3
    lea     var_18(a6),a4
    move.l  arg_8(a6),d7
    move.l  d4,-(sp)
    jsr     f_FFC4F5B0
    move.l  d0,var_30(a6)
    pea     var_28(a6)
    pea     var_24(a6)
    pea     var_34(a6)
    move.l  d4,-(sp)
    jsr     f_FFC52BB0
    move.l  d0,var_20(a6)
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  d0,-(sp)
    pea     aRanges         ; "ranges"
    move.l  var_30(a6),-(sp)
    jsr     f_FFC4F840
    move.l  d0,d4
    lea     $24(sp),sp
    bne.s   l_FFC52EE0
    moveq   #0,d0
    move.l  d0,var_4(a6)
    moveq   #0,d5
    bra.s   l_FFC52EFC

l_FFC52EE0:
    move.l  d4,-(sp)
    jsr     f_FFC4F5D0
    move.l  d0,var_2C(a6)
    movea.l d0,a0
    move.l  $14(a0),var_4(a6)
    movea.l var_2C(a6),a0
    move.l  $10(a0),d5
    addq.w  #4,sp

l_FFC52EFC:
    tst.l   d4
    beq.w   l_FFC53012
    tst.l   d5
    ble.w   l_FFC52F8C
    move.l  d5,-(sp)
    move.l  var_4(a6),-(sp)
    move.l  d6,-(sp)
    move.l  d7,-(sp)
    move.l  var_24(a6),-(sp)
    move.l  a3,-(sp)
    move.l  arg_10(a6),-(sp)
    jsr     f_FFC52DB0
    move.l  d0,var_1C(a6)
    move.l  var_24(a6),d0
    asl.l   #2,d0
    move.l  d0,-(sp)
    move.l  d7,d0
    asl.l   #2,d0
    add.l   var_1C(a6),d0
    move.l  d0,-(sp)
    move.l  a4,-(sp)
    jsr     j_memcpy
    move.w  var_24+2(a6),d0
    move.l  d7,d1
    subq.l  #1,d1
    move.l  d7,d2
    subq.l  #1,d2
    movea.l var_1C(a6),a0
    move.l  (a3,d1.l*4),d1
    sub.l   (a0,d2.l*4),d1
    add.l   d1,-4(a4,d0.w*4)
    move.l  var_28(a6),d0
    asl.l   #2,d0
    move.l  d0,-(sp)
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  var_24(a6),d1
    asl.l   #2,d1
    add.l   a4,d1
    move.l  d1,-(sp)
    jsr     j_memset
    move.l  d7,d0
    add.l   d6,d0
    subq.l  #1,d0
    move.l  var_28(a6),d1
    add.l   var_24(a6),d1
    move.l  (a3,d0.l*4),-4(a4,d1.w*4)
    lea     $34(sp),sp
    bra.s   l_FFC52FE4

l_FFC52F8C:
    move.l  var_28(a6),d0
    add.l   var_24(a6),d0
    asl.l   #2,d0
    move.l  d0,-(sp)
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  a4,-(sp)
    jsr     j_memset
    move.l  d7,d0
    asl.l   #2,d0
    move.l  d0,-(sp)
    move.l  a3,-(sp)
    move.l  var_24(a6),d0
    sub.l   d7,d0
    asl.l   #2,d0
    add.l   a4,d0
    move.l  d0,-(sp)
    jsr     j_memcpy
    move.l  d6,d0
    asl.l   #2,d0
    move.l  d0,-(sp)
    move.l  d7,d0
    asl.l   #2,d0
    add.l   a3,d0
    move.l  d0,-(sp)
    move.l  var_24(a6),d0
    asl.l   #2,d0
    add.l   a4,d0
    move.l  var_28(a6),d1
    sub.l   d6,d1
    asl.l   #2,d1
    add.l   d0,d1
    move.l  d1,-(sp)
    jsr     j_memcpy
    lea     $24(sp),sp

l_FFC52FE4:
    tst.l   var_34(a6)
    beq.s   l_FFC53008
    move.l  var_20(a6),-(sp)
    move.l  var_28(a6),-(sp)
    move.l  var_24(a6),-(sp)
    move.l  a4,-(sp)
    move.l  var_34(a6),-(sp)
    jsr     f_FFC52E80
    move.l  d0,d6
    lea     $14(sp),sp
    bra.s   l_FFC5301A

l_FFC53008:
    move.w  var_24+2(a6),d0
    move.l  -4(a4,d0.w*4),d6
    bra.s   l_FFC5301A

l_FFC53012:
    move.l  d7,d0
    subq.l  #1,d0
    move.l  (a3,d0.l*4),d6

l_FFC5301A:
    move.l  d6,d0
    movem.l var_4C(a6),d4-d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aRanges:        dc.b 'ranges',0
                align $10

; ===========================================================================
j_memset:
    bra.l   memset

    align $10

; ===========================================================================
f_FFC53040:
    link    a6,#-$C
    movem.l d6-d7,-(sp)
    movea.l (dword_DD8).w,a0
    moveq   #$40,d0 ; '@'
    and.l   $28(a0),d0
    beq.s   l_FFC530A2
    subq.l  #2,sp
    pea     var_C(a6)
    jsr     f_FFC4F4E2
    move.w  (sp)+,d7
    bne.s   l_FFC530A2
    moveq   #1,d6

l_FFC53064:
    moveq   #0,d0
    move.l  d0,var_8(a6)
    subq.l  #2,sp
    pea     var_C(a6)
    pea     aDriverAaplMaco_0 ; "driver,AAPL,MacOS,PowerPC"
    pea     var_4(a6)
    pea     var_8(a6)
    move.b  d6,-(sp)
    jsr     f_FFC4FA96
    move.w  (sp)+,d7
    bne.s   l_FFC530A2
    move.l  var_C(a6),-(sp)
    jsr     f_FFC51C60
    tst.b   d0
    addq.w  #4,sp
    bne.s   l_FFC53064
    subq.l  #2,sp
    move.l  var_C(a6),-(sp)
    jsr     f_FFC520FE
    move.w  (sp)+,d7
    bra.s   l_FFC53064

l_FFC530A2:
    movem.l var_14(a6),d6-d7
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aDriverAaplMaco_0:dc.b 'driver,AAPL,MacOS,PowerPC',0

    align $10

; ===========================================================================
f_FFC530D0:
    link    a6,#-$1C
    movem.l d5-d7/a3-a4,-(sp)
    move.l  arg_4(a6),d6
    movea.l arg_8(a6),a3
    subq.l  #2,sp
    move.l  arg_0(a6),-(sp)
    pea     aAssignedAddres ; "assigned-addresses"
    pea     var_1C(a6)
    pea     var_14(a6)
    moveq   #$14,d5
    move.l  d5,-(sp)
    pea     var_18(a6)
    jsr     f_FFC4FB3E
    move.w  (sp)+,d7
    beq.s   l_FFC53108
    move.w  #$F615,d0
    bra.s   l_FFC53152

l_FFC53108:
    lea     var_14(a6),a4
    move.l  var_18(a6),d0
    divu.l  #$14,d0
    move.l  d0,d7
    moveq   #0,d0
    move.l  d0,(a3)
    bra.s   l_FFC5313E

l_FFC53120:
    move.l  #$FF,d0
    and.l   (a4),d0
    move.l  #$FF,d1
    and.l   d6,d1
    cmp.l   d0,d1
    bne.s   l_FFC5313A
    move.l  8(a4),(a3)
    bra.s   l_FFC53146

l_FFC5313A:
    lea     $14(a4),a4

l_FFC5313E:
    move.l  d7,d0
    subq.l  #1,d7
    tst.l   d0
    bne.s   l_FFC53120

l_FFC53146:
    tst.l   (a3)
    bne.s   l_FFC53150
    move.w  #$F615,d0
    bra.s   l_FFC53152

l_FFC53150:
    moveq   #0,d0

l_FFC53152:
    movem.l var_30(a6),d5-d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aAssignedAddres:dc.b 'assigned-addresses',0
                align $10

; ===========================================================================
f_FFC53170:
    link    a6,#-$14
    movem.l d5-d7,-(sp)
    moveq   #$30,d6 ; '0'
    moveq   #1,d5
    pea     var_10(a6)
    pea     arg_0(a6)
    jsr     f_FFC51910
    move.w  d0,d7
    addq.w  #8,sp
    beq.s   l_FFC53192
    move.w  d7,d0
    bra.s   l_FFC531C2

l_FFC53192:
    subq.l  #2,sp
    pea     var_10(a6)
    move.l  d6,-(sp)
    pea     var_14(a6)
    jsr     f_FFC5545A
    move.w  (sp)+,d7
    beq.s   l_FFC531AA
    move.w  d7,d0
    bra.s   l_FFC531C2

l_FFC531AA:
    or.l    d5,var_14(a6)
    subq.l  #2,sp
    pea     var_10(a6)
    move.l  d6,-(sp)
    move.l  var_14(a6),-(sp)
    jsr     f_FFC555AA
    move.w  (sp)+,d7
    move.w  d7,d0

l_FFC531C2:
    movem.l var_20(a6),d5-d7
    unlk    a6
    rts

    align $10

; ===========================================================================
f_FFC531D0:
    link    a6,#-$14
    movem.l d5-d7,-(sp)
    moveq   #$30,d6 ; '0'
    moveq   #1,d5
    pea     var_10(a6)
    pea     arg_0(a6)
    jsr     f_FFC51910
    move.w  d0,d7
    addq.w  #8,sp
    beq.s   l_FFC531F2
    move.w  d7,d0
    bra.s   l_FFC53226

l_FFC531F2:
    subq.l  #2,sp
    pea     var_10(a6)
    move.l  d6,-(sp)
    pea     var_14(a6)
    jsr     f_FFC5545A
    move.w  (sp)+,d7
    beq.s   l_FFC5320A
    move.w  d7,d0
    bra.s   l_FFC53226

l_FFC5320A:
    move.l  d5,d0
    not.l   d0
    and.l   d0,var_14(a6)
    subq.l  #2,sp
    pea     var_10(a6)
    move.l  d6,-(sp)
    move.l  var_14(a6),-(sp)
    jsr     f_FFC555AA
    move.w  (sp)+,d7
    move.w  d7,d0

l_FFC53226:
    movem.l var_20(a6),d5-d7
    unlk    a6
    rts

; ===========================================================================
f_FFC53230:
    link    a6,#-4
    move.l  d7,-(sp)
    subq.l  #2,sp
    move.l  arg_0(a6),-(sp)
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     aDriverAaplMaco_3 ; "driver,AAPL,MacOS,PowerPC"
    pea     var_4(a6)
    jsr     f_FFC502E4
    move.w  (sp)+,d7
    subq.l  #2,sp
    move.l  var_4(a6),-(sp)
    move.l  arg_4(a6),-(sp)
    move.l  arg_8(a6),-(sp)
    jsr     f_FFC5002E
    move.w  (sp)+,d7
    move.w  d7,d0
    move.l  var_8(a6),d7
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aDriverAaplMaco_3:dc.b 'driver,AAPL,MacOS,PowerPC',0

    align $10

; ===========================================================================
f_FFC53290:
    link    a6,#-8
    movem.l d5-d7/a2-a4,-(sp)
    move.l  arg_C(a6),d5
    move.l  arg_0(a6),d6
    moveq   #0,d0
    move.l  d0,var_8(a6)
    movea.l d0,a2
    movea.l d0,a3
    movea.l d0,a4
    move.l  d6,-(sp)
    jsr     f_FFC53170
    move.w  d0,d7
    addq.w  #4,sp
    bne.s   l_FFC53302
    pea     var_8(a6)
    move.l  arg_4(a6),-(sp)
    move.l  d6,-(sp)
    jsr     f_FFC530D0
    move.w  d0,d7
    lea     $C(sp),sp
    bne.s   l_FFC53302
    movea.l arg_8(a6),a4
    adda.l  var_8(a6),a4
    move.l  d5,-(sp)
    jsr     f_FFC4F480
    movea.l d0,a2
    movea.l a2,a3
    move.l  a2,d0
    addq.w  #4,sp
    beq.s   l_FFC53302
    move.l  d5,d7
    bra.s   l_FFC532EC

l_FFC532EA:
    move.b  (a4)+,(a3)+

l_FFC532EC:
    move.l  d7,d0
    subq.l  #1,d7
    tst.l   d0
    bne.s   l_FFC532EA
    move.l  d5,-(sp)
    move.l  a2,-(sp)
    move.l  d6,-(sp)
    jsr     f_FFC53230
    lea     $C(sp),sp

l_FFC53302:
    move.l  a2,d0
    beq.s   l_FFC5330E
    move.l  a2,-(sp)
    jsr     f_FFC4F490
    addq.w  #4,sp

l_FFC5330E:
    move.l  d6,-(sp)
    jsr     f_FFC531D0
    addq.w  #4,sp
    movem.l var_20(a6),d5-d7/a2-a4
    unlk    a6
    rts

; ===========================================================================
f_FFC53320:
    link    a6,#-$1E
    movem.l d3-d7/a4,-(sp)
    lea     var_14(a6),a4
    subq.l  #2,sp
    pea     var_1C(a6)
    jsr     f_FFC4F4E2
    move.w  (sp)+,d7
    bne.s   l_FFC5337A
    moveq   #1,d3

l_FFC5333C:
    moveq   #$FFFFFFEC,d0
    move.l  d0,var_18(a6)
    subq.l  #2,sp
    pea     var_1C(a6)
    pea     aDriverRegAaplM ; "driver-reg,AAPL,MacOS,PowerPC"
    move.l  a4,-(sp)
    pea     var_18(a6)
    move.b  d3,-(sp)
    jsr     f_FFC4FA96
    move.w  (sp)+,d7
    bne.s   l_FFC5337A
    move.l  (a4),d4
    move.l  8(a4),d5
    move.l  $10(a4),d6
    move.l  d6,-(sp)
    move.l  d5,-(sp)
    move.l  d4,-(sp)
    move.l  var_1C(a6),-(sp)
    jsr     f_FFC53290
    lea     $10(sp),sp
    bra.s   l_FFC5333C

l_FFC5337A:
    movem.l var_36(a6),d3-d7/a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aDriverRegAaplM:dc.b 'driver-reg,AAPL,MacOS,PowerPC',0

    align $10

; ===========================================================================
f_FFC533B0:
    link    a6,#-$14
    movem.l d4-d7/a3-a4,-(sp)
    move.l  arg_0(a6),d5
    movea.l arg_4(a6),a3
    move.l  d5,-(sp)
    jsr     f_FFC4F5B0
    movea.l d0,a4
    move.l  8(a4),var_8(a6)
    move.l  var_8(a6),-(sp)
    jsr     f_FFC4F570
    move.l  d0,d4
    subq.l  #2,sp
    move.l  d5,-(sp)
    pea     aSizeCells_0    ; "#size-cells"
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     var_10(a6)
    moveq   #4,d1
    move.l  d1,-(sp)
    move.l  d0,-(sp)
    jsr     f_FFC4FB3E
    move.w  (sp)+,d6
    addq.w  #8,sp
    beq.s   l_FFC533FE
    moveq   #1,d0
    move.l  d0,var_10(a6)

l_FFC533FE:
    subq.l  #2,sp
    move.l  d5,-(sp)
    pea     aAddressCells_0 ; "#address-cells"
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     var_C(a6)
    moveq   #4,d1
    move.l  d1,-(sp)
    move.l  d0,-(sp)
    jsr     f_FFC4FB3E
    move.w  (sp)+,d6
    beq.s   l_FFC53422
    moveq   #1,d0
    move.l  d0,var_C(a6)

l_FFC53422:
    subq.l  #2,sp
    move.l  d4,-(sp)
    pea     aAddressCells_0 ; "#address-cells"
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     var_14(a6)
    moveq   #4,d1
    move.l  d1,-(sp)
    move.l  d0,-(sp)
    jsr     f_FFC4FB3E
    move.w  (sp)+,d6
    beq.s   l_FFC53446
    moveq   #1,d0
    move.l  d0,var_14(a6)

l_FFC53446:
    move.l  var_14(a6),d0
    add.l   var_C(a6),d0
    move.l  var_10(a6),d5
    add.l   d0,d5
    move.l  d5,d0
    subq.l  #1,d0
    move.l  d0,var_10(a6)
    move.l  var_14(a6),d0
    add.l   var_C(a6),d0
    subq.l  #1,d0
    move.l  d0,var_14(a6)
    move.l  var_C(a6),d0
    subq.l  #1,d0
    move.l  d0,var_C(a6)
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  d0,-(sp)
    pea     aRanges_0       ; "ranges"
    move.l  a4,-(sp)
    jsr     f_FFC4F840
    move.l  d0,d4
    move.w  #$F615,d6
    moveq   #0,d0
    move.l  d0,(a3)
    tst.l   d4
    lea     $10(sp),sp
    beq.s   l_FFC534DE
    move.l  d4,-(sp)
    jsr     f_FFC4F5D0
    move.l  d0,var_4(a6)
    movea.l d0,a0
    movea.l $14(a0),a4
    movea.l var_4(a6),a0
    move.l  $10(a0),d0
    lsr.l   #2,d0
    move.l  d0,d4
    moveq   #0,d7
    addq.w  #4,sp
    bra.s   l_FFC534DA

l_FFC534B8:
    moveq   #$18,d0
    move.l  (a4,d7.l*4),d1
    lsr.l   d0,d1
    moveq   #3,d0
    and.l   d1,d0
    moveq   #1,d1
    cmp.l   d0,d1
    bne.s   l_FFC534D8
    move.l  var_14(a6),d0
    add.l   d7,d0
    move.l  (a4,d0.l*4),(a3)
    clr.w   d6
    bra.s   l_FFC534DE

l_FFC534D8:
    add.l   d5,d7

l_FFC534DA:
    cmp.l   d7,d4
    bgt.s   l_FFC534B8

l_FFC534DE:
    move.w  d6,d0
    movem.l var_2C(a6),d4-d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aRanges_0:      dc.b 'ranges',0
                dc.b   0
aAddressCells_0:dc.b '#address-cells',0
                dc.b   0
aSizeCells_0:   dc.b '#size-cells',0
                align $10

; ===========================================================================
f_FFC53510:
    link    a6,#-8
    movem.l d6-d7/a3-a4,-(sp)
    movea.l arg_4(a6),a3
    movea.l arg_8(a6),a0
    moveq   #0,d0
    move.l  d0,(a0)
    subq.l  #2,sp
    move.l  arg_0(a6),-(sp)
    pea     aAssignedAddres_0 ; "assigned-addresses"
    pea     var_8(a6)
    moveq   #0,d0
    move.l  d0,-(sp)
    moveq   #0,d6
    move.l  d6,-(sp)
    pea     var_4(a6)
    jsr     f_FFC4FB3E
    move.w  (sp)+,d7
    beq.s   l_FFC5354C
    move.w  #$F615,d0
    bra.s   l_FFC535A0

l_FFC5354C:
    move.l  var_4(a6),-(sp)
    jsr     f_FFC4F480
    movea.l d0,a4
    move.l  a4,d0
    addq.w  #4,sp
    bne.s   l_FFC53562
    move.w  #$F617,d0
    bra.s   l_FFC535A0

l_FFC53562:
    pea     var_4(a6)
    move.l  a4,-(sp)
    move.l  var_8(a6),-(sp)
    jsr     f_FFC4F940
    move.w  d0,d7
    lea     $C(sp),sp
    beq.s   l_FFC5358A
    move.l  a4,-(sp)
    jsr     f_FFC4F490
    moveq   #0,d0
    move.l  d0,(a3)
    move.w  #$F615,d0
    addq.w  #4,sp
    bra.s   l_FFC535A0

l_FFC5358A:
    move.l  var_4(a6),d0
    divu.l  #$14,d0
    movea.l arg_8(a6),a0
    move.l  d0,(a0)
    move.l  a4,(a3)
    moveq   #0,d0

l_FFC535A0:
    movem.l var_18(a6),d6-d7/a3-a4
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aAssignedAddres_0:dc.b 'assigned-addresses',0

    align $10

; ===========================================================================
f_FFC535C0:
    link    a6,#-8
    movem.l d6-d7,-(sp)
    move.l  arg_0(a6),d6
    subq.l  #2,sp
    move.l  d6,-(sp)
    pea     aAaplAddress    ; "AAPL,address"
    pea     var_8(a6)
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  d0,-(sp)
    pea     var_4(a6)
    jsr     f_FFC4FB3E
    move.w  (sp)+,d7
    beq.s   l_FFC53606
    subq.l  #2,sp
    move.l  d6,-(sp)
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     aAaplAddress    ; "AAPL,address"
    pea     var_8(a6)
    jsr     f_FFC502E4
    move.w  (sp)+,d7
    beq.s   l_FFC53606
    move.w  d7,d0
    bra.s   l_FFC5361C

l_FFC53606:
    subq.l  #2,sp
    move.l  var_8(a6),-(sp)
    move.l  arg_4(a6),-(sp)
    move.l  arg_8(a6),-(sp)
    jsr     f_FFC5002E
    move.w  (sp)+,d7
    move.w  d7,d0

l_FFC5361C:
    movem.l var_10(a6),d6-d7
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aAaplAddress:   dc.b 'AAPL,address',0

    align $10

; ===========================================================================
f_FFC53640:
    link    a6,#-$1C
    movem.l d4-d7/a2-a4,-(sp)
    move.l  arg_0(a6),d5
    moveq   #0,d0
    move.l  d0,var_1C(a6)
    pea     var_8(a6)
    pea     var_C(a6)
    pea     var_10(a6)
    move.l  d5,-(sp)
    jsr     f_FFC52BB0
    move.l  d0,d7
    moveq   #0,d0
    move.l  d0,var_18(a6)
    move.l  d0,var_14(a6)
    pea     var_1C(a6)
    pea     var_18(a6)
    move.l  d5,-(sp)
    jsr     f_FFC53510
    move.w  d0,d6
    lea     $1C(sp),sp
    bne.w   l_FFC53712
    tst.l   var_1C(a6)
    bls.w   l_FFC53712
    movea.l var_18(a6),a4
    move.l  var_1C(a6),d4
    asl.l   #2,d4
    move.l  d4,-(sp)
    jsr     f_FFC4F480
    movea.l d0,a3
    move.l  a3,var_14(a6)
    addq.w  #4,sp
    beq.s   l_FFC5370E
    bra.s   l_FFC536EE

l_FFC536AC:
    moveq   #$18,d0
    move.l  (a4),d1
    lsr.l   d0,d1
    moveq   #3,d0
    and.l   d1,d0
    subq.l  #2,d0
    beq.s   l_FFC536BE
    subq.l  #1,d0
    bne.s   l_FFC536D0

l_FFC536BE:
    movea.l a4,a2
    lea     $14(a4),a4
    move.l  var_C(a6),d0
    subq.l  #1,d0
    move.l  (a2,d0.l*4),(a3)+
    bra.s   l_FFC536EE

l_FFC536D0:
    move.l  d7,-(sp)
    move.l  var_8(a6),-(sp)
    move.l  var_C(a6),-(sp)
    move.l  a4,-(sp)
    lea     $14(a4),a4
    move.l  var_10(a6),-(sp)
    jsr     f_FFC52E80
    move.l  d0,(a3)+
    lea     $14(sp),sp

l_FFC536EE:
    move.l  var_1C(a6),d0
    subq.l  #1,var_1C(a6)
    tst.l   d0
    bne.s   l_FFC536AC
    move.l  d4,-(sp)
    move.l  var_14(a6),-(sp)
    move.l  d5,-(sp)
    jsr     f_FFC535C0
    move.w  d0,d6
    lea     $C(sp),sp
    bra.s   l_FFC53712

l_FFC5370E:
    move.w  #$F617,d6

l_FFC53712:
    tst.l   var_18(a6)
    beq.s   l_FFC53722
    move.l  var_18(a6),-(sp)
    jsr     f_FFC4F490
    addq.w  #4,sp

l_FFC53722:
    tst.l   var_14(a6)
    beq.s   l_FFC53732
    move.l  var_14(a6),-(sp)
    jsr     f_FFC4F490
    addq.w  #4,sp

l_FFC53732:
    move.w  d6,d0
    movem.l var_38(a6),d4-d7/a2-a4
    unlk    a6
    rts

    align $10

; ===========================================================================
f_FFC53740:
    link    a6,#-8
    movem.l d6-d7,-(sp)
    moveq   #1,d6
    subq.l  #2,sp
    pea     var_8(a6)
    jsr     f_FFC4F4E2
    move.w  (sp)+,d7
    bra.s   l_FFC53786

l_FFC53758:
    moveq   #0,d0
    move.l  d0,var_4(a6)
    subq.l  #2,sp
    pea     var_8(a6)
    pea     aAssignedAddres_1 ; "assigned-addresses"
    moveq   #0,d0
    move.l  d0,-(sp)
    pea     var_4(a6)
    move.b  d6,-(sp)
    jsr     f_FFC4FA96
    move.w  (sp)+,d7
    bne.s   l_FFC53786
    move.l  var_8(a6),-(sp)
    jsr     f_FFC53640
    move.w  d0,d7
    addq.w  #4,sp

l_FFC53786:
    tst.w   d7
    beq.s   l_FFC53758
    movem.l var_10(a6),d6-d7
    unlk    a6
    rts

; ---------------------------------------------------------------------------
aAssignedAddres_1:dc.b 'assigned-addresses',0

                align $10

; ===========================================================================
f_FFC537B0:
    link    a6,#0
    moveq   #0,d0
    move.l  d0,-(sp)
    move.l  d0,-(sp)
    jsr     f_FFC52920
    jsr     f_FFC546B8
    jsr     f_FFC56900
    jsr     f_FFC53320
    jsr     f_FFC53740
    moveq   #0,d0
    unlk    a6
    rts

; ---------------------------------------------------------------------------
    align $10

    link    a6,#0
    unlk    a6
    rts
; ---------------------------------------------------------------------------
    align $10

    lea     unk_537FA,a0
    move.l  (loc_7B0).w,-(sp)
    rts
; ---------------------------------------------------------------------------
unk_537FA:
    dc.b   0
    dc.b   0
    dc.b   3
    dc.b $2F ; /
    dc.b $E9
    dc.b   4
    dc.b $BC
    dc.b $E8
    dc.b $CE
    dc.b $F8
    dc.b $CE
    dc.b $2C ; ,
    dc.b $C2
    dc.b $9C
    dc.b $C3
    dc.b $44 ; D
    dc.b $CA
    dc.b $A4
    dc.b $CD
    dc.b $68 ; h
    dc.b $CA
    dc.b $EA
    dc.b $CD
    dc.b $BA
    dc.b $CF
    dc.b $54 ; T
    dc.b $CF
    dc.b $BC
    dc.b $C8
    dc.b $34 ; 4
    dc.b $C8
    dc.b $A2
    dc.b $21 ; !
    dc.b $92
    dc.b $22 ; "
    dc.b $92
    dc.b $23 ; #
    dc.b $86
    dc.b $31 ; 1
    dc.b $E6
    dc.b $CF
    dc.b $FE
    dc.b $D0
    dc.b $7A ; z
    dc.b $D0
    dc.b $BE
    dc.b $DA
    dc.b $DE
    dc.b $26 ; &
    dc.b $1E
    dc.b $29 ; )
    dc.b $40 ; @
    dc.b $FF
    dc.b $E6
    dc.b $ED
    dc.b $EC
    dc.b $ED
    dc.b $CC
    dc.b $DC
    dc.b $28 ; (
    dc.b $DC
    dc.b $A0
    dc.b $1B
    dc.b $70 ; p
    dc.b $1B
    dc.b $F0
    dc.b $1C
    dc.b $60 ; `
    dc.b $1C
    dc.b $D4
    dc.b $1D
    dc.b $44 ; D
    dc.b $1D
    dc.b $B0
    dc.b $1E
    dc.b $2E ; .
    dc.b $1E
    dc.b $AE
    dc.b $1F
    dc.b $2E ; .
    dc.b $1F
    dc.b $B2
    dc.b $20
    dc.b $32 ; 2
    dc.b $20
    dc.b $AE
    dc.b $D8
    dc.b $9A
    dc.b   6
    dc.b $90
    dc.b   1
    dc.b $20
    dc.b   2
    dc.b $74 ; t
    dc.b   0
    dc.b   0
    dc.b   0
    dc.b   0
    dc.b   0
    dc.b   0
    dc.b   0
    dc.b   0

; ===========================================================================
; Call OpenFirmware client interface via _ExecuteRiscContext NK trap.
; The OF client interface entry point is implemented in the cientry word,
; FCode# = 0x45D located at LA 0xFF809E18.
; Return from OF client interface to 68k code is accomplished by executing
; an invalid PowerPC instruction.
;
; Params: (A7) - pointer to OF client interface argument array
; Returns: D0 = 0
; ===========================================================================
f_FFC53860:
    movea.l 4(sp),a0            ; A0 - ptr to OF client interface argument array
    movem.l d2-d3/a2-a4,-(sp)   ; save registers
    movea.l sp,a2               ; save stack pointer

    move.w  #$1CF,d2            ; size in dwords of NativeContextBlock
l_FFC5386E:
    clr.l   -(sp)               ; fill it with zeroes
    dbf     d2,l_FFC5386E       ;

    moveq   #$3F,d2             ;
    add.l   sp,d2               ;
    andi.w  #$FFC0,d2           ;
    movea.l d2,sp               ; align SP on a 64-byte boundary

    move.l  a0,$11C(sp)         ; CB.r3 = ptr to client interface argument array
    move.l  ($FF800000).l,$FC(sp) ; CB.PC = address of cientry from OF segment
    ori.l   #4,(sp)             ; CB.Flags = ecInvalidInstr
    lea     $700(sp),a3         ;
    move.l  a3,$10C(sp)         ; CB.r1 = SP + 0x700
    movea.l sp,a3               ;  A3  - ptr to NativeContextBlock
    move.l  a3,-(sp)            ; (SP) - ptr to NativeContextBlock

l_FFC5389C:
    _ExecuteRiscContext         ; execute OF cientry
    beq.s   l_FFC5389C          ; continue execution if there was an external int
    cmpi.b  #5,(a3)             ;
    beq.s   l_FFC538B0          ; go if mode switch cause = ecPrivilegedInstr

l_FFC538A6:
    moveq   #0,d0               ; result = 0
    movea.l a2,sp               ; restore stack pointer
    movem.l (sp)+,d2-d3/a2-a4   ; restore registers
    rts

l_FFC538B0:
    movea.l $FC(a3),a4          ; A4 = CB.PC
    move.l  (a4)+,d2            ; D2 - opcode at PowerPC PC
    move.l  a4,$FC(a3)          ; move CB.PC to next instruction
    move.l  #$FC0007FE,d3       ; mask for opcode checks
    and.l   d2,d3               ; extract the primary and secondary opcodes
    cmpi.l  #$4C000064,d3       ; if the faulty instruction was rfi
    beq.s   l_FFC538A6          ; we're done
    clr.b   (a3)                ; CB.Flags = ecNoException
    cmpi.l  #$7C0000A6,d3       ; was the faulty instruction mfmsr?
    bne.s   word_5389C          ; if not, continue native code execution
    bfextu  d2{6:5},d3          ; extract mfmsr destination reg number into D3
    move.l  #$F072,$104(a3,d3.l*8) ; stuff fake MSR value into that register
    bra.s   l_FFC5389C          ; continue native code execution

; ===========================================================================
; Transfer control to f_FFC53860.
; ===========================================================================
f_FFC538E4:
    movea.l (dword_208C).w,a0
    movea.l $128(a0),a0
    jmp     (a0)
