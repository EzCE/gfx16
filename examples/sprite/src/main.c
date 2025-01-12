#include <ti/getcsc.h>
#include <gfx16.h>

/* Include the converted graphics file */
#include "gfx/gfx.h"

int main(void)
{
    /* Initialize graphics drawing */
    gfx16_Begin();

    /* Clear screen and fill with white */
    gfx16_ClearVRAM();

    /* Draw a clipped sprite near the bottom of the screen */
    gfx16_Sprite(oiram, 130, 225);

    /* Draw an unclipped sprite */
    gfx16_Sprite_NoClip(oiram, 190, 110);

    /* Waits for a key */
    while (!os_GetCSC());

    /* Close the gfx16 library */
    gfx16_End();

    return 0;
}
