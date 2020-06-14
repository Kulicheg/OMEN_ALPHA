#include "stdio.h"
#define CTRL_C 0x03 /* control-C */
#define CPMEOF 0x1a /* End of File signal (control-Z) */
FILE *fp1;
char cchar;
char document [2500];
unsigned curpos;

AT(X,Y)
{
putchar(27);
putchar('[');
putchar(Y+48);
putchar(';');
putchar(X+48);
putchar('H');
}

CLS()
{
putchar(27);
putchar('[');
putchar('2');
putchar('J');
}



sysexit()
{
document[curpos + 1] = '\0';
printf ("\n");

int q;
char w;
printf ("Saving...\n");
fputs(document, fp1);
printf ("Flushing...\n");
fflush(fp1);
fclose(fp1);	

exit2:

printf ("\nDone.\n");

exit(); 			/* then reboot */	
	
}


getchar() 			/* get a character, hairy version */
{
char c;
if ((c = bios(3)) == CTRL_C) sysexit();

if (c == CPMEOF)
{
	fclose(fp1);
	exit();
}
if (c == '\r') 
{ 					/* if CR typed, then */
document[curpos] = '\r';
curpos++;

putchar('\r'); 		/* echo a CR, and set */
c = '\n'; 			/* up to echo a LF also */
} 					/* and return a '\n'*/
putchar(c); 		/* echo the char */

return c; 			/* and return it */
}


putchar(c) 			/* output a character, hairy version */
char c;
{
bios(4,c); 			/* first output the given char */
if (c == '\n') 		/* if it is a newline, */
{
bios(4,'\r'); 		/* then output a CR also */
}
if (kbhit() && bios(3) == CTRL_C) /* if Ctl-C typed, */
{
sysexit();
}
} 					/* else ignore the input */


main (argc, argv) 
int argc; 
char **argv;
{
CLS();
AT (1,1);


int i;
for (i = 1; i < argc; i++)
{
printf("Arg[");
printf("%u",i);
printf("]=");
printf(argv[i]);
printf("\n");
}

if (argc < 2)
{
printf("No filename given.\n");

exit();
}

if ((fp1 = fopen(argv[1],"w")) == NULL) 
{
printf("Can’t open %s\n",argv[1]);
printf("\n");
exit();
}
initb(document,'\0');
printf("Ready to PASTE!\n");
while (1)
{
	if (curpos == 24998)
		{
		printf(" Memory full. Exiting\n");
		sysexit();
		}
		
	cchar  = getchar();
	document[curpos] = cchar;
	curpos++;
	
		
		
		
	
}

}


