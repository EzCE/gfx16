/**
 * @file
 *
 * @authors RoccoLox Programs
 *          TIny_Hacker
 */

#ifndef GFX16_H
#define GFX16_H

#include <stdint.h>
#include <graphx.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Direct LCD VRAM access.
 *
 * Total of 153600 bytes in size.
 */
#define gfx16_vram ((uint8_t*)0xD40000)

/**
 * Defines for default OS colors.
*/
#define GFX16_OS_BLUE       (0x001F)
#define GFX16_OS_RED        (0xF800)
#define GFX16_OS_BLACK      (0x0000)
#define GFX16_OS_MAGENTA    (0xF81F)
#define GFX16_OS_GREEN      (0x04E0)
#define GFX16_OS_ORANGE     (0xFC64)
#define GFX16_OS_BROWN      (0xB100)
#define GFX16_OS_NAVY       (0x0010)
#define GFX16_OS_LTBLUE     (0x049F)
#define GFX16_OS_YELLOW     (0xFFE0)
#define GFX16_OS_WHITE      (0xFFFF)
#define GFX16_OS_LTGRAY     (0xE71C)
#define GFX16_OS_MEDGRAY    (0xC618)
#define GFX16_OS_GRAY       (0x8C51)
#define GFX16_OS_DARKGRAY   (0x52AA)

void gfx16_Set16bppMode(void);

uint16_t gfx16_SetColor(uint16_t color);

void gfx16_SetPixel(uint24_t x, uint8_t y);

uint16_t gfx16_GetPixel(uint24_t x, uint8_t y);

void gfx16_InvertPixel(uint24_t x, uint8_t y);

void gfx16_FillScreen(uint16_t color);

void gfx16_ClearVRAM(void);

void gfx16_FillRectangle(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

void gfx16_FillInvertedRectangle(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

void gfx16_VertLine(uint24_t x, uint8_t y, uint8_t length);

void gfx16_HorizLine(uint24_t x, uint8_t y, uint16_t length);

void gfx16_Rectangle(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

void gfx16_InvertedVertLine(uint24_t x, uint8_t y, uint8_t length);

void gfx16_InvertedHorizLine(uint24_t x, uint8_t y, uint16_t length);

void gfx16_InvertedRectangle(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

void gfx16_Sprite(const gfx_sprite_t *sprite, uint24_t x, uint8_t y);

#ifdef __cplusplus
}
#endif

#endif
