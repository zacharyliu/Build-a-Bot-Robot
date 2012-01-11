
#include <string.h>
#include <stdio.h>
#include <Wire.h>
#include <Servo.h>

Servo theServo;
int servoPin = 4;
int servoMin = 0;
int servoMax = 360;
int servoPosition = servoMin;
int servoSpeed = 5;
int servoDirection = -1;
float servoJump = 0.2;
float servoCurrentPosition = servoPosition;

int inputDelay = 10;

int velocity;
int angle;
int servo;

char* error;

void setup()
{
  Serial.begin(2400);
  
  pinMode(12, INPUT);  
  
  theServo.attach(servoPin);
  theServo.write(servoPosition);
}

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

boolean motor_set_speed(int motor, int value) {
  
  int pinFwd;
  int pinBwd;
  
  value = value * 2.5;
  
  if (motor == 1) {
    pinFwd = 5;
    pinBwd = 6;
  } else if (motor == 2) {
    pinFwd = 3;  
    pinBwd = 11;
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

void servo_control(int servo) {
  int control;
  
  if (servo == 1) {
    control = servoDirection * servoSpeed * (-1) ;
  } else if (servo == -1) {
    control = servoDirection * servoSpeed;
  } else {
	control = 0;
  }
  
  if (servoPosition + control > servoMin && servoPosition + control < servoMax) {
    servoPosition = servoPosition + control;
  }
  
  if (servoPosition + control <= servoMin) {
    servoPosition = servoMin;
  }
  
  if (servoPosition + control >= servoMax) {
    servoPosition = servoMax;
  }
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
    
    servo_control(servoRead);
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

void servoUpdate()
{
  if (servoCurrentPosition < servoPosition) {
    servoCurrentPosition = servoCurrentPosition + servoJump;
  } else if (servoCurrentPosition > servoPosition) {
    servoCurrentPosition = servoCurrentPosition - servoJump;
  }
  
  theServo.write(int(servoCurrentPosition));
}

void loop()
{  
  if (Serial.available()) {
    readSerial();
  }
  
  servoUpdate();
  
  delay(10);
}
