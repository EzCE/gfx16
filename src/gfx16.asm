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
    export gfx16_SetTransparentColor
    export gfx16_SetClipRegion
    export gfx16_SetPixel
    export gfx16_GetPixel
    export gfx16_InvertPixel
    export gfx16_FillScreen
    export gfx16_ClearVRAM
    export gfx16_FillRectangle_NoClip
    export gfx16_FillRectangle
    export gfx16_FillInvertedRectangle_NoClip
    export gfx16_FillInvertedRectangle
    export gfx16_VertLine
    export gfx16_VertLine_NoClip
    export gfx16_HorizLine
    export gfx16_HorizLine_NoClip
    export gfx16_Rectangle
    export gfx16_Rectangle_NoClip
    export gfx16_InvertedVertLine
    export gfx16_InvertedVertLine_NoClip
    export gfx16_InvertedHorizLine
    export gfx16_InvertedHorizLine_NoClip
    export gfx16_InvertedRectangle
    export gfx16_InvertedRectangle_NoClip
    export gfx16_Sprite
    export gfx16_TransparentSprite
    export gfx16_Sprite_NoClip
    export gfx16_TransparentSprite_NoClip
    export gfx16_ScaledSprite_NoClip
    export gfx16_ScaledTransparentSprite_NoClip
    export gfx16_PutChar
    export gfx16_PutString
    export gfx16_PutStringXY
    export gfx16_SetTextXY
    export gfx16_SetTextScale
    export gfx16_SetTextFGColor
    export gfx16_SetTextBGColor
    export gfx16_SetTextTransparentColor
    export gfx16_SetFontSpacing
    export gfx16_SetFontData
    export gfx16_SetCharWidth
    export gfx16_SetCharData
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

macro isHLLessThanDE?
    or a, a
    sbc hl, de
    add hl, hl
    jp po, $ + 5
    ccf
end macro

macro isHLLessThanBC?
    or a, a
    sbc hl, bc
    add hl, hl
    jp po, $ + 5
    ccf
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
    dec hl
    ld (hl), a
    inc hl
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
    and a, $f0
    jr nz, .wait1
    dec l

.wait2:
    bit 2, (hl)
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
    call gfx16_ClearVRAM
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
    dec hl
    ld (hl), a
    inc hl
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
    ld bc, (hl)
    ld (hl), de
    push bc
    pop hl
    ret

;-------------------------------------------------------------------------------
gfx16_SetTransparentColor:
; Sets the color that the library's transparent drawing functions will use.
; Arguments:
;  arg0: 16 bit color to set.
; Returns:
;  Color that was set previously.
    pop hl
    pop de
    push de
    push hl
    ld hl, _TransColor
    ld bc, (hl)
    ld (hl), de
    push bc
    pop hl
    ret

;-------------------------------------------------------------------------------
gfx16_SetClipRegion:
; Sets the dimensions of the drawing window for all clipped routines.
; Arguments:
;  arg0: Minimum X coordinate, inclusive.
;  arg1: Minimum Y coordinate, inclusive.
;  arg2: Maximum X coordinate, exclusive.
;  arg3: Maximum X coordinate, exclusive.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld hl, _ClipRegion_Full
    call .copy
    ld iy, 0
    add iy, sp
    call _ClipRegion
    ret c
    lea hl, iy + 3

.copy:
    ld de, _XMin
    ld bc, 4 * 3
    ldir
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
    ld bc, 0
    ld c, (iy + 6)
    ld hl, -ti.lcdHeight
    add hl, bc
    ret c
    ld bc, (iy + 3)
    ld hl, -ti.lcdWidth
    add hl, bc
    ret c
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
    ld bc, 0
    ld bc, (iy + 6)
    ld hl, -ti.lcdHeight
    add hl, bc
    ret c
    ld bc, (iy + 3)
    ld hl, -ti.lcdWidth
    add hl, bc
    ret c
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
; Draws a clipped filled rectangle.
; Arguments:
;  arg0: X coordinate of the rectangle.
;  arg1: Y coordinate of the rectangle.
;  arg2: Width of the rectangle.
;  arg3: Height of the rectangle.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld hl, (iy + 9) ; hl = width
    ld de, (iy + 3) ; de = x coordinate
    add hl, de
    ld (iy + 9), hl
    ld hl, (iy + 12) ; hl = height
    ld de, (iy + 6) ; de = y coordinate
    add hl, de
    ld (iy + 12), hl
    call _ClipRegion
    ret c ; return if offscreen or degenerate
    ld de, (iy + 3)
    ld hl, (iy + 9)
    sbc hl, de
    ld (iy + 9), hl
    ld de, (iy + 6)
    ld hl, (iy + 12)
    sbc hl, de
    ld (iy + 12), hl
    jr _FillRectangle_NoClip

;-------------------------------------------------------------------------------
gfx16_FillRectangle_NoClip:
; Draws an unclipped filled rectangle.
; Arguments:
;  arg0: X coordinate of the rectangle.
;  arg1: Y coordinate of the rectangle.
;  arg2: Width of the rectangle.
;  arg3: Height of the rectangle.
; Returns:
;  None
    ld iy, 0
    add iy, sp

_FillRectangle_NoClip:
    call _getVramAddr
    ld bc, (iy + 9)
    ld a, b
    or a, c
    ret z
    ld a, (iy + 12)
    or a, a
    ret z
    ld de, (_GlobalColor)
    push bc
    push hl
    ld b, a

.loop:
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    djnz .loop
    pop hl
    ld bc, ti.lcdHeight * 2
    add hl, bc
    pop bc
    dec bc
    ld a, b
    or a, c
    ret z
    push bc
    push hl
    ld b, (iy + 12)
    jr .loop

;-------------------------------------------------------------------------------
gfx16_FillInvertedRectangle:
; Draws a clipped filled rectangle which inverts the colors it overlaps with
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
    ld hl, (iy + 9) ; hl = width
    ld de, (iy + 3) ; de = x coordinate
    add hl, de
    ld (iy + 9), hl
    ld hl, (iy + 12) ; hl = height
    ld de, (iy + 6) ; de = y coordinate
    add hl, de
    ld (iy + 12), hl
    call _ClipRegion
    ret c ; return if offscreen or degenerate
    ld de, (iy + 3)
    ld hl, (iy + 9)
    sbc hl, de
    ld (iy + 9), hl
    ld de, (iy + 6)
    ld hl, (iy + 12)
    sbc hl, de
    ld (iy + 12), hl
    jr _FillInvertedRectangle_NoClip

