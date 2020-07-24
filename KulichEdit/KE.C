#include "stdio.h"
#define CTRL_C 0x03 /* control-C */
#define CPMEOF 0x1a /* End of File signal (control-Z) */
#define WIN_SIZE 42002
char **fname;
FILE *fp1;
int cchar;

char window[WIN_SIZE];
int cursorX;
int cursorY;
int curPage;
unsigned maxPage;
unsigned winpos;
#include "terminal.c"
#include "files.c"

reDRAW(page)
{
    int q;
    AT(1, 2);
    for (q = 0; q < 1920; q++)
    {
        putchar(window[page * 1920 + q]);
    }
}

DRAWBAR(mode)
{

    AT(1, 1);
    ATRIB(7);
    printf("Kulich Edit: ");

    int fnlen;
    fnlen = 13 - strlen(fname);
    printf(fname);
    int q;
    for (q = 0; q < fnlen; q++)
    {
        putchar(' ');
    }

    printf("Col:%2d", cursorX);
    printf(" Lin:%2d", cursorY);
    printf(" Page:%2d", curPage);
    printf(" of %2d", maxPage);
    printf("  %4d", winpos);
    printf("                     ");
    ATRIB(0);
    AT(cursorX, cursorY);
}

DRAWCUR()
{

    if (cursorX < 1)
    {
        cursorX = 1;
    }
    if (cursorX > 80)
    {
        cursorX = 1;
        cursorY++;
    }
    if (cursorY < 1)
    {
        cursorY = 1;
    }
    if (cursorY > 26)
    {
        cursorY = 26;
    }
    AT(cursorX, cursorY);
}

sysexit()
{
    SAVING();

exit2:
    CLS();
    AT(1, 1);
    printf("\nDone.\n");
    exit();
}

getchar1()
{
    char c;
    unsigned q;
    int w;
    if ((c = bios(3)) == CTRL_C)
        sysexit();

    if (c == 23)
    {
        cursorY--;
    }
    if (c == 19)
    {
        cursorY++;
    }

    if (c == 01)
    {
        cursorX--;
    }
    if (c == 04)
    {
        cursorX++;
    }

    if (c == 16) /*P*/
    {

        DRAWBAR();
        AT(1, 2);
    }

    if (c == 21) /*U*/
    {

        DRAWBAR(0);
        AT(cursorX, cursorY);
    }

    if (c == 17) /*Q*/
    {
        curPage--;
        if (curPage < 0)
        {
            curPage = 0;
        }
        DRAWBAR(0);
        reDRAW(curPage);
    }

    if (c == 5) /*E*/
    {
        curPage++;
        if (curPage > maxPage)
        {
            curPage = maxPage;
        }
        DRAWBAR(0);
        reDRAW(curPage);
    }

    if (c == '\r')
    {
        cursorX = 1;
        cursorY++;
    }
    DRAWBAR(0);
    return c;
}

main(argc, argv) int argc;
char **argv;
{

    CLS();
    AT(1, 1);
    putchar('.');

    if (argc < 2)
    {
        printf("No filename given.\n");

        exit();
    }
    fname = argv[1];
    cursorX = 1;
    cursorY = 2;
    maxPage = 21;

    if ((fp1 = fopen(argv[1], "w")) == NULL)
    {
        printf("Can't open %s\n", argv[1]);
        printf("\n");
        exit();
    }

    setmem(&window, WIN_SIZE, 32);

    window[8192] = 0; /* TEST*/
    DRAWBAR(0);
    AT(1, 2);

    while (1)
    {

        cchar = getchar1();
        DRAWCUR();
        if (cchar > 31)
        {
            putchar(cchar);
            cursorX++;
            winpos = (curPage * 1920 + (cursorY - 1) * 80 + cursorX - 2) - 80;
            window[winpos] = cchar;
        }
    }
}
