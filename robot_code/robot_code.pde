#include <string.h>
#include <stdio.h>
#include <Wire.h> // This seems redundant, but we need to declare this
                  // dependency in the pde file or else it won't be included
                  // in the build.
//#include "nunchuk.h"

int inPin = 4;
int inputDelay = 10;

int velocity;
int angle;
int servo;

char* error;

void setup()
{
  Serial.begin(2400);
  
  pinMode(inPin, INPUT);
  pinMode(12, INPUT);  
  
  //nunchuk_init();
}

/*int readBit(boolean noDelay = false)
{
  if (!noDelay)
  {
    delay(inputDelay);
  }
  return digitalRead(inPin);
}*/

int readBit(boolean noDelay = false)
{
  if (!noDelay)
  {
    delay(inputDelay);
  }
  if (analogRead(1) > 100)
  {
    return HIGH;
  }
  else
  {
    return LOW;
  }
}

boolean receiveData()
{
  // wait for first bit
  if (readBit() != HIGH)
  {
    error = "initial";
    return false;
  }
  
  // look for 5 zeros, else exit
  int counter = 0;
  while (readBit() == LOW && counter < 5)
  {
    counter++;
  }
  if (counter != 5)
  {
    error = "counter";
    return false;
  }
  
  // check for a space
  /*if (readBit() != HIGH)
  {
    error = "space1";
    return false;
  }*/
  readBit();
  
  // get the velocity
  int velocitySign;
  if (readBit() == HIGH)
  {
    velocitySign = 1;
  }
  else
  {
    velocitySign = -1;
  }
  velocity = 0;
  for (int i=0; i<3; i++)
  {
    velocity = (velocity * 2) + readBit();
  }
  velocity = velocitySign * velocity;
  
  // check for a space
  /*if (readBit() != HIGH)
  {
    error = "space2";
    return false;
  }*/
  readBit();
  
  // get the angle
  int angleSign;
  if (readBit() == HIGH)
  {
    angleSign = 1;
  }
  else
  {
    angleSign = -1;
  }
  angle = 0;
  for (int i=0; i<3; i++)
  {
    angle = (angle * 2) + readBit();
  }
  angle = angleSign * angle;
  
  // check for a space
  /*if (readBit() != HIGH)
  {
    error = "space3";
    return false;
  }*/
  readBit();
  
  // get the servo command
  servo = readBit();
  
  // check for a space
  /*if (readBit() != HIGH)
  {
    error = "space4";
    return false;
  }*/
  readBit();
  
  // read the checksum (not yet implemented)
  //readBit();
  //readBit();
  
  // data read was successful
  return true;
}

/*boolean get_data_from_nunchuck()
{
  int jx, jy, ax, ay, az, bz, bc;
  if(nunchuk_read(&jx, &jy, &ax, &ay, &az, &bz, &bc))
  {
    if (jy > 8 || jy < -8) {
      velocity = jy;
    } else {
      velocity = 0;
    }
    
    if (jx > 8 || jx < -8) {
      angle = jx;
    } else {
      angle = 0;
    }
    
    if (bc == 1) {
      servo = 1;
    } else if (bz == 1) {
      servo = -1;
    } else {
      servo = 0;
    }
    
    return true;
  } else {
    return false;
  }
}*/

boolean motor_set_speed(int motor, int value) {
  
  int pinFwd;
  int pinBwd;
  
  value = value * 2.5;
  
  if (motor == 1) {
    pinFwd = 5;
    pinBwd = 6;
  } else if (motor == 2) {
    pinFwd = 9;
    pinBwd = 10;
  } else {
    return false;
  }
  
  if (value > 0) {
    analogWrite(pinFwd, value);
    analogWrite(pinBwd, 0);
  } else if (value < 0) {
    analogWrite(pinFwd, 0);
    analogWrite(pinBwd, (-1) * value);
  } else {
    analogWrite(pinFwd, 0);
    analogWrite(pinBwd, 0);
  }
  
  /*Serial.print(motor);
  Serial.print(" | ");
  Serial.print(value);
  Serial.print("\r\n");*/
}

void motor_control(int velocity, int angle) {
  int motorLeftSpeed;
  int motorRightSpeed;
  
  motorLeftSpeed = velocity + angle;
  motorRightSpeed = velocity - angle;
  
  int adjust;
  
  if (motorLeftSpeed > 100) {
    adjust = motorLeftSpeed - 100;
    motorLeftSpeed = 100; 
    motorRightSpeed = motorRightSpeed - adjust;
  }
  
  if (motorRightSpeed > 100) {
    adjust = motorRightSpeed - 100;
    motorRightSpeed = 100; 
    motorLeftSpeed = motorLeftSpeed - adjust;
  }
  
  if (motorLeftSpeed < -100) {
    adjust = -100 - motorLeftSpeed;
    motorLeftSpeed = -100; 
    motorRightSpeed = motorRightSpeed + adjust;
  }
  
  if (motorRightSpeed < -100) {
    adjust = -100 - motorRightSpeed;
    motorRightSpeed = -100; 
    motorLeftSpeed = motorLeftSpeed + adjust;
  }
  
  motor_set_speed(1, motorLeftSpeed);
  motor_set_speed(2, motorRightSpeed);
}

int currently_reading = 0;
int velocityRead = 0;
int velocityReadSign = 1;
int angleRead = 0;
int angleReadSign = 1;
int servoRead = 0;
int servoReadSign = 1;

boolean readSerial() {
  char val = Serial.read();
  
  if (val == '^') {
    currently_reading = 1;
    
    velocityRead = 0;
    velocityReadSign = 1;
    angleRead = 0;
    angleReadSign = 1;
    servoRead = 0;
    servoReadSign = 1;
    
    return true;
  }
  
  if (val == '$') {
    currently_reading = 0;
    
    velocityRead = velocityReadSign * velocityRead;
    angleRead = angleReadSign * angleRead;
    servoRead = servoReadSign * servoRead;
    
    motor_control(velocityRead, angleRead);
    //Serial.println(velocityRead);
    //Serial.println(angleRead);
    return true;
  }
  
  if (val == '|') {
    currently_reading++;
    return true;
  }
 
  if (currently_reading == 1) {
    if (val == '-') {
      velocityReadSign = -1;
    } else {
      velocityRead = (velocityRead * 10) + ((int)val - 48);
    }
  } else if (currently_reading == 2) {
    if (val == '-') {
      angleReadSign = -1;
    } else {
      angleRead = (angleRead * 10) + ((int)val - 48);
    }
  } else if (currently_reading == 3) {
    if (val == '-') {
      servoReadSign = -1;
    } else {
      servoRead = (servoRead * 10) + ((int)val - 48);
    }
  }
  
  
}

void loop()
{
  /*if (receiveData())
  {
    Serial.println("data received successfully");
    Serial.println(velocity);
    Serial.println(angle);
    Serial.println(servo);
  }
  else
  {
    //if (error != "initial")
    //{
      Serial.println(error);
    //}
  }*/
  
  /*if (get_data_from_nunchuck()) {
    motor_control(velocity, angle);
  }*/
  
  if (Serial.available()) {
    readSerial();
  }
  
  delay(10);

  
}
