AT(X, Y)
{
 printf("%c[%d;%dH", 27, Y, X);
}

CLS()
{
 printf("%c[2J", 27);
 AT(1,1);
}

ATRIB(color)
{
  putchar(27);
  putchar('[');
  putdec(color);
  putchar('m');
}

INVERSE() 
{
 printf("%c[47m%c[30m", 27, 27);
}

normal() 
{
 printf("%c[44m%c[37m", 27, 27);
}