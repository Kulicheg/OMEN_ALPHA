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