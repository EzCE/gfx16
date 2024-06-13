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

/**
 * @brief Sets up the display for gfx16. It is necessary to call this function before using the library.
 * 
 */
void gfx16_Begin(void);

/**
 * @brief Resets the display to the OS default. It is necessary to call this when you are done using the library, like at the end of your progra.
 * 
 */
void gfx16_End(void);

/**
 * @brief Marks the beginning of a logical frame.
 * 
 */
void gfx16_BeginFrame(void);

/**
 * @brief Marks the end of a logical frame. It's important to call this after you've called gfx16_BeginFrame.
 * 
 */
void gfx16_EndFrame(void);

/**
 * @brief Sets the color that the library's drawing functions will use.
 * 
 * @param color 16 bit color to set.
 * @return uint16_t Color that was set previously.
 */
uint16_t gfx16_SetColor(uint16_t color);

/**
 * @brief Sets the color that the library's transparent drawing functions will use.
 * 
 * @param color 16 bit color to set.
 * @return uint16_t Color that was set previously.
 */
uint16_t gfx16_SetTransparentColor(uint16_t color);

/**
 * @brief Sets the dimensions of the drawing window for all clipped routines.
 * 
 * @param xmin Minimum X coordinate, inclusive.
 * @param ymin Minimum Y coordinate, inclusive.
 * @param xmax Maximum X coordinate, exclusive.
 * @param ymax Maximum X coordinate, exclusive.
 */
void gfx16_SetClipRegion(int xmin, int ymin, int xmax, int ymax);

/**
 * @brief Sets a pixel to the currently set drawing color.
 * 
 * @param x X coordinate of the pixel.
 * @param y Y coordinate of the pixel.
 */
void gfx16_SetPixel(uint24_t x, uint8_t y);

/**
 * @brief Gets the current color of a pixel.
 * 
 * @param x X coordinate of the pixel.
 * @param y Y coordinate of the pixel.
 * @return uint16_t Color of the pixel.
 */
uint16_t gfx16_GetPixel(uint24_t x, uint8_t y);

/**
 * @brief Inverts the color of a pixel.
 * 
 * @param x X coordinate of the pixel.
 * @param y Y coordinate of the pixel.
 */
void gfx16_InvertPixel(uint24_t x, uint8_t y);

/**
 * @brief Fills the screen with the specified color.
 * 
 * @param color 16 bit color to fill the screen with.
 */
void gfx16_FillScreen(uint16_t color);

/**
 * @brief Clears the screen and fills it with white.
 * 
 */
void gfx16_ClearVRAM(void);

/**
 * @brief Draws an unclipped filled rectangle.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_FillRectangle_NoClip(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

/**
 * @brief Draws a clipped filled rectangle.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_FillRectangle(int x, int y, int width, int height);

/**
 * @brief Draws an unclipped filled rectangle which inverts the colors it overlaps with rather than drawing with a specified color.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_FillInvertedRectangle_NoClip(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

/**
 * @brief Draws a clipped filled rectangle which inverts the colors it overlaps with rather than drawing with a specified color.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_FillInvertedRectangle(int x, int y, int width, int height);

/**
 * @brief Draws a clipped vertical line.
 * 
 * @param x X coordinate of the line.
 * @param y Y coordinate of the line.
 * @param length Length of the line.
 */
void gfx16_VertLine(int x, int y, int length);

/**
 * @brief Draws an unclipped vertical line.
 * 
 * @param x X coordinate of the line.
 * @param y Y coordinate of the line.
 * @param length Length of the line.
 */
void gfx16_VertLine_NoClip(uint24_t x, uint8_t y, uint24_t length);

/**
 * @brief Draws a clipped horizontal line.
 * 
 * @param x X coordinate of the line.
 * @param y Y coordinate of the line.
 * @param length Length of the line.
 */
void gfx16_HorizLine(int x, int y, int length);

/**
 * @brief Draws an unclipped horizontal line.
 * 
 * @param x X coordinate of the line.
 * @param y Y coordinate of the line.
 * @param length Length of the line.
 */
void gfx16_HorizLine_NoClip(uint24_t x, uint8_t y, uint16_t length);

/**
 * @brief Draws an unclipped unfilled rectangle.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_Rectangle_NoClip(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

/**
 * @brief Draws a clipped vertical line which inverts the colors it overlaps with rather than drawing with a specified color.
 * 
 * @param x X coordinate of the line.
 * @param y Y coordinate of the line.
 * @param length Length of the line.
 */
void gfx16_InvertedVertLine(int x, int y, int length);

/**
 * @brief Draws a unclipped vertical line which inverts the colors it overlaps with rather than drawing with a specified color.
 * 
 * @param x X coordinate of the line.
 * @param y Y coordinate of the line.
 * @param length Length of the line.
 */
void gfx16_InvertedVertLine_NoClip(uint24_t x, uint8_t y, uint24_t length);

/**
 * @brief Draws a clipped horizontal line which inverts the colors it overlaps with rather than drawing with a specified color.
 * 
 * @param x X coordinate of the line.
 * @param y Y coordinate of the line.
 * @param length Length of the line.
 */
void gfx16_InvertedHorizLine(int x, int y, int length);

/**
 * @brief Draws an unclipped horizontal line which inverts the colors it overlaps with rather than drawing with a specified color.
 * 
 * @param x X coordinate of the line.
 * @param y Y coordinate of the line.
 * @param length Length of the line.
 */
void gfx16_InvertedHorizLine_NoClip(uint24_t x, uint8_t y, uint16_t length);

/**
 * @brief Draws an unclipped unfilled rectangle which inverts the colors it overlaps with rather than drawing with a specified color.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_InvertedRectangle_NoClip(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

/**
 * @brief Draws a sprite.
 * 
 * @param sprite Pointer to an initialized sprite structure.
 * @param x X coordinate of the sprite.
 * @param y Y coordinate of the sprite.
 */
void gfx16_Sprite(const gfx_sprite_t *sprite, uint24_t x, uint8_t y);

#ifdef __cplusplus
}
#endif

#endif
