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
    export gfx16_Begin
    export gfx16_End
    export gfx16_BeginFrame
    export gfx16_EndFrame
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
VRAMSizeBytes   := LcdSize * 2
pSpiRange       := 0D000h
mpSpiRange      := 0F80000h
spiValid        := 8
pSpiValid       := pSpiRange + spiValid
mpSpiValid      := mpSpiRange + spiValid
spiStatus       := 12
pSpiStatus      := pSpiRange + spiStatus
mpSpiStatus     := mpSpiRange + spiStatus
spiData         := 24
pSpiData        := pSpiRange + spiData
mpSpiData       := mpSpiRange + spiData
;-------------------------------------------------------------------------------
macro breakPoint?
	push hl
    ld hl, -1
    ld (hl), 2
    pop hl
end macro

; SPI stuff by jacobly
macro spi cmd, params&
    ld a, cmd
    call spiCmd
    match any, params
        iterate param, any
            ld a, param
            call spiParam
        end iterate
    end match
end macro

;-------------------------------------------------------------------------------
gfx16_Begin:
; Sets up the display for gfx16.
; Arguments:
;  None
; Returns:
;  None
    call gfx16_ClearVRAM
    call ti.boot.InitializeHardware
    ld de, ti.lcdWatermark + ti.lcdIntFront + ti.lcdPwr + ti.lcdBgr + ti.lcdBpp16
    ld hl, ti.mpLcdBase
    ld bc, ti.vRam
    ld (hl), bc
    ld l, ti.lcdCtrl
    ld (hl), de
    spi $36, $28 ; sets LCD to column major update
    spi $2A, 0, 0, 0, $EF ; changes bounding of rows and columns
    spi $2B, 0, 0, 1, $3F
    ld hl, ti.mpLcdRange + 1
    ld de, _LcdTiming
    ld bc, 0
	ld b, 8 + 1 ; +1 because c = 0, so first ldi will decrement b
.ExchangeTimingLoop: ; exchange stored and active timing
	ld a, (de)
	ldi
	dec	hl
	ld (hl), a
	inc	hl
	djnz .ExchangeTimingLoop
    ret

spiParam:
    scf
    virtual
        jr nc, $
        load .jr_nc : byte from $$
    end virtual
    db .jr_nc
spiCmd:
    or a, a
    ld hl, mpSpiData or spiValid shl 8
    ld b, 3
.loop:	
    rla
    rla
    rla
    ld (hl), a
    djnz .loop
    ld l, h
    ld (hl), 1
.wait:
    ld l, spiStatus + 1
.wait1:
    ld a, (hl)
    and	a, $f0
    jr nz, .wait1
    dec	l
.wait2:
    bit	2, (hl)
    jr nz, .wait2
    ld l, h
    ld (hl), a
    ret

;-------------------------------------------------------------------------------
gfx16_End:
; Resets the display to the OS default.
; Arguments:
;  None
; Returns:
;  None
    ld de, ti.lcdNormalMode
    ld hl, ti.mpLcdBase
    ld l, ti.lcdCtrl
    ld (hl), de
    spi $B0, $11 ; enable framebuffer copies
    spi $36, $08 ; reset LCD defaults
    spi $2B, 0, 0, 0, $EF
    spi $2A, 0, 0, 1, $3F
    ld hl, ti.mpLcdRange + 1
    ld de, _LcdTiming
    ld bc, 0
	ld b, 8 + 1 ; +1 because c = 0, so first ldi will decrement b
.ExchangeTimingLoop: ; exchange stored and active timing
	ld a, (de)
	ldi
	dec	hl
	ld (hl), a
	inc	hl
	djnz .ExchangeTimingLoop
    ret

;-------------------------------------------------------------------------------
gfx16_BeginFrame:
; Marks the beginning of a logical frame.
; Arguments:
;  None
; Returns:
;  None
    ld a, (ti.mpLcdRis)
    and a, ti.lcdIntVcomp
    jr z, gfx16_BeginFrame
    ld (ti.mpLcdIcr), a
    spi $B0, $01 ; disable framebuffer copies
    spi $2C
    ret

;-------------------------------------------------------------------------------
gfx16_EndFrame:
; Marks the end of a logical frame.
; Arguments:
;  None
; Returns:
;  None
	ld a, (ti.mpLcdCurr + 2) ; a = *mpLcdCurr >> 16
	ld hl, (ti.mpLcdCurr + 1) ; hl = *mpLcdCurr >> 8
	sub a, h
	jr nz, gfx16_EndFrame ; nz ==> lcdCurr may have updated mid-read; retry read
    ld de, ti.vRamEnd
    or a, a
    sbc hl, de
    jr z, .resetVcomp
    ld a, ti.lcdIntVcomp
    ld (ti.mpLcdIcr), a
