import processing.serial.*;

Serial myPort;
String portName = "COM4";  // <<< CHANGE to your port

// ---- State variables ----
boolean flameDetected = false;
boolean smokeDetected = false;
boolean relayOn = false;
int currentAngle = 90;
int flameValue = 0;
int smokeValue = 0;
int flameBaseline = 0;
int flameThreshold = 500;
String latestMessage = "Waiting for data...";

// ---- Layout ----
int margin = 40;
int panelW, panelH;

void setup() {
  size(1100, 700);          // larger canvas
  surface.setTitle("Flame + Smoke Monitor (BIG)");
  
  // Uncomment to see available ports
  // println(Serial.list());
  
  try {
    myPort = new Serial(this, portName, 9600);
    myPort.bufferUntil('\n');
  } catch (Exception e) {
    println("Cannot open port: " + portName);
    exit();
  }
  
  // Use larger default font
  textFont(createFont("SansSerif", 18));
}

void draw() {
  background(30, 30, 40);
  
  drawFlamePanel();
  drawAnglePanel();
  drawSensorPanel();
  drawRelayPanel();
  drawLogPanel();
  
  // Read serial
  while (myPort.available() > 0) {
    String line = myPort.readStringUntil('\n');
    if (line != null) {
      parseLine(line.trim());
    }
  }
}

// ---------- UI Panels (scaled) ----------

void drawFlamePanel() {
  int x = margin;
  int y = margin;
  int w = 260;
  int h = 200;
  fill(50, 50, 60);
  rect(x, y, w, h, 12);
  
  float cx = x + 80;
  float cy = y + 80;
  float r = 70;
  if (flameDetected) {
    for (int i = 0; i < 6; i++) {
      fill(255, 150, 0, 30 - i*4);
      ellipse(cx, cy, r + i*12, r + i*12);
    }
    fill(255, 120, 0);
    ellipse(cx, cy, r, r);
    fill(255, 220, 50, 200);
    ellipse(cx-12, cy-12, r*0.5, r*0.5);
    float flick = random(0.85, 1.15);
    fill(255, 200, 50, 120);
    ellipse(cx + random(-6,6), cy + random(-6,6), r*0.6*flick, r*0.6*flick);
  } else {
    fill(70, 70, 90);
    ellipse(cx, cy, r, r);
  }
  fill(220);
  textAlign(CENTER, CENTER);
  textSize(20);
  text(flameDetected ? "🔥 FLAME" : "No Fire", cx, cy + r + 30);
  
  // Smoke cloud (larger)
  float sx = x + 210;
  float sy = y + 75;
  fill(smokeDetected ? color(180, 180, 210, 220) : color(80, 80, 100, 100));
  noStroke();
  ellipse(sx, sy, 38, 38);
  ellipse(sx - 22, sy + 6, 28, 28);
  ellipse(sx + 22, sy + 6, 28, 28);
  ellipse(sx, sy + 22, 34, 26);
  fill(220);
  textAlign(CENTER, CENTER);
  textSize(18);
  text(smokeDetected ? "☁ SMOKE" : "No Smoke", sx, sy + 58);
}

void drawAnglePanel() {
  int x = margin + 280;
  int y = margin;
  int w = 260;
  int h = 200;
  fill(50, 50, 60);
  rect(x, y, w, h, 12);
  
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(28);
  text("Angle: " + currentAngle + "°", x + w/2, y + 50);
  
  pushMatrix();
  translate(x + w/2, y + 140);
  noFill();
  stroke(100);
  strokeWeight(3);
  arc(0, 0, 120, 120, radians(20), radians(160));
  for (int a = 20; a <= 160; a += 20) {
    float rad = radians(a);
    float inner = 55;
    float outer = 65;
    stroke(120, 120, 160);
    line(inner * cos(rad - HALF_PI), inner * sin(rad - HALF_PI),
         outer * cos(rad - HALF_PI), outer * sin(rad - HALF_PI));
  }
  float ang = radians(currentAngle);
  stroke(255, 180, 50);
  strokeWeight(6);
  line(0, 0, 55 * cos(ang - HALF_PI), 55 * sin(ang - HALF_PI));
  fill(255, 180, 50);
  noStroke();
  ellipse(0, 0, 12, 12);
  popMatrix();
}

