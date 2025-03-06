cmake_minimum_required(VERSION 3.16)

project(CouplesApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required Qt packages
find_package(Qt6 COMPONENTS Core Quick QuickControls2 REQUIRED)

# Set Android-specific configuration (optional, depending on your setup)
if(ANDROID)
    include(FetchContent)
       FetchContent_Declare(
           android_openssl
           DOWNLOAD_EXTRACT_TIMESTAMP true
           URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
       )
       FetchContent_MakeAvailable(android_openssl)
       include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)

    set(CMAKE_ANDROID_ARCH_ABI arm64-v8a)  # You can change this to other ABIs like armeabi-v7a, x86_64, etc.
    set(CMAKE_ANDROID_NDK ${ANDROID_NDK})  # Set your Android NDK path here if needed
    set(CMAKE_ANDROID_SDK ${ANDROID_SDK})  # Set your Android SDK path here if needed

    # Define the Android manifest package and activity
    set(CMAKE_ANDROID_PACKAGE_NAME "com.example.couplesapp")
    set(CMAKE_ANDROID_ACTIVITY_NAME "MainActivity")
    set(CMAKE_ANDROID_VERSION 21)  # Set the Android API level (minimum supported)

    # Set Qt's Android-specific libraries (Qt Quick, Qt Core, etc.)
    find_package(Qt6 REQUIRED COMPONENTS Core Quick)

endif()

# Define the sources for the application
set(PROJECT_SOURCES
    main.cpp
)

# Create the executable with resources embedded properly
qt_add_executable(${PROJECT_NAME}
    MANUAL_FINALIZATION
    ${PROJECT_SOURCES}
)
if (ANDROID)
    add_android_openssl_libraries(${PROJECT_NAME})
endif()
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

# For Android, ensure that the package and activity are correctly set
if(ANDROID)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        ANDROID_PACKAGE_NAME ${CMAKE_ANDROID_PACKAGE_NAME}
        ANDROID_ACTIVITY_NAME ${CMAKE_ANDROID_ACTIVITY_NAME}
        ANDROID_VERSION_CODE 1  # Version code for Android (increment as needed)
    )
endif()

# Link the required libraries
target_link_libraries(${PROJECT_NAME}
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
)

# Finalize the Qt configuration
qt_finalize_executable(${PROJECT_NAME})

# Additional Android settings can go here (optional)
if(ANDROID)
    # Example for enabling additional Qt Android plugins or features
    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/android")
endif()
