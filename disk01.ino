#include <Arduino.h>
#include <SPI.h>
#include <SD.h>

/*DDRD = B11111110;  // sets Arduino pins 1 to 7 as outputs, pin 0 as input
  DDRD = DDRD | B11111100;  // this is safer as it sets pins 2 to 7 as outputs without changing the value of pins 0 & 1, which are RX & TX
  PORTD = B10101000; // sets digital pins 7,5,3 HIGH
  DDRD - The Port D Data Direction Register - read/write
  PORTD - The Port D Data Register - read/write
  PIND - The Port D Input Pins Register - read only
  Большинство контроллеров Arduino умеют обрабатывать до двух внешних прерываний, пронумерованных так: 0 (на цифровом порту 2) и 1 (на цифровом порту 3).
  Arduino Mega обрабатывает дополнительно еще четыра прерывания: 2 (порт 21), 3 (порт 20), 4 (порт 19) и 5 (порт 18).


*/

/*
  Тестовая геометрия
  размер сектора  128 байт
  секторов        2
  дорожек         4
  итого 1024 байта
*/

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

const long int diskSize = 6912; //sectors * tracks * sectorSize;
byte disk[128] = {0x00};

const int chipSelect = 10;

File myFile;

volatile byte databits;
volatile byte state;
volatile byte command;
volatile byte data4, data4H, data4L, data8;
byte wrPend, byteCount;
bool kostyil;

byte sectorSize = 128;
byte sectors = 26;
byte tracks = 90;

byte curSector = 0;
byte curTrack = 0;
byte curDrive = 0;

byte sector[128];

void getData()
{

  DDRC = B00000000;
  DDRD = B00000000;

  if (kostyil)
  {
    kostyil = false;
    Serial.println("K");
    return;
  }

  Serial.println("*");

  byte portb = PINC;
  portb = portb << 2;

  byte portd = PIND;
  portd = portd >> 3;

  databits = portb | portd;

  command = (databits & B00001110) >> 1;
  data4 = (databits & B11110000) >> 4;

  if (state == 1)
  {
    data4H = data4;
    state = 2;
  }
  if (state == 0)
  {
    data4L = data4;
    state = 1;
  }
}

//**********************************************************************************************

void putData(byte dataSend, byte commandSend)
{

  byte highPart, lowPart;

  highPart = dataSend & B11110000;
  lowPart = (dataSend & B00001111) << 4;
  commandSend = commandSend << 1;
  highPart = highPart | commandSend;
  lowPart = lowPart | commandSend;

  byte PD = lowPart << 4;
  byte PC = lowPart >> 2;

  delay(2); //2
  //delayMicroseconds(500);

  PORTD = 0; //очищаем порт
  PORTC = 0;

  //******************* RIGHT *****************************
  PORTD = PD;                // 0,1 bits
  PORTC = PC;                // 2-7 bits
  PORTD = PORTD | B00001000; // Синхрофлаг подняли

  //*******************************************************

  delay(5); //2
  //delayMicroseconds(500);

  PORTC = 0; // Очищаем порт
  PORTD = 0;

  //********************** LEFT ***************************
  PD = highPart << 4;
  PC = highPart >> 2;

  PORTD = PD;                // 0,1 bits
  PORTC = PC;                // 2-7 bits
  PORTD = PORTD | B00001000; // Синхрофлаг подняли

  delay(2); //2
  //delayMicroseconds(500);

  PORTC = 0; // Очищаем порт
  PORTD = 0;
  delay(2);
}






void putData2 (byte dataSend, byte commandSend)
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
  
  //delay(10);
  delayMicroseconds(500);

  //******************* RIGHT *****************************
  PORTD = PD;                // 0,1 bits
  PORTC = PC;                // 2-7 bits
  PORTD = PORTD | B00001000; // Синхрофлаг подняли

  //*******************************************************
//delay(10);
delayMicroseconds(500);

  PORTC = 0; // Очищаем порт
  PORTD = 0;

  //********************** LEFT ***************************
  PD = highPart << 4;
  PC = highPart >> 2;
//delay(10);
  delayMicroseconds(500);

  PORTD = PD;                // 0,1 bits
  PORTC = PC;                // 2-7 bits
  PORTD = PORTD | B00001000; // Синхрофлаг подняли
