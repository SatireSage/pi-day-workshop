from machine import Pin, PWM, ADC
import time

# -----------------------------
# Pin Definitions & Constants
# -----------------------------
RED_PIN = 10
GREEN_PIN = 12
BLUE_PIN = 13
ANODE_PIN = 11

LDR_PIN = 27
POT_PIN = 26
PWM_FREQ = 1000

BUTTON_PIN = 15
LED_PIN = "LED"

class OutdoorLight:
    def __init__(self):
        # Initialize PWM on the LED pin
        self.led_pwm = PWM(Pin(ANODE_PIN))
        self.led_pwm.freq(PWM_FREQ)

        self.red = PWM(Pin(RED_PIN), freq=PWM_FREQ)
        self.green = PWM(Pin(GREEN_PIN), freq=PWM_FREQ)
        self.blue = PWM(Pin(BLUE_PIN), freq=PWM_FREQ)
        
        # Initialize ADC for the LDR and POT pins
        self.ldr_adc = ADC(Pin(LDR_PIN))
        self.pot_adc = ADC(POT_PIN)

        self.button = Pin(BUTTON_PIN, Pin.IN, Pin.PULL_UP)
        self.indicator_led = Pin(LED_PIN, Pin.OUT)

        #Input Control
        self.use_photoresistor = True # False = Potentiometer, True = Photoresistor
        self.prev_button_state = 0
    
    # -----------------------------
    # Helper Functions
    # -----------------------------
    def read_sensor(self):
        return self.ldr_adc.read_u16() if self.use_photoresistor else self.pot_adc.read_u16()

    def check_button(self):
        current_button_state = self.button.value()

        current_state = self.button.value()
        if current_state and not self.prev_button_state:
            self.use_photoresistor = not self.use_photoresistor
            self.indicator_led.value(self.use_photoresistor)
            time.sleep(0.05)  # Debounce delay
        self.prev_button_state = current_state

    # H (Hue); S (Saturation); V (Value)
    def hsv_to_rgb(self, h, s, v):
        h = h % 360
        s = s / 255.0
        v = v / 255.0

        c = v * s
        x = c * (1 - abs((h / 60) % 2 - 1))
        m = v - c

        if 0 <= h < 60:
            r, g, b = c, x, 0
        elif 60 <= h < 120:
            r, g, b = x, c, 0
        elif 120 <= h < 180:
            r, g, b = 0, c, x
        elif 180 <= h < 240:
            r, g, b = 0, x, c
        elif 240 <= h < 300:
            r, g, b = x, 0, c
        elif 300 <= h < 360:
            r, g, b = c, 0, x

        r = int((r + m) * 65535)
        g = int((g + m) * 65535)
        b = int((b + m) * 65535)

        return r, g, b

    # -----------------------------
    # Main Loop
    # -----------------------------
    def run(self):
        while True:
            self.check_button()
            sensor_value = self.read_sensor()

            if not self.use_photoresistor:
                self.led_pwm.duty_u16(65535)

                # Map potentiometer value (0-65535) to hue (0-360)
                hue = (sensor_value / 65535) * 360

                # Convert to RGB
                r, g, b = self.hsv_to_rgb(hue, 255, 255)

                # Apply to PWM
                self.red.duty_u16(r)
                self.green.duty_u16(g)
                self.blue.duty_u16(b)

            else:
                # Multiply to amplify changes, then invert
                brightness = max(0, min(65535, 65535 - (sensor_value * 2)))

                # Set the LED brightness
                self.led_pwm.duty_u16(brightness)

            mode_str = "Photoresistor" if self.use_photoresistor else "Potentiometer"
            print(f"Mode: {mode_str}, Sensor: {sensor_value}")

            time.sleep(0.1) # Run the outdoor light controller
