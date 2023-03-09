#include <ti/getcsc.h>
#include <gfx16.h>

int main(void)
{
    /* Initialize graphics drawing */
    gfx16_Set16bppMode();

    /* Clear screen and fill with white */
    gfx16_ClearVRAM();

    /* Set the color to draw with */
    gfx16_SetColor(0x4859);

    /* Draw a filled rectangle */
    gfx16_FillRectangle(20, 20, 85, 130);

    /* Draw a filled rectangle which inverts the colors of what it covers */
    gfx16_FillInvertedRectangle(60, 40, 150, 70);

    /* You can also use pre-defined OS colors like this */
    gfx16_SetColor(GFX16_OS_GREEN);

    /* Draw a rectangle outline */
    gfx16_Rectangle(180, 140, 75, 95);

    /* Draw a rectangle outline which inverts the colors of what it covers */
    gfx16_InvertedRectangle(30, 115, 45, 65);

    /* Waits for a key */
    while (!os_GetCSC());

    return 0;
}