;-------------------------------------------------------------------------------
gfx16_FillInvertedRectangle_NoClip:
; Draws an unclipped filled rectangle which inverts the colors it overlaps with
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

_FillInvertedRectangle_NoClip:
    call _getVramAddr
    ld bc, (iy + 9)
    ld a, b
    or a, c
    ret z
    ld a, (iy + 12)
    or a, a
    ret z
    push bc
    push hl
    ld b, a

.loop:
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    djnz .loop
    pop hl
    ld bc, ti.lcdHeight * 2
    add hl, bc
    pop bc
    dec bc
    ld a, b
    or a, c
    ret z
    push bc
    push hl
    ld b, (iy + 12)
    jr .loop

;-------------------------------------------------------------------------------
gfx16_VertLine:
; Draws a clipped vertical line.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld hl, (_XMax)
    dec hl ; inclusive
    ld de, (iy + 3) ; x
    isHLLessThanDE
    ret c ; x > xmax
    ld hl, (_XMin)
    ex de, hl
    isHLLessThanDE
    ret c ; x < xmin
    ld hl, (iy + 9) ; length
    ld de, (iy + 6) ; y
    add hl, de
    ld (iy + 9), hl
    ld hl, (_YMin)
    call _Maximum ; get minimum y
    ld (iy + 6), hl
    ld hl, (_YMax)
    ld de, (iy + 9)
    call _Minimum ; get maximum y
    ld (iy + 9), hl
    ld de, (iy + 6)
    isHLLessThanDE
    ret c ; return if not within y bounds
    ld hl, (iy + 9)
    sbc hl, de
    ld (iy + 6), e
    ld (iy + 9), l
    ld bc, 0
    ld c, l
    jr _VertLine_NoClip

;-------------------------------------------------------------------------------
gfx16_VertLine_NoClip:
; Draws an unclipped vertical line.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld bc, 0
    ld c, (iy + 9)

_VertLine_NoClip:
    ld a, b
    or a, c
    ret z ; return if length is 0
    call _getVramAddr
    push hl
    push bc
    pop hl
    add hl, hl
    push hl
    pop bc
    pop hl
    ld de, (_GlobalColor)
    ld (hl), e
    inc hl
    ld (hl), d
    dec bc
    dec bc
    ld a, b
    or a, c
    ret z
    push hl
    pop de
    dec hl
    inc de
    ldir
    ret

;-------------------------------------------------------------------------------
gfx16_HorizLine:
; Draws a clipped horizontal line.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld hl, (_YMax)
    dec hl ; inclusive
    ld de, (iy + 6) ; y
    isHLLessThanDE
    ret c ; y < ymin
    ld hl, (_YMin)
    ex de, hl
    isHLLessThanDE
    ret c ; x < xmin
    ld hl, (iy + 9) ; length
    ld de, (iy + 3) ; x
    add hl, de
    ld (iy + 9), hl
    ld hl, (_XMin)
    call _Maximum ; get minimum x
    ld (iy + 3), hl
    ld hl, (_XMax)
    ld de, (iy + 9)
    call _Minimum ; get maximum x
    ld (iy + 9), hl
    ld de, (iy + 3)
    isHLLessThanDE
    ret c ; return if not within x bounds
    ld hl, (iy + 9)
    sbc hl, de
    ld (iy + 3), de
    ld (iy + 9), hl
    push hl
    pop bc
    jr _HorizLine_NoClip

;-------------------------------------------------------------------------------
gfx16_HorizLine_NoClip:
; Draws a horizontal line without clipping.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld bc, (iy + 9)

_HorizLine_NoClip:
    ld a, b
    or a, c
    ret z ; return if length is 0
    call _getVramAddr
    ld de, (_GlobalColor)

.loop:
    ld (hl), e
    inc hl
    ld (hl), d
    dec hl
    push de
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de
    dec bc
    ld a, b
    or a, c
    jr nz, .loop
    ret

;-------------------------------------------------------------------------------
gfx16_Rectangle:
; Draws a clipped unfilled rectangle.
; Arguments:
;  arg0: X coordinate of the rectangle.
;  arg1: Y coordinate of the rectangle.
;  arg2: Width of the rectangle.
;  arg3: Height of the rectangle.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld hl, (iy + 9) ; hl = width
    ld de, (iy + 3) ; de = x coordinate
    add hl, de
    ld (iy + 9), hl
    ld hl, (iy + 12) ; hl = height
    ld de, (iy + 6) ; de = y coordinate
    add hl, de
    ld (iy + 12), hl
    call _ClipRegion
    ret c ; return if offscreen or degenerate
    ld de, (iy + 3)
    ld hl, (iy + 9)
    sbc hl, de
    ld (iy + 9), hl
    ld de, (iy + 6)
    ld hl, (iy + 12)
    sbc hl, de
    ld (iy + 12), hl
    jr _Rectangle_NoClip

;-------------------------------------------------------------------------------
gfx16_Rectangle_NoClip:
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

_Rectangle_NoClip:
    ld hl, (iy + 9)
    ld a, h
    or a, l
    ret z
    ld bc, 0
    ld c, (iy + 12)
    xor a, a
    or a, c
    ret z
    push hl
    push bc
    call _VertLine_NoClip
    pop bc
    pop de
    ld hl, (iy + 3)
    dec hl
    ld a, h
    or a, l
    ret z
    add hl, de
    ld de, (iy + 3)
    push de
    ld (iy + 3), hl
    call _VertLine_NoClip
    pop de
    ld (iy + 3), de
    ld bc, (iy + 9)
    call _HorizLine_NoClip
    ld c, (iy + 6)
    ld a, (iy + 12)
    dec a
    ret z
    add a, c
    ld (iy + 6), a
    ld bc, (iy + 9)
    jp _HorizLine_NoClip

;-------------------------------------------------------------------------------
gfx16_InvertedVertLine:
; Draws a clipped vertical line which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld hl, (_XMax)
    dec hl ; inclusive
    ld de, (iy + 3) ; x
    isHLLessThanDE
    ret c ; x > xmax
    ld hl, (_XMin)
    ex de, hl
    isHLLessThanDE
    ret c ; x < xmin
    ld hl, (iy + 9) ; length
    ld de, (iy + 6) ; y
    add hl, de
    ld (iy + 9), hl
    ld hl, (_YMin)
    call _Maximum ; get minimum y
    ld (iy + 6), hl
    ld hl, (_YMax)
    ld de, (iy + 9)
    call _Minimum ; get maximum y
    ld (iy + 9), hl
    ld de, (iy + 6)
    isHLLessThanDE
    ret c ; return if not within y bounds
    ld hl, (iy + 9)
    sbc hl, de
    ld (iy + 6), e
    ld (iy + 9), l
    ld bc, 0
    ld c, l
    jr _InvertedVertLine_NoClip

