#include <ESP8266WiFi.h>
#include <ESP8266mDNS.h>
#include <Adafruit_NeoPixel.h>

#define PIN               D6
#define NUMPIXELS         45
#define BASE_BRIGHTNESS   200
#define DEBUG             0
#define HOSTNAME          "bunker-8266"


const char* ssid = "Bunker11";
const char* password = "mc nuggets";

int brightness = BASE_BRIGHTNESS;

WiFiServer server(80);

Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);


void update_pixel(int pixel, int r, int g, int b) {
  pixels.setPixelColor(pixel, pixels.Color(r, g, b));
  pixels.show();
}


void setup() {
  Serial.begin(115200);
  pixels.begin();
  pixels.setBrightness(BASE_BRIGHTNESS);

  reset_pixels();

  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  WiFi.hostname(HOSTNAME);

  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }

  Serial.println("WiFi connected");
  Serial.println(WiFi.localIP());

  if (!MDNS.begin(HOSTNAME)) {
    update_pixel(0, 200, 0, 0);
    Serial.println("Error setting up MDNS responder!");
    while (1) {
      delay(1000);
    }
  }
  Serial.println("mDNS responder started");

  update_pixel(0, 0, 200, 0);
  pixels.show();

  server.begin();
  MDNS.addService("http", "tcp", 80);
}

void sync_led(WiFiClient client) {
  int new_brightness = -1;

  while (client.available()) {
    String line = client.readStringUntil('\r');

    int ix_magic_ld = line.indexOf("ld");
    int ix_colon = line.indexOf(":");

    if (ix_magic_ld != -1) {
      // Sync the LEDs
      int ix_led = line.substring(ix_magic_ld + 2, ix_colon).toInt();

      // The RGB value are encoded in Base 10 (not base 16) with "zero" padding.
      // LD<LED_INDEX>: FFFFFF
      // | |          | |
      // 0 2          C 2

      String hexval = line.substring(ix_colon + 2);

      long value = strtol(hexval.c_str(), NULL, 16);

      int led_r = value >> 16;
      int led_g = value >> 8 & 0xFF;
      int led_b = value & 0xFF;

      pixels.setPixelColor(ix_led, pixels.Color(led_r, led_g, led_b));
      pixels.show();
      #if DEBUG
      Serial.print("LED#");
      Serial.print(ix_led);
      Serial.print(" <rgb>:");
      Serial.print(led_r);
      Serial.print(',');
      Serial.print(led_g);
      Serial.print(',');
      Serial.print(led_b);
      Serial.print('\n');
      #endif
    }
    int ix_magic_br = line.indexOf("brightness");
    if (ix_magic_br != -1) {
      // Update the Brightness Values
      new_brightness = line.substring(ix_colon + 2).toInt();
    }
  }

  if (new_brightness >= 0) {
    update_brightness(new_brightness);
  }
}

void reset_pixels() {
  for (int i=1; i < NUMPIXELS; i++) {
    pixels.setPixelColor(i, pixels.Color(0, 0, 0));
  }
  pixels.setPixelColor(0, pixels.Color(0, 0, 200));
  pixels.show();
}

void update_brightness(int to_value) {
  if (to_value < 0 || to_value > 255) {
    return;
  }
  Serial.print('next brightness');
  Serial.print(to_value);
  Serial.println(brightness);
  // Slowly update the brightness
  while (true) {
    if (brightness < to_value) {
      brightness++;
    } else if (brightness > to_value) {
      brightness--;
    } else {
      break;
    }
    pixels.setBrightness(brightness);
    pixels.show();
    delay(10);
  }
}


void loop() {
  WiFiClient client = server.available();
  if (!client) {
    return;
  }
  client.setNoDelay(true);


  unsigned long timeout = millis() + 3000;
  while (!client.available() && millis() < timeout) {
    delay(1);
  }
  if (millis() > timeout) {
    Serial.println("timeout");
    client.flush();
    client.stop();
    return;
  }

  sync_led(client);

  client.flush();

  String s = "HTTP/1.1 201 OK\r\n";
  client.print(s);
}
