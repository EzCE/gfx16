#include <ti/getcsc.h>
#include <gfx16.h>

int main(void)
{
    /* Initialize graphics drawing */
    gfx16_Begin();

    /* Clear screen and fill with white */
    gfx16_ClearVRAM();

    /* Set the color to draw with */
    gfx16_SetColor(0x4859);

    /* Draw a horizontal line */
    gfx16_HorizLine(10, 10, 300);

    /* Draw a horizontal which inverts the colors of what it covers */
    gfx16_InvertedHorizLine(160, 10, 150);

    /* Draw a line from (175, 100) to (250, 50) */
    gfx16_Line(175, 100, 250, 50);

    /* You can also use pre-defined OS colors like this */
    gfx16_SetColor(GFX16_OS_GREEN);

    /* Draw a vertical line */
    gfx16_VertLine(10, 20, 210);

    /* Draw a vertical which inverts the colors of what it covers */
    gfx16_InvertedVertLine(10, 120, 110);

    /* Draw a line from (50, 50) to (200, 175) */
    gfx16_Line(50, 50, 200, 200);

    /* Waits for a key */
    while (!os_GetCSC());

    /* Close the gfx16 library */
    gfx16_End();

    return 0;
}
