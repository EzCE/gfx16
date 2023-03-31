#include <keypadc.h>
#include <gfx16.h>

int main(void)
{
    /* Initialize graphics drawing */
    gfx16_Begin();

    /* Clear screen and fill with white */
    gfx16_ClearVRAM();

    /* Set color to draw with */
    gfx16_SetColor(GFX16_OS_BLUE);

    /* Square coordinates */
    unsigned int x = 0;
    uint8_t y = 0;

    /* Program loop */
    while (!kb_IsDown(kb_KeyClear)) {
        kb_Scan();

        /* Vertical movement */
        if (kb_IsDown(kb_KeyDown) && (y + 5 < 225)) {
            y += 5;
        } else if (kb_IsDown(kb_KeyUp) && (y!= 0)) {
            y -= 5;
        }

        /* Horizontal movement */
        if (kb_IsDown(kb_KeyRight) && (x + 5 < 305)) {
            x += 5;
        } else if (kb_IsDown(kb_KeyLeft) && (x!= 0)) {
            x -= 5;
        }

        /* Begin the frame */
        gfx16_BeginFrame();

        /* Redraw background */
        gfx16_FillScreen(GFX16_OS_WHITE);

        /* Draw rectangle */
        gfx16_FillRectangle(x, y, 20, 20);

        /* End frame and draw it to the screen */
        gfx16_EndFrame();
    }

    /* Close the gfx16 library */
    gfx16_End();

    return 0;
}
