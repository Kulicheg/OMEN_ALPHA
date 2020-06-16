/*
  ASDF
  ^W 23  17
  ^S 19 13
  ^A 1  01
  ^D 4  04

  BS
  ^H 8  08

  DEL
  ^? 127  7F
*/

#include "stdio.h"
#define CTRL_C 0x03 /* control-C */
#define CPMEOF 0x1a /* End of File signal (control-Z) */
FILE *fp1;
int cchar;
char document[32002];
unsigned curpos;

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
  exit(); /* then reboot */
}

getchar1() /* get a character, hairy version */
{
  char c;
  if ((c = bios(3)) == CTRL_C)
    sysexit();

  if (c == '\r') /* if CR typed, then */

  {
    document[curpos] = '\r';
    curpos++;

    putchar1('\r'); /* echo a CR, and set */
    c = '\n';       /* up to echo a LF also */
  }                 /* and return a '\n'*/

  putchar1(c); /* echo the char */

  return c; /* and return it */
}

putchar1(c) /* output a character, hairy version */
    char c;
{
  bios(4, c);    /* first output the given char */
  if (c == '\n') /* if it is a newline, */
  {
    bios(4, '\r'); /* then output a CR also */
  }
  if (kbhit() && bios(3) == CTRL_C) /* if Ctl-C typed, */
  {
    sysexit();
  }
} /* else ignore the input */

main(argc, argv) int argc;
char **argv;
{
  CLS();
  AT(1, 1);

  int i;
  for (i = 1; i < argc; i++)
  {
    printf("Arg[");
    printf("%u", i);
    printf("]=");
    printf(argv[i]);
    printf("\n");
  }

  if (argc < 2)
  {
    printf("No filename given.\n");
    exit();
  }
 
  if ((fp1 = fopen(argv[1], "w")) == NULL)
  {
    printf("Can't open %s\n", argv[1]);
    printf("\n");
    exit();
  }
  initb(document, '\0');
  ATRIB(7);
  printf("        COPYPASTER 2000 Ready to PASTE! Press CTRL + C for SAVE and EXIT        \n");
  ATRIB(0);
  while (1)
  {
    if (curpos == 32000)
    {
      printf(" Memory full. Exiting\n");
      sysexit();
    }

    cchar = getchar1();
    document[curpos] = cchar;
    curpos++;
  }
}