.loop:
    ld a, (ti.mpLcdRis)
    bit ti.bLcdIntVcomp, a
    jr z, .loop
.resetVcomp:
    ld a, ti.lcdIntVcomp
    ld (ti.mpLcdIcr), a
    spi $B0, $11 ; enable framebuffer copies
    ret

;-------------------------------------------------------------------------------
gfx16_SetColor:
; Sets the color that the library's drawing functions will use.
; Arguments:
;  arg0: 16 bit color to set.
; Returns:
;  Color that was set previously.
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

;-------------------------------------------------------------------------------
gfx16_SetPixel:
; Sets a pixel to the currently set drawing color.
; Arguments:
;  arg0: X coordinate of the pixel.
;  arg1: Y coordinate of the pixel.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld de, _GlobalColor
    ex de, hl
    ldi
    ldi
    ret

;-------------------------------------------------------------------------------
gfx16_GetPixel:
; Gets the current color of a pixel.
; Arguments:
;  arg0: X coordinate of the pixel.
;  arg1: Y coordinate of the pixel.
; Returns:
;  Color of the pixel.
    ld iy, 0
    add iy, sp
    call _getVramAddr
    ld de, 0
    ld e, (hl)
    inc hl
    ld d, (hl)
    ex de, hl
    ret

;-------------------------------------------------------------------------------
gfx16_InvertPixel:
; Inverts the color of a pixel.
; Arguments:
;  arg0: X coordinate of the pixel.
;  arg1: Y coordinate of the pixel.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_FillScreen:
; Fills the screen with the specified color.
; Arguments:
;  16 bit color to fill the screen with.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_ClearVRAM:
; Clears the screen and fills it with white.
; Arguments:
;  None
; Returns:
;  None
    ld hl, ti.vRam
    push hl
    pop de
    ld (hl), $FF
    inc de
    ld bc, VRAMSizeBytes - 1
    ldir
    ret

;-------------------------------------------------------------------------------
gfx16_FillRectangle:
; Draws a filled rectangle.
; Arguments:
;  arg0: X coordinate of the rectangle.
;  arg1: Y coordinate of the rectangle.
;  arg2: Width of the rectangle.
;  arg3: Height of the rectangle.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_FillInvertedRectangle:
; Draws a filled rectangle which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the rectangle.
;  arg1: Y coordinate of the rectangle.
;  arg2: Width of the rectangle.
;  arg3: Height of the rectangle.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_VertLine:
; Draws a vertical line.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_HorizLine:
; Draws a horizontal line.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_Rectangle:
; Draws an unfilled rectangle.
; Arguments:
;  arg0: X coordinate of the rectangle.
;  arg1: Y coordinate of the rectangle.
;  arg2: Width of the rectangle.
;  arg3: Height of the rectangle.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_InvertedVertLine:
; Draws a vertical line which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_InvertedHorizLine:
; Draws a horizontal line which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_InvertedRectangle:
; Draws an unfilled rectangle which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the rectangle.
;  arg1: Y coordinate of the rectangle.
;  arg2: Width of the rectangle.
;  arg3: Height of the rectangle.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
gfx16_Sprite:
; Draws a sprite.
; Arguments:
;  arg0: Pointer to an initialized sprite structure.
;  arg1: X coordinate of the sprite.
;  arg2: Y coordinate of the sprite.
; Returns:
;  None
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

;-------------------------------------------------------------------------------
_GlobalColor:
    rb 2
_TextFGColor:
    rb 2
_TextBGColor:
    rb 2
_LcdTiming:
;	db	14 shl 2 ; PPL shl 2
	db	7 ; HSW
	db	87 ; HFP
	db	63 ; HBP
	dw	(0 shl 10) + 319 ; (VSW shl 10) + LPP
	db	179 ; VFP
	db	0 ; VBP
	db	(0 shl 6) + (0 shl 5) + 0 ; (ACB shl 6) + (CLKSEL shl 5) + PCD_LO
; H = ((PPL + 1) * 16) + (HSW + 1) + (HFP + 1) + (HBP + 1) = 240 + 8 + 88 + 64 = 400
; V = (LPP + 1) + (VSW + 1) + VFP + VBP = 320 + 1 + 179 + 0 = 500
; CC = H * V * PCD * 2 = 400 * 500 * 2 * 2 = 800000
; Hz = 48000000 / CC = 60