;-------------------------------------------------------------------------------
gfx16_InvertedVertLine_NoClip:
; Draws an unclipped vertical line which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld bc, 0
    ld c, (iy + 9)

_InvertedVertLine_NoClip:
    ld a, b
    or a, c
    ret z ; return if length is 0
    call _getVramAddr

.loop:
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    dec c
    jr nz, .loop
    ret

;-------------------------------------------------------------------------------
gfx16_InvertedHorizLine:
; Draws a clipped horizontal line which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld hl, (_YMax)
    dec hl ; inclusive
    ld de, (iy + 6) ; y
    isHLLessThanDE
    ret c ; y < ymin
    ld hl, (_YMin)
    ex de, hl
    isHLLessThanDE
    ret c ; x < xmin
    ld hl, (iy + 9) ; length
    ld de, (iy + 3) ; x
    add hl, de
    ld (iy + 9), hl
    ld hl, (_XMin)
    call _Maximum ; get minimum x
    ld (iy + 3), hl
    ld hl, (_XMax)
    ld de, (iy + 9)
    call _Minimum ; get maximum x
    ld (iy + 9), hl
    ld de, (iy + 3)
    isHLLessThanDE
    ret c ; return if not within x bounds
    ld hl, (iy + 9)
    sbc hl, de
    ld (iy + 3), de
    ld (iy + 9), hl
    push hl
    pop bc
    jr _InvertedHorizLine_NoClip

;-------------------------------------------------------------------------------
gfx16_InvertedHorizLine_NoClip:
; Draws an unclipped horizontal line which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the line.
;  arg1: Y coordinate of the line.
;  arg2: Length of the line.
; Returns:
;  None
    ld iy, 0
    add iy, sp
    ld bc, (iy + 9)

_InvertedHorizLine_NoClip:
    ld a, b
    or a, c
    ret z ; return if length is 0
    call _getVramAddr

.loop:
    ld a, (hl)
    cpl
    ld (hl), a
    inc hl
    ld a, (hl)
    cpl
    ld (hl), a
    dec hl
    push de
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de
    dec bc
    ld a, b
    or a, c
    jr nz, .loop
    ret

;-------------------------------------------------------------------------------
gfx16_InvertedRectangle:
; Draws a clipped unfilled rectangle which inverts the colors it overlaps with
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
    ld hl, (iy + 9) ; hl = width
    ld de, (iy + 3) ; de = x coordinate
    add hl, de
    ld (iy + 9), hl
    ld hl, (iy + 12) ; hl = height
    ld de, (iy + 6) ; de = y coordinate
    add hl, de
    ld (iy + 12), hl
    call _ClipRegion
    ret c ; return if offscreen or degenerate
    ld de, (iy + 3)
    ld hl, (iy + 9)
    sbc hl, de
    ld (iy + 9), hl
    ld de, (iy + 6)
    ld hl, (iy + 12)
    sbc hl, de
    ld (iy + 12), hl
    jr _InvertedRectangle_NoClip

;-------------------------------------------------------------------------------
gfx16_InvertedRectangle_NoClip:
; Draws an unfilled rectangle which inverts the colors it overlaps with
; rather than drawing with a specified color.
; Arguments:
;  arg0: X coordinate of the rectangle.
;  arg1: Y coordinate of the rectangle.
;  arg2: Width of the rectangle.
;  arg3: Height of the rectangle.
; Returns:
;  None-
    ld iy, 0
    add iy, sp

_InvertedRectangle_NoClip:
    ld hl, (iy + 9)
    ld a, h
    or a, l
    ret z
    ld bc, 0
    ld c, (iy + 12)
    xor a, a
    or a, c
    ret z
    push hl
    push bc
    call _InvertedVertLine_NoClip
    pop bc
    pop de
    ld hl, (iy + 3)
    dec hl
    ld a, h
    or a, l
    ret z
    add hl, de
    ld de, (iy + 3)
    push de
    ld (iy + 3), hl
    call _InvertedVertLine_NoClip
    pop de
    inc de
    ld (iy + 3), de
    ld bc, (iy + 9)
    dec bc
    dec bc
    call _InvertedHorizLine_NoClip
    ld c, (iy + 6)
    ld a, (iy + 12)
    dec a
    ret z
    add a, c
    ld (iy + 6), a
    ld bc, (iy + 9)
    dec bc
    dec bc
    jp _InvertedHorizLine_NoClip

;-------------------------------------------------------------------------------
gfx16_Sprite:
; Draws a clipped sprite.
; Arguments:
;  arg0: Pointer to an initialized sprite structure.
;  arg1: X coordinate of the sprite.
;  arg2: Y coordinate of the sprite.
; Returns:
;  None
    push ix
    call _ClipCoordinates
    pop ix
    ret nc
    ld (.amount), a ; skip amount
    ld b, (iy + 0)
    ld c, (iy + 3)
    ld de, (iy + 6)
    ld iy, 3
    add iy, sp
    push de
    call _getVramAddr
    ex de, hl
    pop hl
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
    push de ; sprite ptr
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de ; de = sprite ptr
    push hl ; vram ptr
    ex de, hl ; hl = sprite ptr
    ld c, iyl
    ld de, 0

.amount := $ - 3
    add hl, de
    add hl, de
    pop de ; de = vram ptr
    push de
    jr .spriteLoop

;-------------------------------------------------------------------------------
gfx16_TransparentSprite:
; Draws a clipped transparent sprite.
; Arguments:
;  arg0: Pointer to an initialized sprite structure.
;  arg1: X coordinate of the sprite.
;  arg2: Y coordinate of the sprite.
; Returns:
;  None
    ld hl, (_TransColor)
    ld a, l
    ld (.chkByte1), a
    ld a, h
    ld (.chkByte2), a
    push ix
    call _ClipCoordinates
    pop ix
    ret nc
    ld (.amount), a ; skip amount
    ld b, (iy + 0)
    ld c, (iy + 3)
    ld de, (iy + 6)
    ld iy, 3
    add iy, sp
    push de
    call _getVramAddr
    ex de, hl
    pop hl
    ld iyl, c
    push de

