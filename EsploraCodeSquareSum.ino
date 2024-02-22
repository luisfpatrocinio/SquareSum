/*
  Esplora Kart

  This sketch turns the Esplora into a PC game pad.

  It uses the both the analog joystick and the four switches.
  By moving the joystick in a direction or by pressing a switch,
  the PC will "see" that a key is pressed. If the PC is running
  a game that has keyboard input, the Esplora can control it.

  The default configuration is suitable for SuperTuxKart, an
  open-source racing game. It can be downloaded from
  http://supertuxkart.sourceforge.net/ .

  Created on 22 november 2012
  By Enrico Gueli <enrico.gueli@gmail.com>
*/


#include <Esplora.h>
#include <Keyboard.h>

boolean buttonStates[8];

const byte buttons[] = {
  JOYSTICK_DOWN,
  JOYSTICK_LEFT,
  JOYSTICK_UP,
  JOYSTICK_RIGHT,
  SWITCH_RIGHT, //4
  SWITCH_LEFT,  //2
  SWITCH_UP,    //3
  SWITCH_DOWN,  //1
};


const char keystrokes[] = {
  KEY_DOWN_ARROW,
  KEY_LEFT_ARROW,
  KEY_UP_ARROW,
  KEY_RIGHT_ARROW,
  'K',
  'J',
  'I',
  'L'
};

const int MAX_VALUE = 100;

int limitar_variavel(int variavel, int valor_max){
  int novo_valor = variavel;

  if (novo_valor >= 0){
    if ( novo_valor > valor_max ){
        novo_valor = valor_max;
    }
  } else {
    if ( novo_valor < -valor_max){
        novo_valor = -valor_max;
    }
  }

  return novo_valor;
}


void setup() {
  Keyboard.begin();
  Serial.begin(9600);
}


void loop() {


  for (byte thisButton = 0; thisButton < 8; thisButton++) {
    boolean lastState = buttonStates[thisButton];
    boolean newState = Esplora.readButton(buttons[thisButton]);
    if (lastState != newState) { 
     
      if (newState == PRESSED) {
        Keyboard.press(keystrokes[thisButton]);
      }
      else if (newState == RELEASED) {
        Keyboard.release(keystrokes[thisButton]);
      }
    }

    buttonStates[thisButton] = newState;
  }

  int xValue = Esplora.readAccelerometer(X_AXIS);
  int yValue = Esplora.readAccelerometer(Y_AXIS);
  int zValue = Esplora.readAccelerometer(Z_AXIS);
  
  xValue -= 16;
  yValue -= 30;

  xValue = limitar_variavel(xValue, MAX_VALUE);

  yValue = limitar_variavel(yValue, MAX_VALUE);
  
  if(abs(xValue) < 32){
    xValue = 0;
  } 

  if(abs(yValue) < 32){
    yValue = 0;
  } 


  float xPos = map(xValue, MAX_VALUE, -MAX_VALUE, -100, 100) / 100.0;
  float yPos = map(yValue, MAX_VALUE, -MAX_VALUE, -100, 100) / 100.0;


  float sliderValue = map(Esplora.readSlider(), 0, 1024, 0, 100) / 100.0;
  // float yPos = map(yValue, -512, 512, 0, MAX_H);

  //SWITCH_RIGHT, //4
  //SWITCH_LEFT,  //2
  //SWITCH_UP,    //3
  //SWITCH_DOWN,  //1

  Serial.print("b1:");
  Serial.print(!Esplora.readButton(SWITCH_DOWN));
  Serial.print("#b2:");
  Serial.print(!Esplora.readButton(SWITCH_LEFT));
  Serial.print("#b3:");
  Serial.print(!Esplora.readButton(SWITCH_UP));
  Serial.print("#b4:");
  Serial.print(!Esplora.readButton(SWITCH_RIGHT));
  Serial.print("#tv:");
  Serial.print(xPos);
  Serial.print("#sv:");
  Serial.print(sliderValue);
  Serial.print(']');
  Serial.println();

  // delay(100);
}






