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

    /* Draw a filled circle */
    gfx16_FillCircle(60, 60, 25);

    /* You can also use pre-defined OS colors like this */
    gfx16_SetColor(GFX16_OS_GREEN);

    /* Draw a circle outline */
    gfx16_Circle(200, 125, 75);

    /* Waits for a key */
    while (!os_GetCSC());

    /* Close the gfx16 library */
    gfx16_End();

    return 0;
}