.spriteLoop:
    ld a, 0

.chkByte1 := $ - 1
    cp a, (hl)
    inc hl
    jr nz, .draw
    ld a, 0

.chkByte2 := $ - 1
    cp a, (hl)
    jr nz, .draw
    inc hl
    inc de
    inc de
    dec c
    jr .drawDone

.draw:
    dec hl
    ldi
    inc c
    ldi
    xor a, a
    or a, c

.drawDone:
    jr nz, .spriteLoop
    pop de
    dec b
    ret z
    ex de, hl
    push de ; sprite ptr
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de ; de = sprite ptr
    push hl ; vram ptr
    ex de, hl ; hl = sprite ptr
    ld c, iyl
    ld de, 0

.amount := $ - 3
    add hl, de
    add hl, de
    pop de ; de = vram ptr
    push de
    jr .spriteLoop

;-------------------------------------------------------------------------------
gfx16_Sprite_NoClip:
; Draws an unclipped sprite.
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
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de
    ex de, hl
    ld c, iyl
    push de
    jr .spriteLoop

;-------------------------------------------------------------------------------
gfx16_TransparentSprite_NoClip:
; Draws an unclipped transparent sprite.
; Arguments:
;  arg0: Pointer to an initialized sprite structure.
;  arg1: X coordinate of the sprite.
;  arg2: Y coordinate of the sprite.
; Returns:
;  None
    ld hl, (_TransColor)
    ld a, l
    ld (.chkByte1), a
    ld a, h
    ld (.chkByte2), a
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
    ld a, 0

.chkByte1 := $ - 1
    cp a, (hl)
    inc hl
    jr nz, .draw
    ld a, 0

.chkByte2 := $ - 1
    cp a, (hl)
    jr nz, .draw
    inc hl
    inc de
    inc de
    dec c
    jr .drawDone

.draw:
    dec hl
    ldi
    inc c
    ldi
    xor a, a
    or a, c

.drawDone:
    jr nz, .spriteLoop
    pop de
    dec b
    ret z
    ex de, hl
    push de
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de
    ex de, hl
    ld c, iyl
    push de
    jr .spriteLoop

;-------------------------------------------------------------------------------
gfx16_ScaledSprite_NoClip:
; Draws a scaled unclipped sprite.
; Arguments:
;  arg0: Pointer to an initialized sprite structure.
;  arg1: X coordinate of the sprite.
;  arg2: Y coordinate of the sprite.
;  arg3: Width scaling factor.
;  arg4: Height scaling factor.
; Returns:
;  None
    ld iy, 3
    add iy, sp
    call _getVramAddr
    ld de, (iy)
    ex de, hl
    ld a, (iy + 12)
    ld (.scaleHeight), a
    ld iy, (iy + 9)
    ld iyh, a
    ld a, iyl
    ld (.scaleWidth), a
    ld bc, (hl)
    ld a, c
    ld (.height), a
    push de
    inc hl
    inc hl
    push hl

.spriteLoop:
    ldi
    inc c
    ldi
    dec iyh
    jr z, .heightScaled
    dec hl ; scale not yet complete
    dec hl
    inc c
    jr $ + 5

.heightScaled:
    ld iyh, 0

.scaleHeight := $ - 1
    xor a, a
    or a, c
    jr nz, .spriteLoop
    dec iyl
    jr z, .widthScaled
    pop hl ; scale not complete
    inc b
    jr .skip

.widthScaled:
    pop de
    ld iyl, 0

.scaleWidth := $ - 1
.skip:
    pop de
    dec b
    ret z
    ex de, hl
    push de
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de
    ex de, hl
    ld c, 0

.height := $ - 1
    push de
    push hl
    jr .spriteLoop

;-------------------------------------------------------------------------------
gfx16_ScaledTransparentSprite_NoClip:
; Draws a scaled unclipped transparent sprite.
; Arguments:
;  arg0: Pointer to an initialized sprite structure.
;  arg1: X coordinate of the sprite.
;  arg2: Y coordinate of the sprite.
;  arg3: Width scaling factor.
;  arg4: Height scaling factor.
; Returns:
;  None
    ld hl, (_TransColor)
    ld a, l
    ld (.chkByte1), a
    ld a, h
    ld (.chkByte2), a
    ld iy, 3
    add iy, sp
    call _getVramAddr
    ld de, (iy)
    ex de, hl
    ld a, (iy + 12)
    ld (.scaleHeight), a
    ld iy, (iy + 9)
    ld iyh, a
    ld a, iyl
    ld (.scaleWidth), a
    ld bc, (hl)
    ld a, c
    ld (.height), a
    push de
    inc hl
    inc hl
    push hl

.spriteLoop:
    ld a, 0

.chkByte1 := $ - 1
    cp a, (hl)
    inc hl
    jr nz, .draw
    ld a, 0

.chkByte2 := $ - 1
    cp a, (hl)
    jr nz, .draw
    inc hl
    inc de
    inc de
    dec c
    jr .drawDone

.draw:
    dec hl
    ldi
    inc c
    ldi

.drawDone:
    dec iyh
    jr z, .heightScaled
    dec hl ; scale not yet complete
    dec hl
    inc c
    jr $ + 5

.heightScaled:
    ld iyh, 0

.scaleHeight := $ - 1
    xor a, a
    or a, c
    jr nz, .spriteLoop
    dec iyl
    jr z, .widthScaled
    pop hl ; scale not complete
    inc b
    jr .skip

.widthScaled:
    pop de
    ld iyl, 0

.scaleWidth := $ - 1
.skip:
    pop de
    dec b
    ret z
    ex de, hl
    push de
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de
    ex de, hl
    ld c, 0

.height := $ - 1
    push de
    push hl
    jr .spriteLoop

;-------------------------------------------------------------------------------
gfx16_PutChar:
; Draws a single character at the current cursor position.
; Arguments:
;  arg0: Character to draw.
; Returns:
;  None
    pop hl
    pop de
    push de ; e = char
    push hl

_PutChar:
    ld iy, $0101

.scaleInitial := $ - 3
    or a, a
    sbc hl, hl
    ld l, e
    push hl
    ld bc, (_CharSpacing)
    add hl, bc
    ld b, (hl)
    ld hl, ti.vRam
    ld de, 0

.cursorX := $ - 3
    ; set a = ((x & $100) * lcdHeight) >> 8
    ld a, d
    ld d, ti.lcdHeight
    rra
    sbc a, a
    and a, d
    mlt de
    add hl, de
    add hl, de
    ; add ((x & $100) * lcdHeight + y) * 2
    ld d, a
    ld e, 0

