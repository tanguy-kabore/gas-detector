#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

const char* ssid = "111111000";
const char* password = "octopus@1945#@+-trueorfalse";

WebServer server(80);
const int gasSensorPin = 35;  // Pin analogique pour le capteur de gaz
const float VOLT_RESOLUTION = 3.3; // Tension de référence de l'ESP32
const float ADC_RESOLUTION = 4095.0; // Résolution ADC de l'ESP32

// Paramètres de calibration du MQ2
const float RL = 10.0;  // Résistance de charge en kΩ
const float R0 = 10.0;  // Résistance du capteur dans l'air propre en kΩ
const float VOLT_RESOLUTION_5V = 5.0; // Tension nominale du capteur

float calculatePPM(float rs_ro_ratio) {
  // Formule de conversion pour le GPL/Butane basée sur la courbe caractéristique du MQ2
  // PPM = 10^((log(rs_ro_ratio) - b) / m)
  // où m et b sont dérivés de la courbe du datasheet
  float m = -0.47; // Pente de la courbe
  float b = 1.29;  // Ordonnée à l'origine
  
  return pow(10, ((log10(rs_ro_ratio) - b) / m));
}

void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connexion au WiFi...");
  }
  
  Serial.println("Connecté au WiFi");
  Serial.println("Adresse IP: " + WiFi.localIP().toString());
  
  server.on("/gas", HTTP_GET, handleGasReading);
  server.begin();
}

void loop() {
  server.handleClient();
}

void handleGasReading() {
  // Lecture de la valeur analogique
  float adc = analogRead(gasSensorPin);
  
  // Conversion en tension
  float voltage = (adc * VOLT_RESOLUTION) / ADC_RESOLUTION;
  
  // Calcul de la résistance du capteur (Rs)
  float rs = ((VOLT_RESOLUTION_5V * RL) / voltage) - RL;
  
  // Calcul du ratio Rs/R0
  float rs_ro_ratio = rs / R0;
  
  // Conversion en PPM
  float ppm = calculatePPM(rs_ro_ratio);
  
  // Limiter les valeurs extrêmes
  if (ppm > 10000) ppm = 10000;
  if (ppm < 200) ppm = 200;
  
  StaticJsonDocument<200> doc;
  doc["value"] = ppm;
  doc["raw_value"] = adc;
  doc["timestamp"] = millis();
  
  String response;
  serializeJson(doc, response);
  
  server.send(200, "application/json", response);
  
  // Debug sur le port série
  Serial.print("ADC: "); Serial.print(adc);
  Serial.print(", Voltage: "); Serial.print(voltage);
  Serial.print("V, Rs/R0: "); Serial.print(rs_ro_ratio);
  Serial.print(", PPM: "); Serial.println(ppm);
}
