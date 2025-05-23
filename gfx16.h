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
 * @brief Inverts the contents of the screen.
 * 
 */
#define gfx16_InvertScreen() \
gfx16_FillInvertedRectangle_NoClip(0, 0, 320, 240)

#define gfx16_RGBTo565(r, g, b) \
((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)

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
 * @brief Draws a clipped filled rectangle.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_FillRectangle(int x, int y, int width, int height);

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
 * @brief Draws a clipped unfilled circle.
 * 
 * @param x X coordinate of the center.
 * @param y Y coordinate of the center.
 * @param radius Radius of the circle.
 */
void gfx16_Circle(int x, int y, uint8_t radius);

/**
 * @brief Draws an unclipped unfilled circle.
 * 
 * @param x X coordinate of the center.
 * @param y Y coordinate of the center.
 * @param radius Radius of the circle.
 */
void gfx16_Circle_NoClip(int x, uint8_t y, uint8_t radius);

/**
 * @brief Draws a clipped filled circle.
 * 
 * @param x X coordinate of the center.
 * @param y Y coordinate of the center.
 * @param radius Radius of the circle.
 */
void gfx16_FillCircle(int x, int y, uint8_t radius);

/**
 * @brief Draws an unclipped filled circle.
 * 
 * @param x X coordinate of the center.
 * @param y Y coordinate of the center.
 * @param radius Radius of the circle.
 */
void gfx16_FillCircle_NoClip(int x, uint8_t y, uint8_t radius);

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
 * @brief Draws a clipped line.
 * 
 * @param x0 First x coordinate.
 * @param y0 First y coordinate.
 * @param x1 Second x coordinate.
 * @param y1 Second y coordinate.
 */
void gfx16_Line(int x0, int y0, int x1, int y1);

/**
 * @brief Draws an unclipped line.
 * 
 * @param x0 First x coordinate.
 * @param y0 First y coordinate.
 * @param x1 Second x coordinate.
 * @param y1 Second y coordinate.
 */
void gfx16_Line_NoClip(uint24_t x0, uint8_t y0, uint24_t x1, uint8_t y1);

/**
 * @brief Draws a clipped unfilled rectangle.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_Rectangle(int x, int y, int width, int height);

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
 * @brief Draws a clipped unfilled rectangle which inverts the colors it overlaps with rather than drawing with a specified color.
 * 
 * @param x X coordinate of the rectangle.
 * @param y Y coordinate of the rectangle.
 * @param width Width of the rectangle.
 * @param height Height of the rectangle.
 */
void gfx16_InvertedRectangle(uint24_t x, uint8_t y, uint16_t width, uint8_t height);

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
 * @brief Draws a clipped sprite.
 * 
 * @param sprite Pointer to an initialized sprite structure.
 * @param x X coordinate of the sprite.
 * @param y Y coordinate of the sprite.
 */
void gfx16_Sprite(const gfx_sprite_t *sprite, int x, int y);

/**
 * @brief Draws a clipped transparent sprite.
 * 
 * @param sprite Pointer to an initialized sprite structure.
 * @param x X coordinate of the sprite.
 * @param y Y coordinate of the sprite.
 */
void gfx16_TransparentSprite(const gfx_sprite_t *sprite, int x, int y);

/**
 * @brief Draws an unclipped sprite.
 * 
 * @param sprite Pointer to an initialized sprite structure.
 * @param x X coordinate of the sprite.
 * @param y Y coordinate of the sprite.
 */
void gfx16_Sprite_NoClip(const gfx_sprite_t *sprite, uint24_t x, uint8_t y);

/**
 * @brief Draws an unclipped transparent sprite.
 * 
 * @param sprite Pointer to an initialized sprite structure.
 * @param x X coordinate of the sprite.
 * @param y Y coordinate of the sprite.
 */
void gfx16_TransparentSprite_NoClip(const gfx_sprite_t *sprite, uint24_t x, uint8_t y);

/**
 * @brief Draws a scaled unclipped sprite.
 * 
 * @param sprite Pointer to an initialized sprite structure.
 * @param x X coordinate of the sprite.
 * @param y Y coordinate of the sprite.
 * @param width_scale Width scaling factor.
 * @param height_scale Height scaling factor.
 */
void gfx16_ScaledSprite_NoClip(const gfx_sprite_t *sprite, uint24_t x, uint8_t y, uint8_t width_scale, uint8_t height_scale);

/**
 * @brief Draws a scaled unclipped transparent sprite.
 * 
 * @param sprite Pointer to an initialized sprite structure.
 * @param x X coordinate of the sprite.
 * @param y Y coordinate of the sprite.
 * @param width_scale Width scaling factor.
 * @param height_scale Height scaling factor.
 */
void gfx16_ScaledTransparentSprite_NoClip(const gfx_sprite_t *sprite, uint24_t x, uint8_t y, uint8_t width_scale, uint8_t height_scale);

/**
 * @brief Draws a single character at the current cursor position.
 * 
 * @param c Character to draw.
 */
void gfx16_PutChar(const char c);

/**
 * @brief Draws a string at the current cursor position.
 * 
 * @param string Pointer to the null-terminated string to draw.
 */
void gfx16_PutString(const char *string);

/**
 * @brief Draws a string at a specified cursor position.
 * 
 * @param string Pointer to the null-terminated string to draw.
 * @param x Top-left cursor X coordinate.
 * @param y Top-left cursor Y coordinate.
 */
void gfx16_PutStringXY(const char *string, uint24_t x, uint8_t y);

/**
 * @brief Sets the text cursor position.
 * 
 * @param x Top-left cursor X coordinate.
 * @param y Top-left cursor Y coordinate.
 */
void gfx16_SetTextXY(uint24_t x, uint8_t y);

/**
 * @brief Sets the text scaling factors.
 * 
 * @param width New text width scale factor.
 * @param height New text height scale factor.
 */
void gfx16_SetTextScale(uint8_t width, uint8_t height);

/**
 * @brief Sets the text foreground color.
 * 
 * @param color New text foreground color.
 */
void gfx16_SetTextFGColor(uint16_t color);

/**
 * @brief Sets the text background color.
 * 
 * @param color New text background color.
 */
void gfx16_SetTextBGColor(uint16_t color);

/**
 * @brief Sets the text transparent color.
 * 
 * @param color New text transparent color.
 */
void gfx16_SetTextTransparentColor(uint16_t color);

/**
 * @brief Sets the font's character spacing.
 * 
 * @param spacing Pointer to array of character spacing.
 * @return uint8_t* Pointer to previous font spacing.
 */
uint8_t *gfx16_SetFontSpacing(const uint8_t *spacing);

/**
 * @brief Sets the font's character data.
 * 
 * @param data Pointer to formatted 8x8 pixel font.
 * @return uint8_t* Pointer to previous font data.
 */
uint8_t *gfx16_SetFontData(const uint8_t *data);

/**
 * @brief Sets the width of an individual character in the font.
 * 
 * @param index Character index to modify.
 * @param width New width value.
 */
void gfx16_SetCharWidth(char index, uint8_t width);

/**
 * @brief Sets the data of an individual character in the font.
 * 
 * @param index Character index to modify.
 * @param data Pointer to formatted 8x8 pixel font.
 */
void gfx16_SetCharData(char index, const uint8_t *data);

#ifdef __cplusplus
}
#endif

#endif