.cursorY := $ - 1
    add hl, de
    add hl, de
    push hl
    ld de, 0
    ld e, b
    ld d, iyl
    mlt de
    ld hl, (.cursorX)
    add hl, de
    ld (.cursorX), hl
    pop de
    pop hl
    ld h, 8
    mlt hl
    push bc
    ld bc, (_TextData)
    add hl, bc
    pop bc

.loop:
    push hl
    push de
    ld a, (hl)
    ld c, 8 ; height
    push af

.loopByte:
    pop af
    add a, a
    push af
    jr c, .drawFG
    ld hl, $FFFF

.textBGColor := $ - 3
    jr .draw

.drawFG:
    ld hl, $0000

.textFGColor := $ - 3
.draw:
    push bc
    ld bc, $FFFF

.textTransparentColor := - 3
    or a, a
    push hl
    sbc.sis hl, bc
    pop hl
    pop bc
    jr nz, .putPixel
    inc de
    jr .drawDone

.putPixel:
    ld a, l
    ld (de), a
    inc de
    ld a, h
    ld (de), a

.drawDone:
    inc de
    dec iyh
    jr nz, .draw

.heightScaled:
    ld iyh, 1

.scaleHeight := $ - 1
    dec c
    xor a, a
    or a, c
    jr nz, .loopByte
    pop af
    pop hl ; vram
    pop de ; char data
    dec iyl
    jr z, .widthScaled
    inc b
    jr .skip

.widthScaled:
    inc de
    ld iyl, 1

.scaleWidth := $ - 1
.skip:
    dec b
    ret z
    push de
    ld de, ti.lcdHeight * 2
    add hl, de
    ex de, hl
    pop hl ; character data
    jr .loop

;-------------------------------------------------------------------------------
gfx16_PutStringXY:
; Draws a string at a specified cursor position.
; Arguments:
;  arg0: Pointer to the null-terminated string to draw.
;  arg1: Top-left cursor X coordinate.
;  arg2: Top-left cursor Y coordinate.
; Returns:
;  None
    pop iy
    pop bc
    call gfx16_SetTextXY
    push bc
    ex (sp), hl
    push iy
    jr gfx16_PutString.loop

;-------------------------------------------------------------------------------
gfx16_PutString:
; Draws a string at the current cursor position.
; Arguments:
;  arg0: Pointer to the null-terminated string to draw.
; Returns:
;  None
    pop de
    pop hl
    push hl
    push de

.loop:
    xor a, a
    ld e, (hl)
    or a, e
    ret z
    push hl
    call _PutChar
    pop hl
    inc hl
    jr .loop

;-------------------------------------------------------------------------------
gfx16_SetTextXY:
; Sets the text cursor position.
; Arguments:
;  arg0: Top-left cursor X coordinate.
;  arg1: Top-left cursor Y coordinate.
; Returns:
;  None
    pop de
    pop hl
    ld (_PutChar.cursorX), hl
    ex (sp), hl
    push hl
    push de
    ld a, l
    ld (_PutChar.cursorY), a
    ret

;-------------------------------------------------------------------------------
gfx16_SetTextScale:
; Sets the text scaling factors.
; Arguments:
;  arg0: New text width scale factor.
;  arg1: New text height scale factor.
; Returns:
;  None
    pop de
    pop hl
    ld a, l
    or a, a
    jr z, .skipWidth
    ld (_PutChar.scaleWidth), a
    ld (_PutChar.scaleInitial), hl

.skipWidth:
    ex (sp), hl
    push hl
    push de
    ld a, l
    or a, a
    ret z
    ld (_PutChar.scaleHeight), a
    ld (_PutChar.scaleInitial + 1), a
    ret

;-------------------------------------------------------------------------------
gfx16_SetTextFGColor:
; Sets the text foreground color.
; Arguments:
;  arg0: New text foreground color.
; Returns:
;  None
    pop de
    pop hl
    push hl
    push de
    ld (_PutChar.textFGColor), hl
    ret

;-------------------------------------------------------------------------------
gfx16_SetTextBGColor:
; Sets the text background color.
; Arguments:
;  arg0: New text background color.
; Returns:
;  None
    pop de
    pop hl
    push hl
    push de
    ld (_PutChar.textBGColor), hl
    ret

;-------------------------------------------------------------------------------
gfx16_SetTextTransparentColor:
; Sets the text transparent color.
; Arguments:
;  arg0: New text transparent color.
; Returns:
;  None
    pop de
    pop hl
    push hl
    push de
    ld (_PutChar.textTransparentColor), hl
    ret

;-------------------------------------------------------------------------------
gfx16_SetFontSpacing:
; Sets the font's character spacing.
; Arguments:
;  arg0: Pointer to array of character spacing.
; Returns:
;  Pointer to previous font spacing.
    pop hl
    pop de
    push de
    push hl
    ld hl, (_CharSpacing)
    ld (_CharSpacing), de
    ret

;-------------------------------------------------------------------------------
gfx16_SetFontData:
; Sets the font's character data.
; Arguments:
;  arg0: Pointer to formatted 8x8 pixel font.
; Returns:
;  Pointer to previous font data.
    pop hl
    pop de
    push de
    push hl
    ld hl, (_TextData)
    ld (_TextData), de
    ret

;-------------------------------------------------------------------------------
gfx16_SetCharWidth:
; Sets the width of an individual character in the font.
; Arguments:
;  arg0: Character index to modify.
;  arg1: New width value.
; Returns:
;  None
    pop de
    pop bc
    ex (sp), hl
    push bc
    push de
    ld a, l
    ld de, 0
    ld e, c
    ld hl, (_CharSpacing)
    add hl, de
    ld (hl), a
    ret

;-------------------------------------------------------------------------------
gfx16_SetCharData:
; Sets the data of an individual character in the font.
; Arguments:
;  arg0: Character index to modify.
;  arg1: Pointer to formatted 8x8 pixel font.
; Returns:
;  None
    pop de
    pop bc
    ex (sp), hl
    push bc
    push de
    push hl
    ld d, 8
    ld e, c
    mlt de
    ld hl, (_TextData)
    add hl, de
    ex de, hl
    pop hl
    ld bc, 8
    ldir
    ret

