cmake_minimum_required(VERSION 3.16)

project(CouplesApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required Qt packages
find_package(Qt6 COMPONENTS Core Quick QuickControls2 REQUIRED)

# No effects libraries required

# Define the sources for the application
set(PROJECT_SOURCES
    main.cpp
)

# Create the executable with resources embedded properly
qt_add_executable(${PROJECT_NAME}
    MANUAL_FINALIZATION
    ${PROJECT_SOURCES}
)

# Add resources
qt_add_resources(${PROJECT_NAME} "qml_resources"
    PREFIX "/"
    FILES
        main.qml
        Style.qml
        qmldir
        components/BottomNavigation.qml
        views/HubView.qml
        views/QuizzesView.qml
        views/API_Key.qml
        views/DailyQuestionView.qml
        views/DateIdeasView.qml
        views/LinkerView.qml
        styles.qss
)

qt_add_resources(${PROJECT_NAME} "image_resources"
    PREFIX "/"
    FILES
        images/archive.svg
        images/help-circle.svg
        images/message-circle.svg
        images/calendar.svg
        images/heart.svg
        images/archive-active.svg
        images/help-circle-active.svg
        images/message-circle-active.svg
        images/calendar-active.svg
        images/heart-active.svg
)

# Set target properties for the application
set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.couplesapp
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# Link the required libraries
target_link_libraries(${PROJECT_NAME}
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
)

# Finalize the Qt configuration
qt_finalize_executable(${PROJECT_NAME})
