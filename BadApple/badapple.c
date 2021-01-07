#include "stdio.h"
FILE *fp1;

AT(X, Y)
{
    putchar(27);
    putchar('[');
    putdec(Y);
    putchar(';');
    putdec(X);
    putchar('H');
}

CLS()
{
    putchar(27);
    putchar('[');
    putchar('2');
    putchar('J');
}

ATRIB(color)
{
    putchar(27);
    putchar('[');
    putdec(color);
    putchar('m');
}

HOME()
{
    putchar(27);
    putchar('[');
    putchar('H');
}

render()
{
    HOME();
    int rbyte1;
    int lng;
    int cntr;
    char color;
    int col;
    rbyte1 = 255;
    col = 0;
    while (rbyte1 != 0)
    {
        rbyte1 = fgetc(fp1);

        if (rbyte1 > 128)
        {
            lng = rbyte1 - 128;
            color = '*';
        }
        else
        {
            lng = rbyte1;
            color = '.';
        }

        for (cntr = 0; cntr < lng; cntr++)
        {
        bios(4, color);
        bios(4, color);

        /*  putchar(color);
            putchar(color);
        */    
            col++;
            if (col > 31)
            {
                printf("\n");
                col = 0;
            }
        }
    }
    rbyte1 = fgetc(fp1);
    if (rbyte1 == 0)
    {
        exit();
    }
    ungetc(rbyte1, fp1);
}

main(argc, argv) int argc;
char **argv;
{
    if ((fp1 = fopen(argv[1], "rb")) == NULL)
    {
        printf("Can't open %s\n", argv[1]);
        printf("\n");
        exit();
    }
    CLS();

    while (1)
    {
        render();
    }
}