;-------------------------------------------------------------------------------
; Inner library routines
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
_getVramAddr: ; returns address in hl
; routine by calc84maniac
    ld hl, ti.vRam
    ld de, (iy + 3)
    ; set a = ((x & $100) * lcdHeight) >> 8
    ld a, d
    ld d, ti.lcdHeight
    rra
    sbc a, a
    and a, d
    mlt de
    add hl, de
    add hl, de
    ; add ((x & $100) * lcdHeight + y) * 2
    ld d, a
    ld e, (iy + 6)
    add hl, de
    add hl, de
    ret

;-------------------------------------------------------------------------------
_Maximum:
; Calculate the result of a signed comparison
; Inputs:
;  DE, HL = numbers
; Oututs:
;  HL = max number
    or a, a
    sbc hl, de
    add hl, de
    jp p, .skip
    ret pe
    ex de, hl

.skip:
    ret po
    ex de, hl
    ret

;-------------------------------------------------------------------------------
_Minimum:
; Calculate the result of a signed comparison
; Inputs:
;  DE, HL = numbers
; Oututs:
;  HL = min number
    or a, a
    sbc hl, de
    ex de, hl
    jp p, .skip
    ret pe
    add hl, de

.skip:
    ret po
    add hl, de
    ret

;-------------------------------------------------------------------------------
_ClipRegion:
; Calculates the new coordinates given the clip and inputs
; Inputs:
;  None
; Outputs:
;  Modifies data registers
;  Sets C flag if offscreen
    ld hl, (_XMin)
    ld de, (iy + 3)
    call _Maximum
    ld (iy + 3), hl
    ld hl, (_XMax)
    ld de, (iy + 9)
    call _Minimum
    ld (iy + 9), hl
    ld de, (iy + 3)
    call .compare
    ret c
    ld hl, (_YMin)
    ld de, (iy + 6)
    call _Maximum
    ld (iy + 6), hl
    ld hl, (_YMax)
    ld de, (iy + 12)
    call _Minimum
    ld (iy + 12), hl
    ld de, (iy + 6)

.compare:
    dec hl

_SignedCompare:
    or a, a
    sbc hl, de
    add hl, hl
    ret po
    ccf
    ret

;-------------------------------------------------------------------------------
_ClipCoordinates:
; Clipping stuff
; Arguments:
;  arg0 : Pointer to sprite structure
;  arg1 : X coordinate
;  arg2 : Y coordinate
; Returns:
;  A    : How much to add to the sprite per iteration
;  arg1 : New Y coordinate
;  arg2 : New X coordinate
;  NC   : If offscreen
    ld ix, 6 ; get pointer to arguments
    lea iy, ix - 6
    add ix, sp
    ld hl, (ix + 3)
    ld a, (hl)
    ld de, _TmpWidth + 3
    ld (de), a ; save _TmpHeight
    ld (.height1), a ; save tmpSpriteHeight
    ld (.height2), a ; save again in a different spot
    add iy, de
    lea iy, iy - 3
    inc hl
    ld a, (hl)
    ld (iy + 0), a ; save tmpWidth
    inc hl
    ld (iy + 6), hl ; save a ptr to the sprite data to change offsets
    ld bc, (ix + 9)
    ld hl, (_YMin)
    isHLLessThanBC
    jr c, .notop
    ld hl, (iy + 3) ; hl = tmpHeight
    add hl, bc
    ex de, hl
    ld hl, (_YMin)
    isHLLessThanDE
    ret nc ; bc = y location
    ld hl, (_YMin) ; ymin
    or a, a
    sbc hl, bc
    ld a, (iy + 3)
    sub a, l
    ld (iy + 3), a
    ex de, hl
    ld hl, (iy + 6)
    add hl, de
    add hl, de ; Add twice for 16bpp
    ld (iy + 6), hl ; store new ptr
    ld bc, (_YMin) ; new y location ymin

.notop:
    push bc
    pop hl ; hl = y coordinate
    ld de, (_YMax)
    isHLLessThanDE
    ret nc ; return if offscreen on bottom
    ld hl, (iy + 3) ; bc = y coordinate, hl = tmpHeight
    add hl, bc
    ld de, (_YMax)
    isHLLessThanDE
    jr c, .notbottom ; is partially clipped bottom?
    ex de, hl ; bc = y coordinate, hl = ymax
    sbc hl, bc
    ld (iy + 3), hl ; store new tmpHeight

.notbottom:
    ld hl, (ix + 6) ; hl = x coordinate
    ld de, (_XMin)
    isHLLessThanDE
    ld hl, (ix + 6) ; hl = x coordinate
    jr nc, .noleft ; is partially clipped left?
    ld de, (iy + 0) ; de = _TmpWidth
    add hl, de
    ld de, (_XMin)
    ex de, hl
    isHLLessThanDE
    ret nc ; return if offscreen
    ld de, (ix + 6) ; de = x coordinate
    ld hl, (_XMin)
    or a, a
    sbc hl, de
    ex de, hl ; calculate new offset
    ld hl, (iy + 0) ; hl = _TmpWidth
    or a, a
    sbc hl, de
    ld (iy + 0), hl ; save new width
    ld d, 0

.height1 := $ - 1
    mlt de
    ld hl, (iy + 6) ; hl = sprite ptr
    add hl, de
    add hl, de
    ld (iy + 6), hl
    ld hl, (_XMin)
    ld (ix + 6), hl ; save min x coordinate

.noleft:
    ld de, (_XMax) ; de = xmax
    isHLLessThanDE
    ret nc ; return if offscreen
    ld hl, (ix + 6) ; hl = x coordinate
    ld de, (iy + 0) ; de = _TmpWidth
    add hl, de
    ld de, (_XMax)
    ex de, hl
    isHLLessThanDE
    jr nc, .noright ; is partially clipped right?
    ld hl, (_XMax) ; clip on the right
    ld de, (ix + 6)
    ccf
    sbc hl, de
    ld (iy + 0), hl ; save new _TmpWidth

.noright:
    ld a, (iy + 3)
    or a, a
    ret z ; quit if new tmpHeight is 0 (edge case)
    ld a, 0

.height2 := $ - 1
    ld (ix + 9), bc
    sub a, (iy + 3) ; compute new x width
    scf ; set carry for success
    ret

;-------------------------------------------------------------------------------
; Internal library data
;-------------------------------------------------------------------------------

_GlobalColor:
    dl 0
_TextFGColor:
    dl 0
_TextBGColor:
    dl 0
_TransColor:
    dl 0

_XMin:
    dl 0
_YMin:
    dl 0
_XMax:
    dl ti.lcdWidth
