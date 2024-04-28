# 3DScanner Control App

## Inspiration and Purpose

This application was inspired by a [Thingiverse project](https://www.thingiverse.com/thing:3958326) but has been developed to overcome limitations related to the lack of direct interaction between the iOS device and the rotational platform. The original setup required a shutter remote and servo motor, which constrained seamless operation and integration.

To improve functionality and user interaction, this application provides direct control features through an iOS device to operate a 3D scanning platform. Significant enhancements include:
- **Direct iOS Control:** Users can directly manipulate the rotation of the scanner's platform via their iOS devices.
- **Focus Adjustment:** Focus can be adjusted directly from the app, improving scan quality.
- **Step Control:** Users can configure the number of rotation steps directly from the app, ensuring precise control during scanning.

## System Overview

The 3DScanner Control App is designed to interact with a rotary table equipped with an Arduino board and a Bluetooth 4.0 compatible module such as HM-10 or AT-09 (based on CC2541 chipset), along with a BYJ28 stepper motor. The app facilitates synchrnonization between the table's rotation and camera actions.

## Bluetooth Module Requirements

The application requires a Bluetooth LE module that supports specific service and characteristic UUIDs. Compatible modules include HM-10 or other CC2541 chipset-based devices. Note that iOS devices might not detect these modules immediately; using specialized apps like Beacon app, LightBlue, or BlueSee can help in detecting and troubleshooting connections.

## Configuration and Setup

### Project Configuration
Ensure the `BluetoothConfig.h` file includes the correct settings to match your hardware configuration:
- **Device Name:** `DEVICE_NAME`
- **Service UUID:** `SERVICE_UUID`
- **Characteristic UUID:** `CHARACTERISTIC_UUID`

These values must align with those programmed into the Bluetooth module. You can either read them from your Bluetooth module, or setup additionally by using AT+NAME, AT+UUID and AT+CHAR commands. Consistent referencing of these settings in both the iOS project and the Arduino sketch is crucial for proper functionality.

### Arduino Sketch Configuration

Arduino scetch uses pins 6 and 5 for Bluetooth communication and pins 8-11 for stepper motor. You can modify this pins in auto_scan.ino scetch. It is important to notice that wheen you copy arduino scetch, you should copy BluetoothConfig.h file as well

The Arduino sketch incorporates a debug mode which can be enabled or disabled by modifying the `#define debug` directive. This mode allows for the simulation of Bluetooth commands through the serial port, facilitating testing without the actual Bluetooth module.

### Permissions
To operate correctly, the app requires several permissions which must be declared in your project's Info.plist:
- **NSBluetoothPeripheralUsageDescription**
- **NSCameraUsageDescription**
- **NSPhotoLibraryUsageDescription**
- **NSPhotoLibraryAddUsageDescription**

## Building and Running

Prior to launching the application, verify all settings and permissions are correctly configured. Compile the project in Xcode and deploy it on an iOS device supporting Bluetooth 4.0 or newer.

## Acknowledgments

This project takes inspiration from [an original 3D scanner project on Thingiverse](https://www.thingiverse.com/thing:3958326). It's important to note that the software for this iOS-controlled 3D scanner setup was independently developed from scratch, with no software or code from the original project reused in this application.

## License

This work is licensed under the Creative Commons Attribution 4.0 International License - see the [LICENSE](LICENSE) file for details. Although inspired by a design under a different license, this implementation is an original creation, not based on or derivative of the original Thingiverse project.
