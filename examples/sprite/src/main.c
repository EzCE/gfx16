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

    /* Draw an unclipped sprite */
    gfx16_Sprite_NoClip(oiram, 0, 0);

    /* Waits for a key */
    while (!os_GetCSC());

    /* Close the gfx16 library */
    gfx16_End();

    return 0;
}