//delay(10);
  delayMicroseconds(100);

  PORTC = 0; // Очищаем порт
  PORTD = 0;
  //delay(10);
  delayMicroseconds(500);
}















//****************************************************************************************

void printSector()
{
  int sixteen = 0;
  Serial.println("");
  for (byte q = 0; q < sectorSize; q++)
  {
    if (sector[q] < 0x10)
    {
      Serial.print("0");
    }

    Serial.print(sector[q], HEX);
    Serial.print(" ");
    sixteen++;

    if (sixteen == 16)
    {
      sixteen = 0;
      Serial.println("");
    }
  }
}

void HOME()
{
  Serial.println("");
  Serial.println("Going home.");
  //curSector = 0;
  curTrack = 0;
}
//****************************************************************************************

void READ()
{
  detachInterrupt(1);

  
  long int startByte = curTrack * sectors * sectorSize + sectorSize * curSector;

  myFile = SD.open("DISKA.IMG");
  myFile.seek(startByte);

  myFile.read(sector, 128);

  Serial.print("TRACK:");
  Serial.print(curTrack);
  Serial.print("  SECTOR:");
  Serial.print(curSector);
  Serial.print("  Startbyte:");
  Serial.println(startByte);

  DDRC = B11111111;
  DDRD = DDRD | B11111100;

  for (byte q = 0; q < sectorSize; q++)
  {
    putData2 (sector[q], 000);
    // Serial.print(sector[q]);
    // Serial.print("_");
  }
  Serial.println("");
  myFile.close();

  DDRC = B00000000;
  DDRD = B00000000;

  kostyil = true;
  attachInterrupt(1, getData, RISING);

  //printSector();
}

//*******************************************************************************

void SETSEC()
{
  curSector = data8; // убран -1

  if (curSector > sectors)
  {
    Serial.println(String(curSector) + " Sector error");
    curSector = 0;
  }
  Serial.print("curSector:");
  Serial.println(curSector);
}

void SETTRK()
{
  curTrack = data8;
  if (curTrack > tracks)
  {
    Serial.println(String(curTrack) + " Track error");
    curTrack = 0;
  }

  Serial.print("SETTRK curTrack:");
  Serial.println(curTrack);
}

void SELDSK()
{
  curDrive = data8;
  Serial.print("Drive selected:");
  Serial.println(curDrive);
}

void WRITE()
{

  long int startByte = curTrack * sectors * sectorSize + sectorSize * curSector;

  if (wrPend == false)
  {
    Serial.print("Writting:");
    Serial.print(curSector);
    Serial.print(" sector / Track:");
    Serial.println(curTrack);
    Serial.print("startByte = ");
    Serial.println(startByte);

    byteCount = 0;
    sector[byteCount] = data8;
    wrPend = true;
    return;
  }

  byteCount++;

  if (byteCount < sectorSize)
  {
    sector[byteCount] = data8;

    if (byteCount == sectorSize - 1)
    {
      wrPend = false;
    }
    myFile = SD.open("DISKA.IMG, FILE_WRITE");
    myFile.seek(startByte);

    myFile.write(sector, 128);
    myFile.close();
    return;
  }
}

void cardInfo()
{
}

//*****************************************************************************
void setup()
{
  DDRC = B00000000;
  DDRD = B00000000;
  Serial.begin(115200);
  // kostyil = true;
  attachInterrupt(1, getData, RISING);

  if (!SD.begin(10))
  {
    Serial.println("SD initialization failed!");
    while (1)
      ;
  }

  Serial.println("SD initialization done.");

  if (SD.exists("DISKA.IMG"))
  {
    Serial.println("DISKA.IMG used");
  }
  else
  {
    Serial.println("DISKA.IMG doesn't exist.");
  }
}

void loop()
{

  if (state != 0)
  {
    if (state == 2)
    {
      data8 = data4L + data4H * 16;
      state = 0;

      switch (command)
      {
      case 00: //Read a sector
        READ();
        break;
      case 01: //Move disc head to track 0
        HOME();
        break;
      case 02: //Select disc drive
        SELDSK();
        break;
      case 03: //Set sector number
        SETSEC();
        break;

      case 04: //Set track number
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
    }
  }
}
