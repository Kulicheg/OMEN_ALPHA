#include <SPI.h>
#include <SD.h>

/*
  Пакет содержит 8 бит
  0 Синхро, каждое изменение на 1 это новый пакет на шине
  1 Комманда
  2 Комманда
  3 Комманда
  4 Данные
  5 Данные
  6 Данные
  7 Данные

  Комманды:

  00  000 Чтение  READ    ;36: Read a sector
  01  001 Домой   HOME    ;21: Move disc head to track 0
  02  010 Выбор   SELDSK  ;24: Select disc drive
  03  011 Сектор  SETSEC  ;30: Set sector number
  04  100 Трек    SETTRK  ;27: Set track number
  05  101
  06  110
  07  111 Запись  WRITE   ;39: Write a sector
*/
const int chipSelect = 10;
String diskName = "disk";
String diskLtr = "a";
String diskExt  = ".img";


String curDiskName = diskName + diskLtr + diskExt;

File myFile;

byte databits;

byte command;
byte wrPend, byteCount;
unsigned long startByte;

byte sectorSize = 128;
byte sectors = 128;
byte tracks = 255;

byte curSector = 0;
byte curTrack = 0;
byte curDrive = 0;

byte sector[128];


byte getByte ()
{
  byte portc, portd, L4, H4, result;
  databits = 0;

  DDRC = B00000000;
  DDRD = B00000000;

  while (databits == 0)
  {

    portc = PINC;
    portc = portc & B00111111;              // Двигаем данные с порта на 2 позиции влево там биты 01 - 07
    portc = portc << 2;
    portd = PIND;
    portd = portd & B00011000;              // Двигаем данные с порта на 2 влево чтобы получить все слово
    portd = portd >> 3;
    databits = portc + portd;               // Объединяем данные с обоих порторв
  }

  while (databits != 0)
  {
    delayMicroseconds (20);

    portc = PINC;
    portc = portc & B00111111;              // Двигаем данные с порта на 2 позиции влево там биты 01 - 07
    portc = portc << 2;
    portd = PIND;
    portd = portd & B00011000;              // Двигаем данные с порта на 2 влево чтобы получить все слово
    portd = portd >> 3;
    databits = portc + portd;               // Объединяем данные с обоих порторв

    if (databits != 0)
    {
      L4 = databits & B11110000;
      L4 = L4 >> 4;
      command = databits & B00001110;
      command = command >> 1;
    }

  }


  while (databits == 0)
  {
    // delayMicroseconds (30);

    portc = PINC;
    portc = portc & B00111111;              // Двигаем данные с порта на 2 позиции влево там биты 01 - 07
    portc = portc << 2;
    portd = PIND;
    portd = portd & B00011000;              // Двигаем данные с порта на 2 влево чтобы получить все слово
    portd = portd >> 3;
    databits = portc + portd;               // Объединяем данные с обоих порторв
  }

  while (databits != 0)
  {
    delayMicroseconds (20);

    portc = PINC;
    portc = portc & B00111111;              // Двигаем данные с порта на 2 позиции влево там биты 01 - 07
    portc = portc << 2;
    portd = PIND;
    portd = portd & B00011000;              // Двигаем данные с порта на 2 влево чтобы получить все слово
    portd = portd >> 3;
    databits = portc + portd;               // Объединяем данные с обоих порторв

    if (databits != 0)
    {
      H4 = databits & B11110000;
      H4 = H4 >> 4;

    }

  }
  H4 = H4 << 4;
  result = L4 | H4;

  //Serial.println("HL:\t" + String(H4, HEX) + "&" + String(L4, HEX) + "\t getByte:\t" + String(result, HEX) + "\t" + String(char(result)));

  return  result;
}


//**********************************************************************************************
void putData2(byte dataSend, byte commandSend)
{

  byte highPart, lowPart;

  highPart = dataSend & B11110000;
  lowPart = (dataSend & B00001111) << 4;
  commandSend = commandSend << 1;
  highPart = highPart | commandSend;
  lowPart = lowPart | commandSend;

  byte PD = lowPart << 4;
  byte PC = lowPart >> 2;

  PORTD = 0; //очищаем порт
  PORTC = 0;

  delayMicroseconds(40);

  //******************* RIGHT *****************************
  PORTD = PD;                // 0,1 bits
  PORTC = PC;                // 2-7 bits
  PORTD = PORTD | B00001000; // Синхрофлаг подняли

  //*******************************************************
  delayMicroseconds(30);

  PORTC = 0; // Очищаем порт
  PORTD = 0;

  //********************** LEFT ***************************
  PD = highPart << 4;
  PC = highPart >> 2;

  delayMicroseconds(20);

  PORTD = PD;                // 0,1 bits
  PORTC = PC;                // 2-7 bits
  PORTD = PORTD | B00001000; // Синхрофлаг подняли

  delayMicroseconds(30);

  PORTC = 0; // Очищаем порт
  PORTD = 0;

  delayMicroseconds(15);
}

