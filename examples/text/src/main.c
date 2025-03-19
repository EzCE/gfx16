#include <ti/getcsc.h>
#include <gfx16.h>

int main(void)
{
    /* Initialize graphics drawing */
    gfx16_Begin();

    /* Clear screen and fill with white */
    gfx16_ClearVRAM();

    /* Draw some text to the screen */
    gfx16_PutString("Text");

    /* Draw some text at the coordinates (10, 10) */
    gfx16_PutStringXY("More text", 10, 10);

    /* Draw some blue text */
    gfx16_SetTextFGColor(GFX16_OS_BLUE);
    gfx16_PutStringXY("Colored text", 20, 20);

    /* Draw some text scaled by 2 horizontally and 3 vertically */
    gfx16_SetTextScale(2, 3);
    gfx16_PutStringXY("Scaled text", 30, 30);

    /* Waits for a key */
    while (!os_GetCSC());

    /* Close the gfx16 library */
    gfx16_End();

    return 0;
}
