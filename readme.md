# 🔥 Smart Fire Protection System

An affordable, modular, DIY early-detection and active suppression system built using Arduino and Processing. This project detects fire and smoke, aims a nozzle towards the source, and automatically activates a water pump to suppress the flames.

## 📖 Project Overview
Home fires cause serious loss of life and property. Minutes matter, and early detection saves lives. This system provides early detection + active suppression. It is designed as a **layered defense** and a supplement to (not a replacement for) professional suppression systems.

### Key Features
* **Auto-Calibration:** The Arduino automatically calculates the ambient baseline for the flame sensor on startup to avoid false positives.
* **Active Scanning:** A servo motor sweeps the flame sensor from 20° to 160° to monitor a wide area.
* **Dual-Sensor Safety Logic:** The water pump will **only** activate if *both* a flame and smoke are detected simultaneously.
* **Real-Time Dashboard:** A custom Processing application displays live sensor readings, servo angle, and pump status via serial communication.

---

## 🛠️ Hardware Requirements & Configuration
Based on the project documentation, the system consists of:
* **Arduino Uno** (Central Controller: reads sensors, runs logic, controls outputs)
* **Flame Sensor** (KY-026 - Infrared detection)
* **Smoke Sensor** (Analog - detects smoke signatures)
* **Servo Motor** (Pan mechanism for scanning the environment)
* **Relay Module** (Acts as an electronic switch to isolate the Arduino from high-current pump loads)
* **Water Pump & PVC Nozzle** (Directed delivery for suppressant)
* **LM2596 Voltage Regulator** & **Battery** (Backup / portable power)

### ⚡ Circuit Diagram
![Circuit Diagram](hardware/circuit_diagram.png)

---

## 💻 Software & Code Configuration

### 1. Arduino (`arduino_code/sketch_sep8a.ino`)
* **Logic:** Reads flame/smoke sensors, runs threshold checks, sweeps the servo, and controls the relay.
* **Auto-Calibration:** On boot, it reads the flame sensor 50 times to establish a baseline, setting the threshold +150 above the baseline.
* **State Machine:** Scans when safe. If a flame is detected, it stops the servo. If smoke is also present, it triggers the relay (`PUMP_ON`).

### 2. Processing Dashboard (`processing_dashboard/Turbo_C___lnk.pde`)
* **Visualization:** Provides a real-time graphical interface (Flame icon, Smoke cloud, Angle gauge, Sensor bars, and Relay status).
* **Configuration:** Open the `.pde` file in the Processing IDE. **Important:** Change `String portName = "COM4";` on line 4 to match the COM port your Arduino is connected to.

### 3. Project Presentation
You can view the project presentation and slides here: [presentation.pptx](hardware/presentation.pptx)

---

## 🚀 How to Run the Project

1. **Hardware Setup:** Wire the components according to the circuit diagram. Ensure the relay is connected to the water pump and the LM2596 regulates power correctly.
2. **Flash the Arduino:** Open `sketch_sep8a.ino` in the Arduino IDE, select your board/port, and upload.
3. **Calibrate:** Open the Serial Monitor (9600 baud). The Arduino will print `CALIBRATION_START`, print its baseline, and then display `READY`. 
4. **Launch the Dashboard:** Open `Turbo_C___lnk.pde` in Processing, ensure the correct `portName` is set, and hit Run. The dashboard will now display real-time telemetry.
5. **Test:** Carefully bring a lighter (flame) and some smoke near the sensor to test the scanning stop, sensor visualization, and pump activation logic.

---

## 📈 Future Scope
* Integrate additional sensors (Temperature, CO/CO2).
* Plan safe suppressant choices (e.g., extinguisher cartridges) and mounting mechanisms.
* Expand the Processing Dashboard for remote monitoring and debugging.