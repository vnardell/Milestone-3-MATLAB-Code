const int pressureSensor = A0;
const int oscillometricSensor = A1;

// Voltage to mmHg calibration constants
const float V_at_150mmHg = 2.874;  
const float V_at_0mmHg = 1.237;     
const float VREF = 5.0;            
const float ADC_MAX = 1023.0;  

// Calculate conversion constants: mmHg = m * V + b
const float m = 150.0 / (V_at_150mmHg - V_at_0mmHg); 
const float b = 0.0 - m * V_at_0mmHg;                 

const int MAX_SAMPLES = 32; 
int pressureValues[MAX_SAMPLES];
int amplitudeValues[MAX_SAMPLES];
int sampleCount = 0;

void setup() {
  Serial.begin(9600);
  pinMode(pressureSensor, INPUT);
  pinMode(oscillometricSensor, INPUT);
  
  Serial.println("=== Blood Pressure Monitor ===");
  Serial.println("Ready to collect data...");
  Serial.print("Conversion formula: mmHg = ");
  Serial.print(m, 2);
  Serial.print(" * V ");
  if(b >= 0) Serial.print("+ ");
  Serial.println(b, 2);
  Serial.println("==============================\n");
  delay(2000);
}

void loop() {
  int pressure = analogRead(pressureSensor);
  
  int amplitude = measurePulseAmplitude();
  
  if(sampleCount < MAX_SAMPLES) {
    pressureValues[sampleCount] = pressure;
    amplitudeValues[sampleCount] = amplitude;
    sampleCount++;
    
    float voltage = (pressure * VREF) / ADC_MAX;
    float pressure_mmHg = m * voltage + b;
    
    Serial.print("Sample ");
    Serial.print(sampleCount);
    Serial.print(" | ADC: ");
    Serial.print(pressure);
    Serial.print(" | Voltage: ");
    Serial.print(voltage, 3);
    Serial.print(" V | Pressure: ");
    Serial.print(pressure_mmHg, 1);
    Serial.print(" mmHg | Amplitude: ");
    Serial.println(amplitude);
  } else {
    calculateBloodPressure();
    
    Serial.println("\nMeasurement complete. Press reset to measure again.");
    while(true);  
  }
  
  delay(100);
}

int measurePulseAmplitude() {
  const int WINDOW_SIZE = 100;  
  int minVal = 1023;
  int maxVal = 0;
  
  for(int i = 0; i < WINDOW_SIZE; i++) {
    int reading = analogRead(oscillometricSensor);
    
    if(reading < minVal) minVal = reading;
    if(reading > maxVal) maxVal = reading;
    
    delay(5);  
  }
  return maxVal - minVal;
}

void calculateBloodPressure() {
  int maxAmplitude = 0;
  int mapPressure = 0;
  int mapIndex = 0;
  
  for(int i = 0; i < sampleCount; i++) {
    if(amplitudeValues[i] > maxAmplitude) {
      maxAmplitude = amplitudeValues[i];
      mapPressure = pressureValues[i];
      mapIndex = i;
    }
  }
  
  float mapVoltage = (mapPressure * VREF) / ADC_MAX;
  float mapMMHg = m * mapVoltage + b;

  int systolicTarget = maxAmplitude * 0.5;
  int systolicPressure = 0;
  int minDiff = 9999;
  
  for(int i = 0; i < mapIndex; i++) {
    int diff = abs(amplitudeValues[i] - systolicTarget);
    if(diff < minDiff) {
      minDiff = diff;
      systolicPressure = pressureValues[i];
    }
  }
  
  float systolicVoltage = (systolicPressure * VREF) / ADC_MAX;
  float systolicMMHg = m * systolicVoltage + b;
  
  int diastolicTarget = maxAmplitude * 0.8;
  int diastolicPressure = 0;
  minDiff = 9999;
  
  for(int i = mapIndex + 1; i < sampleCount; i++) {
    int diff = abs(amplitudeValues[i] - diastolicTarget);
    if(diff < minDiff) {
      minDiff = diff;
      diastolicPressure = pressureValues[i];
    }
  }
  
  float diastolicVoltage = (diastolicPressure * VREF) / ADC_MAX;
  float diastolicMMHg = m * diastolicVoltage + b;
  
  // Display results
  Serial.println("\n");
  Serial.println("================================");
  Serial.println("         FINAL RESULTS          ");
  Serial.println("================================");
  Serial.println("\nMean Arterial Pressure (MAP):");
  Serial.print("  Pressure: ");
  Serial.print(mapMMHg, 2);
  Serial.println(" mmHg");
  Serial.print("  Voltage: ");
  Serial.print(mapVoltage, 3);
  Serial.println(" V");
  Serial.print("  ADC: ");
  Serial.println(mapPressure);
  Serial.print("  Max Amplitude: ");
  Serial.println(maxAmplitude);
  Serial.print("  Sample Index: ");
  Serial.println(mapIndex + 1);
  
  Serial.println("\nSystolic Pressure (0.5 × max amplitude):");
  Serial.print("  Pressure: ");
  Serial.print(systolicMMHg, 2);
  Serial.println(" mmHg");
  Serial.print("  Voltage: ");
  Serial.print(systolicVoltage, 3);
  Serial.println(" V");
  Serial.print("  ADC: ");
  Serial.println(systolicPressure);
  
  Serial.println("\nDiastolic Pressure (0.8 × max amplitude):");
  Serial.print("  Pressure: ");
  Serial.print(diastolicMMHg, 2);
  Serial.println(" mmHg");
  Serial.print("  Voltage: ");
  Serial.print(diastolicVoltage, 3);
  Serial.println(" V");
  Serial.print("  ADC: ");
  Serial.println(diastolicPressure);
  
  Serial.println("\n--------------------------------");
  Serial.print("*** BLOOD PRESSURE: ");
  Serial.print((int)systolicMMHg);
  Serial.print("/");
  Serial.print((int)diastolicMMHg);
  Serial.println(" mmHg ***");
  Serial.println("================================");
}

float adcToMMHg(int adcValue) {
  float voltage = (adcValue * VREF) / ADC_MAX;
  return m * voltage + b;
}

float adcToVoltage(int adcValue) {
  return (adcValue * VREF) / ADC_MAX;
}