_YMax:
    dl ti.lcdHeight

_TmpWidth:
    dl 0

_TmpHeight:
    dl 0

_TmpSprite:
    dl 0

_ClipRegion_Full: ; x, y, w, h
    dl 0
    dl 0
    dl ti.lcdWidth
    dl ti.lcdHeight

_LcdTiming:
;   db 14 shl 2 ; PPL shl 2
    db 7 ; HSW
    db 87 ; HFP
    db 63 ; HBP
    dw (0 shl 10) + 319 ; (VSW shl 10) + LPP
    db 179 ; VFP
    db 0 ; VBP
    db (0 shl 6) + (0 shl 5) + 0 ; (ACB shl 6) + (CLKSEL shl 5) + PCD_LO
; H = ((PPL + 1) * 16) + (HSW + 1) + (HFP + 1) + (HBP + 1) = 240 + 8 + 88 + 64 = 400
; V = (LPP + 1) + (VSW + 1) + VFP + VBP = 320 + 1 + 179 + 0 = 500
; CC = H * V * PCD * 2 = 400 * 500 * 2 * 2 = 800000
; Hz = 48000000 / CC = 60

_CharSpacing:
    dl _DefaultCharSpacing
_TextData:
    dl _DefaultTextData

_DefaultCharSpacing:
    ;  0, 1, 2, 3, 4, 5, 6, 7, 8, 9, A, B, C, D, E, F
    db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 ; 0
    db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 ; 1
    db 3, 4, 6, 8, 8, 8, 8, 5, 5, 5, 8, 7, 4, 7, 3, 8 ; 2
    db 8, 7, 8, 8, 8, 8, 8, 8, 8, 8, 3, 4, 6, 7, 6, 7 ; 3
    db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 ; 4
    db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 5, 8, 5, 8, 8 ; 5
    db 4, 8, 8, 8, 8, 8, 8, 8, 8, 5, 8, 8, 5, 8, 8, 8 ; 6
    db 8, 8, 8, 8, 7, 8, 8, 8, 8, 8, 8, 7, 3, 7, 8, 8 ; 7
    db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 ; 8
    db 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8 ; 9

