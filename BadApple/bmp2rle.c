#include <iostream>
#include <stdio.h>

uint8_t frame[96];
bool bitBuffer[768];

FILE* finput;
FILE* foutput;


void rleCompress()
{


	
	int pos = 0;
	int color = bitBuffer[0];
	int colornext = bitBuffer[1];
	int counter = 1;


	while (pos < 767)
	{
		color = bitBuffer[pos];
		colornext = bitBuffer[pos + 1];
		while (color == colornext)
		{
			counter++;
			pos++;
			color = bitBuffer[pos];
			colornext = bitBuffer[pos + 1];
			if (counter == 127)
			{
				break;
			}
		}
		
		if (color)
		{
			counter = counter + 128;
		}
		fputc(counter, foutput);
		counter = 1;
		pos++;
	}	fputc(00, foutput);
	
	fclose(foutput);

}

void fillBuffer()
{
	bool bit;
	for (int q = 0; q < 96; q++)
	{
		int eights = frame[q];
		for (int pos = 7; pos  >= 0; pos--)
		{
			bit = (bool((1 << 7 - pos) & eights));
			bitBuffer[q * 8 + pos] = bit;
		}
	}
}

void renderBuffer()
{
	for (int row = 23; row >= 0; row--)
	{
		for (int col = 0; col < 32; col++)
		{

			if (bitBuffer[(col) + (row * 32)])
			{
				printf("**");
			}
			else { printf(".."); }
		}
		printf("\n");
	}
}

int main(int argc, char* argv[])
{

	finput = fopen(argv[1], "rb");
	//char file_namee[] = "C:\\Users\\egoro\\source\\repos\\BMP2RLE-K\\Debug\\0070.bmp";
	//finput = fopen(file_namee, "rb");
	if (!finput)
	{
		printf("open file %s failed", argv[1]);
		return -1;
	}

	fseek(finput, 0x3E, SEEK_SET);

	fread(&frame, sizeof(frame), 1, finput);
	fclose(finput);

	foutput = fopen(argv[2], "wb");
	//char file_nameo[] = "C:\\Users\\egoro\\source\\repos\\BMP2RLE-K\\Debug\\0070.rle";
	//foutput = fopen(file_nameo, "wb");
	if (!finput)
	{
		printf("open file %s failed", argv[1]);
		return -1;
	}
	printf("Starting...\n");

	fillBuffer();
	renderBuffer();
	rleCompress();
}

