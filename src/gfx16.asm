;-------------------------------------------------------------------------------
include 'include/library.inc'
;-------------------------------------------------------------------------------

library GFX16, 1

;-------------------------------------------------------------------------------
; no dependencies
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; v1 functions
;-------------------------------------------------------------------------------
    export gfx16_Set16bppMode
    export gfx16_SetColor
    export gfx16_SetPixel
    export gfx16_GetPixel
    export gfx16_InvertPixel
    export gfx16_FillScreen
    export gfx16_ClearVRAM
    export gfx16_FillRectangle
    export gfx16_FillInvertedRectangle
    export gfx16_VertLine
    export gfx16_HorizLine
    export gfx16_Rectangle
    export gfx16_InvertedVertLine
    export gfx16_InvertedHorizLine
    export gfx16_InvertedRectangle
    export gfx16_Sprite
;-------------------------------------------------------------------------------
LcdSize         := ti.lcdWidth * ti.lcdHeight
VRAMSizeBytes    := LcdSize * 2
;-------------------------------------------------------------------------------
macro breakPoint?
	push hl
    ld hl, -1
    ld (hl), 2
    pop hl
end macro
;-------------------------------------------------------------------------------
gfx16_Set16bppMode:
    call gfx16_ClearVRAM
    ld de, ti.lcdNormalMode
    ld hl, ti.mpLcdBase
    ld bc, ti.vRam
    ld (hl), bc
    ld l, ti.lcdCtrl
    ld (hl), de
    ret

gfx16_SetColor:
    pop hl
    pop de
    push de
    push hl
    ld hl, _GlobalColor
    ld bc, 0
    ld c, (hl)
    inc hl
    ld b, (hl)
    ld (hl), d
    dec hl
    ld (hl), e
    push bc
    pop hl
    ret

gfx16_SetPixel:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld de, _GlobalColor
    ex de, hl
    ldi
    ldi
    ret

gfx16_GetPixel:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld de, 0
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret

gfx16_InvertPixel:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    ld a, (hl)
    cpl
    ld (hl), a
    ret

gfx16_FillScreen:
    pop hl
    pop de
    push de
    push hl
    ld hl, ti.vRam
    ld (hl), e
    inc hl
    ld (hl), d
    push hl
    pop de
    dec hl
    inc de
    ld bc, VRAMSizeBytes - 2
    ldir
    ret

gfx16_ClearVRAM:
    ld hl, ti.vRam
    push hl
    pop de
    ld (hl), $FF
    inc de
    ld bc, VRAMSizeBytes - 1
    ldir
    ret

gfx16_FillRectangle:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld bc, (iy + 9)
    ld a, b
    or a, c
    ret z
    xor a, a
    cp a, (iy + 12)
    ret z
    ld de, (_GlobalColor)
    push bc
    push hl

.loop:
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    dec bc
    ld a, b
    or a, c
    jr nz, .loop
    pop hl
    ld bc, ti.lcdWidth * 2
    add hl, bc
    dec (iy + 12)
    pop bc
    ret z
    push bc
    push hl
    jr .loop

gfx16_FillInvertedRectangle:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld bc, (iy + 9)
    ld a, b
    or a, c
    ret z
    xor a, a
    cp a, (iy + 12)
    ret z
    push bc
    push hl

.loop:
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    dec bc
    ld a, b
    or a, c
    jr nz, .loop
    pop hl
    ld bc, ti.lcdWidth * 2
    add hl, bc
    dec (iy + 12)
    pop bc
    ret z
    push bc
    push hl
    jr .loop

gfx16_VertLine:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld b, (iy + 9)
    xor a, a
    or a, b
    ret z
_VertLine_LoadColor:
    ld de, (_GlobalColor)
    ld a, b
    ld bc, ti.lcdWidth * 2

.drawLoop:
    ld (hl), e
    inc hl
    ld (hl), d
    dec hl
    add hl, bc
    dec a
    ret z
    jr .drawLoop

gfx16_HorizLine:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld bc, (iy + 9)
    ld a, b
    or a, c
    ret z
_HorizLine_LoadColor:
    ld de, (_GlobalColor)

.drawLoop:
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    dec bc
    ld a, b
    or a, c
    ret z
    jr .drawLoop

gfx16_Rectangle:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld bc, (iy + 9)
    ld a, b
    or a, c
    ret z
    ld b, (iy + 12)
    xor a, a
    or a, b
    ret z
    push hl
    call _VertLine_LoadColor
    pop de
    ld hl, (iy + 9)
    dec hl
    ld a, h
    or a, l
    ret z
    add hl, hl
    add hl, de
    ld b, (iy + 12)
    call _VertLine_LoadColor
    call _getVramAddr
    ld bc, (iy + 9)
    call _HorizLine_LoadColor
    ld c, (iy + 6)
    ld a, (iy + 12)
    dec a
    ret z
    add a, c
    ld (iy + 6), a
    call _getVramAddr
    ld bc, (iy + 9)
    jp _HorizLine_LoadColor

gfx16_InvertedVertLine:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld b, (iy + 9)
    xor a, a
    or a, b
    ret z
_InvertVertLine:
    ld de, ti.lcdWidth * 2

.drawLoop:
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    ld a, (hl)
    cpl
    ld (hl), a
    dec hl
    add hl, de
    djnz .drawLoop
    ret

gfx16_InvertedHorizLine:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld bc, (iy + 9)
    ld a, b
    or a, c
    ret z

_InvertHorizLine:
.drawLoop:
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    dec bc
    ld a, b
    or a, c
    ret z
    jr .drawLoop

gfx16_InvertedRectangle:
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld bc, (iy + 9)
    ld a, b
    or a, c
    ret z
    ld b, (iy + 12)
    xor a, a
    or a, b
    ret z
    push hl
    call _InvertVertLine
    pop de
    ld hl, (iy + 9)
    dec hl
    ld a, h
    or a, l
    ret z
    add hl, hl
    add hl, de
    ld b, (iy + 12)
    call _InvertVertLine
    call _getVramAddr
    ld bc, (iy + 9)
    dec bc
    ld a, b
    or a, c
    ret z
    dec bc
    ld a, b
    or a, c
    ret z
    inc hl
    inc hl
    call _InvertHorizLine
    ld c, (iy + 6)
    ld a, (iy + 12)
    dec a
    ret z
    add a, c
    ld (iy + 6), a
    call _getVramAddr
    inc hl
    inc hl
    ld bc, (iy + 9)
    dec bc
    dec bc
    jp _InvertHorizLine

_getVramAddr: ; returns address in hl
    ld a, (iy + 6)
    ld hl, ti.vRam
    ld de, ti.lcdWidth * 2
    ld b, a
    xor a, a
    cp a, b
    jr z, .foundCoord

.loopCoord:
    add hl, de
    djnz .loopCoord

.foundCoord:
    ex de, hl
    ld hl, (iy + 3)
    add hl, hl
    add hl, de
    ret

gfx16_Sprite:
    ld iy, 3
    add iy, sp
    call _getVramAddr
    ld de, (iy)
    ex de, hl
    ld bc, (hl)
    inc hl
    inc hl
    ld iyl, c
    push de

.spriteLoop:
    ldi
    inc c
    ldi
    xor a, a
    or a, c
    jr nz, .spriteLoop
    pop de
    dec b
    ret z
    ex de, hl
    push de
    ld de, ti.lcdWidth * 2
    add hl, de
    pop de
    ex de, hl
    ld c, iyl
    push de
    jr .spriteLoop

_GlobalColor:
    rb 2
_TextFGColor:
    rb 2
_TextBGColor:
    rb 2