_DefaultTextData:
    db $00, $00, $00, $00, $00, $00, $00, $00 ;  
    db $7E, $81, $AD, $8D, $8D, $AD, $81, $7E ; ☺
    db $7E, $FF, $D3, $F3, $F3, $D3, $FF, $7E ; ☻
    db $70, $F8, $FC, $7E, $FC, $F8, $70, $00 ; ♥
    db $10, $38, $7C, $FE, $7C, $38, $10, $00 ; ♦
    db $18, $59, $F9, $FF, $F9, $59, $18, $00 ; ♣
    db $08, $1D, $3D, $7F, $7F, $3D, $1D, $08 ; ♠
    db $00, $00, $18, $3C, $3C, $18, $00, $00 ; •
    db $FF, $FF, $E7, $C3, $C3, $E7, $FF, $FF ; ◘
    db $00, $3C, $66, $42, $42, $66, $3C, $00 ; ○
    db $FF, $C3, $99, $BD, $BD, $99, $C3, $FF ; ◙
    db $0E, $1F, $11, $11, $BF, $FE, $E0, $F0 ; ♂
    db $00, $72, $FA, $8F, $8F, $FA, $72, $00 ; ♀
    db $03, $07, $FF, $FE, $A0, $A0, $E0, $E0 ; ♪
    db $03, $FF, $FE, $A0, $A0, $A6, $FE, $FC ; ♫
    db $99, $5A, $3C, $E7, $E7, $3C, $5A, $99 ; *
    db $FE, $7C, $7C, $38, $38, $10, $10, $00 ; ►
    db $10, $10, $38, $38, $7C, $7C, $FE, $00 ; ◄
    db $00, $24, $66, $FF, $FF, $66, $24, $00 ; ↕
    db $00, $FA, $FA, $00, $00, $FA, $FA, $00 ; ‼
    db $60, $F0, $90, $FE, $FE, $80, $FE, $FE ; ¶
    db $01, $79, $FD, $A5, $A5, $BF, $9E, $80 ; §
    db $00, $0E, $0E, $0E, $0E, $0E, $0E, $00 ; ▬
    db $01, $29, $6D, $FF, $FF, $6D, $29, $01 ; ↨
    db $00, $20, $60, $FE, $FE, $60, $20, $00 ; ↑
    db $00, $08, $0C, $FE, $FE, $0C, $08, $00 ; ↓
    db $10, $10, $10, $54, $7C, $38, $10, $00 ; →
    db $10, $38, $7C, $54, $10, $10, $10, $00 ; ←
    db $3C, $3C, $04, $04, $04, $04, $04, $00 ; └
    db $10, $38, $7C, $10, $10, $7C, $38, $10 ; ↔
    db $0C, $1C, $3C, $7C, $7C, $3C, $1C, $0C ; ▲
    db $60, $70, $78, $7C, $7C, $78, $70, $60 ; ▼
    db $00, $00, $00, $00, $00, $00, $00, $00 ;
    db $FA, $FA, $00, $00, $00, $00, $00, $00 ; !
    db $E0, $E0, $00, $E0, $E0, $00, $00, $00 ; "
    db $28, $FE, $FE, $28, $FE, $FE, $28, $00 ; #
    db $24, $74, $54, $D6, $D6, $5C, $48, $00 ; $
    db $62, $66, $0C, $18, $30, $66, $46, $00 ; %
    db $0C, $5E, $F2, $BA, $EC, $5E, $12, $00 ; &
    db $00, $20, $E0, $C0, $00, $00, $00, $00 ; '
    db $38, $7C, $C6, $82, $00, $00, $00, $00 ; (
    db $82, $C6, $7C, $38, $00, $00, $00, $00 ; )
    db $10, $54, $7C, $38, $38, $7C, $54, $10 ; *
    db $18, $18, $7E, $7E, $18, $18, $00, $00 ; +
    db $01, $07, $06, $00, $00, $00, $00, $00 ; ,
    db $10, $10, $10, $10, $10, $10, $00, $00 ; -
    db $06, $06, $00, $00, $00, $00, $00, $00 ; .
    db $06, $0C, $18, $30, $60, $C0, $80, $00 ; /
    db $7C, $FE, $9A, $B2, $E2, $FE, $7C, $00 ; 0
    db $02, $42, $FE, $FE, $02, $02, $00, $00 ; 1
    db $4E, $DE, $92, $92, $92, $F2, $62, $00 ; 2
    db $82, $82, $92, $92, $92, $FE, $6C, $00 ; 3
    db $78, $78, $08, $08, $FE, $FE, $08, $00 ; 4
    db $E4, $E6, $A2, $A2, $A2, $BE, $9C, $00 ; 5
    db $7C, $FE, $92, $92, $92, $9E, $0C, $00 ; 6
    db $80, $80, $86, $8E, $98, $F0, $E0, $00 ; 7
    db $6C, $FE, $92, $92, $92, $FE, $6C, $00 ; 8
    db $60, $F2, $92, $92, $92, $FE, $7C, $00 ; 9
    db $66, $66, $00, $00, $00, $00, $00, $00 ; :
    db $01, $67, $66, $00, $00, $00, $00, $00 ; ;
    db $10, $38, $6C, $C6, $82, $00, $00, $00 ; <
    db $28, $28, $28, $28, $28, $28, $00, $00 ; =
    db $82, $C6, $6C, $38, $10, $00, $00, $00 ; >
    db $40, $C0, $9A, $BA, $E0, $40, $00, $00 ; ?
    db $7C, $FE, $82, $BA, $BA, $FA, $7A, $00 ; @
    db $3E, $7E, $C8, $88, $C8, $7E, $3E, $00 ; A
    db $FE, $FE, $92, $92, $92, $FE, $6C, $00 ; B
    db $7C, $FE, $82, $82, $82, $C6, $44, $00 ; C
    db $FE, $FE, $82, $82, $C6, $7C, $38, $00 ; D
    db $FE, $FE, $92, $92, $92, $82, $82, $00 ; E
    db $FE, $FE, $90, $90, $90, $80, $80, $00 ; F
    db $7C, $FE, $82, $82, $8A, $CE, $4C, $00 ; G
    db $FE, $FE, $10, $10, $10, $FE, $FE, $00 ; H
    db $00, $82, $82, $FE, $FE, $82, $82, $00 ; I
    db $04, $06, $02, $02, $02, $FE, $FC, $00 ; J
    db $FE, $FE, $10, $38, $6C, $C6, $82, $00 ; K
    db $FE, $FE, $02, $02, $02, $02, $02, $00 ; L
    db $FE, $FE, $70, $38, $70, $FE, $FE, $00 ; M
    db $FE, $FE, $60, $30, $18, $FE, $FE, $00 ; N
    db $7C, $FE, $82, $82, $82, $FE, $7C, $00 ; O
    db $FE, $FE, $90, $90, $90, $F0, $60, $00 ; P
    db $7C, $FE, $82, $8E, $86, $FF, $7D, $00 ; Q
    db $FE, $FE, $90, $98, $9C, $F6, $62, $00 ; R
    db $64, $F6, $92, $92, $92, $DE, $4C, $00 ; S
    db $80, $80, $80, $FE, $FE, $80, $80, $80 ; T
    db $FE, $FE, $02, $02, $02, $FE, $FE, $00 ; U
    db $F8, $FC, $06, $06, $06, $FC, $F8, $00 ; V
    db $FC, $FE, $06, $0C, $06, $FE, $FC, $00 ; W
    db $C6, $EE, $38, $10, $38, $EE, $C6, $00 ; X
    db $E2, $F2, $16, $1C, $18, $F0, $E0, $00 ; Y
    db $82, $86, $8E, $9A, $B2, $E2, $C2, $00 ; Z
    db $FE, $FE, $82, $82, $00, $00, $00, $00 ; [
    db $80, $C0, $60, $30, $18, $0C, $06, $00 ; \
    db $82, $82, $FE, $FE, $00, $00, $00, $00 ; ]
    db $10, $30, $60, $C0, $60, $30, $10, $00 ; ^
    db $01, $01, $01, $01, $01, $01, $01, $01 ; _
    db $C0, $E0, $20, $00, $00, $00, $00, $00 ; `
    db $04, $2E, $2A, $2A, $2A, $3E, $1E, $00 ; a
    db $FE, $FE, $12, $12, $12, $1E, $0C, $00 ; b
    db $1C, $3E, $22, $22, $22, $36, $14, $00 ; c
    db $0C, $1E, $12, $12, $12, $FE, $FE, $00 ; d
    db $1C, $3E, $2A, $2A, $2A, $3A, $18, $00 ; e
    db $00, $12, $7E, $FE, $92, $C0, $40, $00 ; f
    db $19, $3D, $25, $25, $25, $3F, $3E, $00 ; g
    db $FE, $FE, $20, $20, $20, $3E, $1E, $00 ; h
    db $22, $BE, $BE, $02, $00, $00, $00, $00 ; i
    db $02, $03, $01, $01, $01, $BF, $BE, $00 ; j
    db $FE, $FE, $08, $18, $3C, $26, $02, $00 ; k
    db $82, $FE, $FE, $02, $00, $00, $00, $00 ; l
    db $3E, $3E, $18, $1E, $38, $3E, $1E, $00 ; m
    db $3E, $3E, $20, $20, $20, $3E, $1E, $00 ; n
    db $1C, $3E, $22, $22, $22, $3E, $1C, $00 ; o
    db $3F, $3F, $24, $24, $24, $3C, $18, $00 ; p
    db $18, $3C, $24, $24, $24, $3F, $3F, $00 ; q
    db $3E, $3E, $20, $20, $20, $30, $10, $00 ; r
    db $12, $3A, $2A, $2A, $2A, $2E, $24, $00 ; s
    db $20, $20, $FC, $FE, $22, $22, $00, $00 ; t
    db $3C, $3E, $02, $02, $02, $3E, $3E, $00 ; u
    db $38, $3C, $06, $06, $06, $3C, $38, $00 ; v
    db $3C, $3E, $06, $0C, $06, $3E, $3C, $00 ; w
    db $22, $36, $1C, $08, $1C, $36, $22, $00 ; x
    db $39, $3D, $05, $05, $05, $3F, $3E, $00 ; y
    db $22, $26, $2E, $2A, $3A, $32, $22, $00 ; z
    db $10, $10, $7C, $EE, $82, $82, $00, $00 ; {
    db $EE, $EE, $00, $00, $00, $00, $00, $00 ; |
    db $82, $82, $EE, $7C, $10, $10, $00, $00 ; }
    db $40, $C0, $80, $C0, $40, $C0, $80, $00 ; ~
    db $0E, $1E, $32, $62, $32, $1E, $0E, $00 ; △
