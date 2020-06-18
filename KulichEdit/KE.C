
#include "stdio.h"
#define CTRL_C 0x03 /* control-C */
#define CPMEOF 0x1a /* End of File signal (control-Z) */
char **fname;
FILE *fp1;
int cchar;
char document[32002];
unsigned curpos;
int cursorX;
int cursorY;

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

DRAWBAR(mode)
{

  AT(1, 1);
  ATRIB(7);
  printf("Kulich Edit: ");

  int fnlen;
  fnlen = 15 - strlen(fname);
  printf(fname);
  int q;
  for (q = 0; q < fnlen; q++)
  {
    putchar(' ');
  }

  printf("Col:%2d", cursorX);
  printf("  Lin:%2d", cursorY);
  printf("                                      ");
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
  if (cursorY > 24)
  {
    cursorY = 24;
  }
  AT(cursorX, cursorY);
}

sysexit()
{
  document[curpos] = '\0';
  printf("\n");

  int q;
  char w;
  printf("Saving...\n");
  fputs(document, fp1);
  fclose(fp1);

exit2:
  printf("\nDone.\n");
  exit();
}

getchar1()
{
  char c;
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

  if (c == '\r')
  {
    document[curpos] = '\r';
    curpos++;
    document[curpos] = '\n';
    curpos++;

    cursorX = 1;
    cursorY++;
  }

  return c;
}

main(argc, argv) int argc;
char **argv;
{
  CLS();
  AT(1, 1);

  if (argc < 2)
  {
    printf("No filename given.\n");

    exit();
  }
  fname = argv[1];
  cursorX = 1;
  cursorY = 2;

  DRAWBAR(0);

  if ((fp1 = fopen(argv[1], "w")) == NULL)
  {
    printf("Can't open %s\n", argv[1]);
    printf("\n");
    exit();
  }
  initb(document, '\0');
  AT(1, 2);

  while (1)
  {
    /*  DRAWBAR(1);*/
    if (curpos == 32000)
    {
      printf(" Memory full. Exiting\n");
      sysexit();
    }

    cchar = getchar1();

    DRAWCUR();
    if (cchar > 31)
    {
      putchar(cchar);
      document[curpos] = cchar;
      curpos++;
      cursorX++;
    }
  }
}
