# IFP Whiteboard Application

A whiteboard application designed for Android-based Interactive Flat Panels (IFPs) with local saving functionality.

## Features

- Freehand drawing with adjustable stroke width and color
- Insert shapes (rectangle, circle, line, polygon)
- Insert and edit text
- Save and load drawings locally in JSON format
- Optimized for large screens and landscape orientation

## How to Run on an IFP

1. Ensure Flutter is installed on your development machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Connect your IFP device or use an emulator
5. Run `flutter run --release` to deploy the app

## App Architecture

The app follows a clean architecture with:

- **Models**: Data structures for strokes, shapes, and texts
- **Services**: File handling and JSON serialization
- **Widgets**: Reusable UI components
- **Screens**: Main application screens

## File Format

Drawings are saved as JSON files with the following structure:

```json
{
  "strokes": [
    {
      "points": [{"x": 10, "y": 10}, {"x": 15, "y": 20}],
      "color": "#FF0000",
      "width": 3
    }
  ],
  "shapes": [
    {
      "type": "rectangle",
      "topLeft": {"x": 50, "y": 50},
      "bottomRight": {"x": 150, "y": 100},
      "color": "#0000FF"
    }
  ],
  "texts": [
    {
      "text": "Hello IFP!",
      "position": {"x": 300, "y": 400},
      "color": "#000000",
      "size": 24
    }
  ]
}
