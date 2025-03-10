from outdoor_light import OutdoorLight
import time

def main():
    light = OutdoorLight()
    time.sleep(1)
    light.run()  # Start controlling the light

if __name__ == "__main__":
    main()
