#include <Arduino.h>
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

volatile byte databits;
volatile byte state;
volatile byte command;
volatile byte data4, data4H, data4L, data8;
byte wrPend, byteCount;
bool kostyil;
unsigned long startByte;

byte sectorSize = 128;
byte sectors = 128;
byte tracks = 255;

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
    return;
  }

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

void HOME()
{
  //Serial.println("HOME");
  //curSector = 0;
  curTrack = 0;
}
//****************************************************************************************

void READ()
{
  detachInterrupt(1);

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
    //Serial.println("error opening " + curDiskName);
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

  kostyil = true;
  attachInterrupt(1, getData, RISING);
}

//*******************************************************************************

void SETSEC()
{
  curSector = data8;

  if (curSector > sectors)
  {
    //Serial.println(String(curSector) + " Sector error");
    curSector = 0;
  }
}

void SETTRK()
{
  curTrack = data8;
  if (curTrack > tracks)
  {
    //Serial.println(String(curTrack) + " Track error");
    curTrack = 0;
  }


}

void SELDSK()
{
  curDrive = data8;
  diskLtr = char (97 + curDrive);
  curDiskName = diskName + diskLtr + diskExt;
  Serial.print("SELDSK: ");
  //Serial.println(curDrive);
  Serial.println(curDiskName);
}

void WRITE()
{
  detachInterrupt(1);
  delay(4);
  startByte = curTrack * (sectors);
  startByte = startByte * sectorSize + sectorSize * curSector;
  databits = 0;
  state = 0;
  Serial.println("Writting(T/S): " + String(curTrack) + " / " + String(curSector));

  DDRC = B00000000;
  DDRD = B00000000;

  byte portc, portd, L4, H4; // Внимание L И H перепутаны =)

  for (int byteCount = 0; byteCount < 128; byteCount++)
  {
    while (databits == 0)
    {
      portc = PINC;
      portc = portc << 2;
      portd = PIND;
      portd = (portd & B11111100) >> 3;
      databits = portc | portd;
    }

    while (databits != 0)
    {

      portc = PINC;
      portc = portc << 2;

      portd = PIND;
      portd = (portd & B11111100) >> 3;
      databits = portc | portd;
      if (databits != 0)
      {
        L4 = (databits - 1);
      }
    }

    while (databits == 0)
    {
      portc = PINC;
      portc = portc << 2;
      portd = PIND;
      portd = (portd & B11111100) >> 3;
      databits = portc | portd;
    }

    while (databits != 0)
    {
      portc = PINC;
      portc = portc << 2;
      portd = PIND;
      portd = (portd & B11111100) >> 3;
      databits = portc | portd;
      if (databits != 0)
      {
        H4 = (databits - 1);
      }
    }
    //H4 = H4 >> 4;
    L4 = L4 >> 4;
    sector[byteCount] = L4 | H4;
    //Serial.print (L4, HEX);
    //Serial.print ("+");
    //Serial.println (H4 , HEX);
    //Serial.print ("=");
    //Serial.println (sector[byteCount], HEX);
    //Serial.print ("\t");
    //Serial.println (char(sector[byteCount]));
    //Serial.println ("");
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

  kostyil = true;
  attachInterrupt(1, getData, RISING);
}


//*****************************************************************************
void setup()
{
  DDRC = B00000000;
  DDRD = B00000000;
  Serial.begin(115200);
  attachInterrupt(1, getData, RISING);

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

  if (state != 0)
  {
    if (state == 2)
    {
      data8 = data4L + data4H * 16;

      pinMode(LED_BUILTIN, OUTPUT);
      digitalWrite(LED_BUILTIN, HIGH);

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
