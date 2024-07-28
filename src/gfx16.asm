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
    export gfx16_InvertedRectangle_NoClip
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

macro isHLLessThanDE?
    or a, a
    sbc hl, de
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
    ld de, ti.lcdHeight * 2
    add hl, de
    pop de
    ex de, hl
    ld c, iyl
    push de
    jr .spriteLoop

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
; Calculate the resut of a signed comparison
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
; Calculate the resut of a signed comparison
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
