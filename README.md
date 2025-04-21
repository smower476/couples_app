# Couples App

A mobile-first relationship application built with Qt/QML that helps couples strengthen their relationship through quizzes, daily questions, and date ideas.

## Features

- **Hub View**: See your relationship history, including completed quizzes, daily questions, and date ideas
- **Quizzes**: Take relationship quizzes to learn more about each other
- **Daily Questions**: Answer daily connection questions to share with your partner
- **Date Ideas**: Swipe through date ideas and find inspiration for your next outing
- **Linker**: Connect with your partner using invite codes

## Requirements

- Qt 6.2+ (Qt 6.8 recommended)
- Qt Quick and Qt Quick Controls 2
- macOS 10.15+ or iOS 14+ for Apple platforms

## Building for macOS

1. Open the project in Qt Creator
2. Select the macOS kit in the Configure Project screen
3. Build and run the application

## Building for iOS

1. Open the project in Qt Creator
2. Select the iOS kit in the Configure Project screen
3. Configure your developer signing certificate
4. Build and run the application

## Project Structure

- `main.cpp`: Application entry point
- `main.qml`: Main QML application
- `components/`: Reusable UI components
- `views/`: Application screens
- `images/`: SVG icons and images
- `styles.qss`: Application styling

## Customization

The app uses a mobile-first design approach with a consistent look and feel across platforms. The dark theme with pink accent colors can be customized by modifying:

- `Style.qml`: Central style definitions
- `styles.qss`: Additional QSS styling for widgets

## License

This project is licensed under the MIT License - see the LICENSE file for details.
