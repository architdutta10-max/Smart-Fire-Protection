#include <Servo.h>

// ========== Pin Definitions ==========
const int FLAME_PIN = A0;          // Flame sensor (analog)
const int SMOKE_PIN = A1;          // Smoke sensor (analog)
const int SERVO_PIN = 9;           // Servo control
const int RELAY_PIN = 8;           // Pump relay

Servo scanServo;

// ========== Scan Parameters ==========
const int PAN_MIN = 20;
const int PAN_MAX = 160;
int scanAngle = PAN_MIN;
int scanDir = 1;

// ========== Thresholds (will be set by calibration) ==========
int flameThreshold = 500;
int smokeThreshold = 300;          // Adjust as needed

// ========== State ==========
bool flameDetected = false;
bool smokeDetected = false;
bool pumpActive = false;

// ========== Calibration ==========
int flameBaseline = 0;

// ========== Smoothing ==========
const int NUM_SAMPLES = 5;

int readFlame() {
  long sum = 0;
  for (int i = 0; i < NUM_SAMPLES; i++) {
    sum += analogRead(FLAME_PIN);
    delay(5);
  }
  return sum / NUM_SAMPLES;
}

void setup() {
  Serial.begin(9600);

  scanServo.attach(SERVO_PIN);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);

  // Move servo to start
  scanServo.write(scanAngle);

  // ---------- Auto‑calibration ----------
  Serial.println("CALIBRATION_START");
  long total = 0;
  for (int i = 0; i < 50; i++) {
    total += analogRead(FLAME_PIN);
    delay(20);
  }
  flameBaseline = total / 50;
  flameThreshold = flameBaseline + 150;   // margin
  if (flameThreshold > 900) flameThreshold = 900;
  if (flameThreshold < 300) flameThreshold = 300;

  Serial.print("CALIBRATION baseline=");
  Serial.print(flameBaseline);
  Serial.print(" threshold=");
  Serial.println(flameThreshold);
  Serial.println("READY");
}

void loop() {
  int flameVal = readFlame();
  int smokeVal = analogRead(SMOKE_PIN);

  smokeDetected = (smokeVal > smokeThreshold);

  // ---------- Flame Detection ----------
  if (flameVal > flameThreshold) {
    if (!flameDetected) {
      flameDetected = true;
      // Send flame detection message with all info
      Serial.print("FLAME_DETECTED angle=");
      Serial.print(scanAngle);
      Serial.print(" flame=");
      Serial.print(flameVal);
      Serial.print(" baseline=");
      Serial.print(flameBaseline);
      Serial.print(" smoke=");
      Serial.println(smokeVal);
    }

    // Stop servo (hold position)

    // Pump control: both flame AND smoke required
    if (smokeDetected) {
      if (!pumpActive) {
        pumpActive = true;
        digitalWrite(RELAY_PIN, HIGH);
        Serial.println("PUMP_ON");
      }
    } else {
      if (pumpActive) {
        pumpActive = false;
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("PUMP_OFF (no smoke)");
      }
    }

    delay(100);
  }
  else {
    // No flame
    if (flameDetected) {
      flameDetected = false;
      if (pumpActive) {
        pumpActive = false;
        digitalWrite(RELAY_PIN, LOW);
        Serial.println("PUMP_OFF (flame out)");
      }
      Serial.println("FLAME_EXTINGUISHED");
    }

    // Keep pump off
    digitalWrite(RELAY_PIN, LOW);

    // Resume scanning
    scanServo.write(scanAngle);
    delay(30);

    scanAngle += scanDir;
    if (scanAngle >= PAN_MAX || scanAngle <= PAN_MIN) {
      scanDir = -scanDir;
    }
  }
}