//****************************************************************************************

void printSector()
{
  int sixteen = 0;
  //Serial.println("");
  for (byte q = 0; q < sectorSize; q++)
  {
    if (sector[q] < 0x10)
    {
      //Serial.print("0");
    }

    //Serial.print(sector[q], HEX);
    //Serial.print(" ");
    sixteen++;

    if (sixteen == 16)
    {
      sixteen = 0;
      //Serial.println("");
    }
  }
}


//****************************************************************************************

void READ()
{

  Serial.println("READ T/S\t" + String(curTrack) + " / " + String(curSector));

  startByte = curTrack * (sectors);
  startByte = startByte * sectorSize + sectorSize * curSector;





  myFile = SD.open(curDiskName);
  if (myFile)
  {
    myFile.seek(startByte);
    myFile.read(sector, 128);
    //Serial.print("READ T:");
    //Serial.print(curTrack);
    //Serial.print(" S:");
    //Serial.println(curSector);
  }
  else
  {
    Serial.println("error opening " + curDiskName);
  }

  DDRC = B11111111;
  DDRD = DDRD | B11111100;

  for (byte q = 0; q < sectorSize; q++)
  {
    putData2(sector[q], 000);

  }
  myFile.close();

  DDRC = B00000000;
  DDRD = B00000000;

  command = 0xFF;

}

//*******************************************************************************

void HOME()
{
  Serial.println("HOME:");
  //curSector = 0;
  curTrack = 0;

  command = 0xFF;
}


void SETSEC()
{
  Serial.println("SETSEC:\t" + String (curSector));

  if (curSector > sectors)
  {
    //Serial.println(String(curSector) + " Sector error");
    curSector = 0;
  }

  command = 0xFF;
}

void SETTRK()
{
  Serial.println("SETTRK:\t" + String (curTrack));
  if (curTrack > tracks)
  {
    //Serial.println(String(curTrack) + " Track error");
    curTrack = 0;
  }

  command = 0xFF;
}

void SELDSK()
{
  diskLtr = char (97 + curDrive);
  curDiskName = diskName + diskLtr + diskExt;
  command = 0xFF;
  Serial.println("SELDSK:\t" + String (curDiskName));
}

void WRITE()
{
  startByte = curTrack * (sectors);
  startByte = startByte * sectorSize + sectorSize * curSector;
  databits = 0;
  Serial.println("WRITE T/S:\t" + String(curTrack) + " / " + String(curSector));

  DDRC = B00000000;
  DDRD = B00000000;

  byte portc, portd, L4, H4; // Внимание L И H перепутаны =)

  for (int byteCount = 0; byteCount < 128; byteCount++)
  {
    sector [byteCount] = getByte();
   // Serial.println(byteCount);
  }

  myFile = SD.open(curDiskName, O_WRITE);
  if (myFile)
  {
    myFile.seek(startByte);
    myFile.write(sector, 128);
    myFile.close();
  }
  else
  {
    // if the file didn't open, print an error:
    Serial.println("error opening " + curDiskName);
  }


  command = 0xFF;
}


//*****************************************************************************
void setup()
{
  DDRC = B00000000;
  DDRD = B00000000;
  Serial.begin(115200);

  if (!SD.begin(10))
  {
    Serial.println("SD initialization failed!");
    while (1);
  }

  Serial.println("SD initialization done.");

  if (SD.exists(curDiskName))
  {
    Serial.println(curDiskName + " used");
  }
  else
  {
    Serial.println(curDiskName + "doesn't exist.");
  }
}

void loop()
{

  byte result = getByte();

 // Serial.println("Command:\t" + String(command, BIN) + " / " + String(result, HEX));

  switch (command)
  {
    case 0xFF: //DUMB CYCLE
      break;
    case 00: //Read a sector
      READ();
     // delay(2);
      break;
    case 01: //Move disc head to track 0
      HOME();
      break;
    case 02: //Select disc drive
      curDrive = result;
      SELDSK();
      break;
    case 03: //Set sector number
      curSector = result;
      SETSEC();
      break;
    case 04: //Set track number
      curTrack = result;
      SETTRK();
      break;
    case 05:
      break;
    case 06:
      break;
    case 07: //Write a sector
      WRITE();
      break;
  }
 // pinMode(LED_BUILTIN, OUTPUT);
 // digitalWrite(LED_BUILTIN, HIGH);

  command = 0xFF;
}
