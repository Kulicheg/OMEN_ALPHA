#include "stdio.h"
#define CTRL_C 0x03 /* control-C */
#define CPMEOF 0x1a /* End of File signal (control-Z) */
char **fname;
FILE *fp1;
int cchar;
char document[32002];
char window[2000];
unsigned curpos;
int cursorX;
int cursorY;
int winpos;
int curpage;
#include "terminal.c"

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
  printf("                                         ");
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

mem2file()
{

  int q;
  int q2;
  int positium;
  int chr;
  int stroka;
  AT(1, 2);

  for (stroka = 1; stroka < 25; stroka++)
  {
    positium = stroka * 80;
    chr = window[positium];

    while (chr == 0)
    {
      chr = window[positium];
      positium--;
    }

    for (q = 0; q < positium - ((stroka - 1) * 80); q++)
    {
      int w;
      w = window[(stroka - 1) * 80 + q];
      if (w == 0)
      {
        w = 32;
      }
      document[(stroka - 1) * 80 + q + 2] = w;
      putchar(w);
    }
    if (q < 80)
    {
      document[q + 1] = 13;
      putchar(13);
    }
  }
}

drawmenu()
{
}

update()
{
}

getchar1()
{
  char c;
  int q;
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
    mem2file();
  }

  if (c == 9) /*I*/
  {
    CLS();
    AT(1, 1);
    for (q = 0; q < 1920; q++)
    {
      putchar(window[q]);
    }
    AT(1, 2);
  }

  if (c == 15) /*O*/
  {
    CLS();
    AT(1, 1);
    for (q = 0; q < 1920; q++)
    {
      putchar(document[q]);
    }
    AT(1, 2);
  }
  if (c == 21) /*U*/
  {
    CLS();
    setmem(*document, 32002, 0);
    setmem(*window, 1920, 46);

    DRAWBAR(0);
    AT(1, 2);
    cursorX = 1;
    cursorY = 2;
  }

  if (c == '\r')
  {
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

  if ((fp1 = fopen(argv[1], "w")) == NULL)
  {
    printf("Can't open %s\n", argv[1]);
    printf("\n");
    exit();
  }

  DRAWBAR(0);
  AT(1, 2);

  while (1)
  {
    cchar = getchar1();

    DRAWCUR();
    if (cchar > 31)
    {
      putchar(cchar);
      curpos++;
      cursorX++;
      winpos = (cursorY - 2) * 80 + cursorX - 2;
      window[winpos] = cchar;
    }
  }
}
