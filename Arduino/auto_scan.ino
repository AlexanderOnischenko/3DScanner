#include <SoftwareSerial.h>
#include <AccelStepper.h>
#include <BluetoothConfig.h>

//#define DEBUG

#define RX_PIN 5
#define TX_PIN 6

#define STEPPER_PIN1 8
#define STEPPER_PIN2 9
#define STEPPER_PIN3 10
#define STEPPER_PIN4 11

#define MOTOR_INTERFACE_TYPE 8
#define STEPS_PER_REVOLUTION 2048
#define MAX_MOTOR_SPEED 500
#define MAX_MOTOR_ACCELERATION 200

SoftwareSerial myBluetooth(RX_PIN, TX_PIN); // RX, TX
AccelStepper myStepper(MOTOR_INTERFACE_TYPE, STEPPER_PIN1, STEPPER_PIN2, STEPPER_PIN3, STEPPER_PIN4);
int numSteps = 108; // Для 20 изображений

// Указатель на поток для выбора источника ввода
#ifdef DEBUG
Stream *inputSource = &Serial; // Используем Serial для ввода в режиме отладки
#else
Stream *inputSource = &myBluetooth; // Используем Bluetooth в нормальном режиме
#endif

void setup() {
  myBluetooth.begin(9600);
  myStepper.setMaxSpeed(MAX_MOTOR_SPEED);
  myStepper.setAcceleration(MAX_MOTOR_ACCELERATION);
  myStepper.moveTo(0);
  myStepper.runToPosition();
  Serial.begin(9600);
  Serial.println("Started");
}

void loop() {
  if (inputSource->available()) {
    char receivedChar = inputSource->read();
    handleReceivedChar(receivedChar);
  }
}

void handleReceivedChar(char receivedChar) {
  Serial.print(receivedChar);
  switch (receivedChar) {
    // тестовые команды для проверки всех 4х обмоток мотора
    case '1': activateStepper(STEPPER_PIN1); break;
    case '2': activateStepper(STEPPER_PIN2); break;
    case '3': activateStepper(STEPPER_PIN3); break;
    case '4': activateStepper(STEPPER_PIN4); break;
    case '0': deactivateStepper(); break;
    // операционные команды
    case ROTATE_CHAR: rotate(numSteps); break;
    case ROTATE_BACKWARDS_CHAR: rotateBackwards(numSteps); break;
    case TERM_CHAR: deactivateStepper(); break;
    // команды настройки
    case SET_NUMSHOTS_START: updateNumSteps(); break;
    default: Serial.println("Invalid Command");
  }
}

void activateStepper(int pin) {
  digitalWrite(pin, HIGH);
  delay(2);
}

void deactivateStepper() {
  digitalWrite(STEPPER_PIN1, LOW);
  digitalWrite(STEPPER_PIN2, LOW);
  digitalWrite(STEPPER_PIN3, LOW);
  digitalWrite(STEPPER_PIN4, LOW);
}

void rotate(int steps) {
  for (int i = 0; i < steps; i++) {
    activateStepper(STEPPER_PIN1);
    deactivateStepper();
    activateStepper(STEPPER_PIN2);
    deactivateStepper();
    activateStepper(STEPPER_PIN3);
    deactivateStepper();
    activateStepper(STEPPER_PIN4);
    deactivateStepper();
  }
  // Записываем обратно в порт информаццию о завершении операции
  Serial.println(TERM_CHAR);
  myBluetooth.write(TERM_CHAR);
}

void rotateBackwards(int steps) {
  for (int i = steps; i > 0; i--) {
    activateStepper(STEPPER_PIN4);
    deactivateStepper();
    activateStepper(STEPPER_PIN3);
    deactivateStepper();
    activateStepper(STEPPER_PIN2);
    deactivateStepper();
    activateStepper(STEPPER_PIN1);
    deactivateStepper();
  }
  // Записываем обратно в порт информаццию о завершении операции
  Serial.println(TERM_CHAR);
  myBluetooth.write(TERM_CHAR);
}

void updateNumSteps() {
  String inputString = "";
 
  while (true) { 
    if (!inputSource->available()) {
      continue; // Если данных нет, пропускаем текущую итерацию
    }
    
    char inChar = inputSource->read();
    Serial.print(inChar); // Отладочный вывод полученного символа

    if (inChar == SET_NUMSHOTS_END) {
      break; // Выход из цикла при встрече с символом 'X'
    }
    inputString += inChar; // Добавление символа к строке
  }

  int steps = inputString.toInt(); // Преобразование строки в число
  if (steps > 0) { // Проверка валидности полученного числа шагов
    numSteps = steps;
    Serial.println();
    Serial.println("Number of steps updated to: " + String(numSteps));
  } else {
    Serial.println("Invalid number of steps received.");
  }
  myBluetooth.write(TERM_CHAR);
}