void drawSensorPanel() {
  int x = margin + 560;
  int y = margin;
  int w = 280;
  int h = 200;
  fill(50, 50, 60);
  rect(x, y, w, h, 12);
  
  float barX = x + 30;
  float barW = 220;
  float barH = 28;
  
  // Flame bar
  float barY1 = y + 55;
  fill(70);
  rect(barX, barY1, barW, barH, 6);
  float val = constrain(map(flameValue, 0, 1023, 0, barW), 0, barW);
  fill(flameDetected ? color(255, 140, 0) : color(100, 150, 255));
  rect(barX, barY1, val, barH, 6);
  // Threshold marker
  float threshX = map(flameThreshold, 0, 1023, barX, barX + barW);
  stroke(255, 50, 50);
  strokeWeight(3);
  line(threshX, barY1 - 6, threshX, barY1 + barH + 6);
  fill(220);
  textAlign(LEFT, CENTER);
  textSize(16);
  text("Flame: " + flameValue + " (base:" + flameBaseline + ")", barX, barY1 - 18);
  
  // Smoke bar
  float barY2 = y + 135;
  fill(70);
  rect(barX, barY2, barW, barH, 6);
  float valSmoke = constrain(map(smokeValue, 0, 1023, 0, barW), 0, barW);
  fill(smokeDetected ? color(180, 180, 230) : color(80, 80, 120));
  rect(barX, barY2, valSmoke, barH, 6);
  fill(220);
  text("Smoke: " + smokeValue, barX, barY2 - 18);
}

void drawRelayPanel() {
  int x = margin;
  int y = margin + 230;
  int w = 260;
  int h = 130;
  fill(50, 50, 60);
  rect(x, y, w, h, 12);
  
  fill(relayOn ? color(0, 210, 80) : color(200, 40, 40));
  rect(x + 30, y + 25, 90, 55, 8);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(26);
  text(relayOn ? "ON" : "OFF", x + 75, y + 52);
  
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(18);
  text("Pump", x + 150, y + 30);
  textSize(16);
  String cond = relayOn ? "ACTIVE (Flame+Smoke)" : "DEACTIVATED";
  fill(relayOn ? color(150, 255, 150) : color(255, 150, 150));
  text(cond, x + 150, y + 70);
}

void drawLogPanel() {
  int x = margin + 280;
  int y = margin + 230;
  int w = 560;
  int h = 130;
  fill(20, 20, 30);
  rect(x, y, w, h, 12);
  
  fill(200);
  textAlign(LEFT, CENTER);
  textSize(18);
  text("Status:", x + 15, y + 25);
  fill(255);
  textSize(18);
  text(latestMessage, x + 15, y + 70);
}

// ---------- Serial Parsing (unchanged) ----------

void parseLine(String line) {
  latestMessage = line;
  println(">>> " + line);
  
  if (line.startsWith("FLAME_DETECTED")) {
    flameDetected = true;
    String[] parts = line.split(" ");
    for (String p : parts) {
      if (p.contains("=")) {
        String[] kv = p.split("=");
        if (kv.length == 2) {
          String key = kv[0];
          int val = int(kv[1]);
          if (key.equals("angle")) currentAngle = val;
          else if (key.equals("flame")) flameValue = val;
          else if (key.equals("baseline")) flameBaseline = val;
          else if (key.equals("smoke")) {
            smokeValue = val;
            smokeDetected = (smokeValue > 80);
          }
        }
      }
    }
  }
  else if (line.startsWith("FLAME_EXTINGUISHED")) {
    flameDetected = false;
  }
  else if (line.startsWith("PUMP_ON")) {
    relayOn = true;
  }
  else if (line.startsWith("PUMP_OFF")) {
    relayOn = false;
  }
  else if (line.startsWith("CALIBRATION")) {
    String[] parts = line.split(" ");
    for (String p : parts) {
      if (p.contains("=")) {
        String[] kv = p.split("=");
        if (kv.length == 2) {
          if (kv[0].equals("baseline")) flameBaseline = int(kv[1]);
          else if (kv[0].equals("threshold")) flameThreshold = int(kv[1]);
        }
      }
    }
  }
}
