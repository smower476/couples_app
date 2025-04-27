cmake_minimum_required(VERSION 3.16)
project(Couples_App VERSION 1.0 LANGUAGES CXX)

# Basic project settings
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(APP_ID "com.anton.couplesapp")
set(APP_NAME "Couples App")
set(APP_ICON "${CMAKE_CURRENT_SOURCE_DIR}/images/icon.png")

# Find required Qt packages
find_package(Qt6 COMPONENTS Core Quick QuickControls2 REQUIRED)

# Define source files
set(PROJECT_SOURCES main.cpp)

# Define QML files
set(QML_FILES
    main.qml
    components/BottomNavigation.qml
    views/HubView.qml
    views/QuizzesView.qml
    views/LinkerView.qml
    views/ProfileView.qml
    views/LoginRegisterView.qml
    views/RegisterView.qml
    views/CallAPI.js
    # Commented views that may be used later
    views/DailyQuestionView.qml
    views/DateIdeasView.qml
    views/QuizHistoryDetailView.qml
)

# Define image resources
set(IMAGE_FILES
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
    images/icon.png
)

# Add executable
qt_add_executable(${PROJECT_NAME} MANUAL_FINALIZATION ${PROJECT_SOURCES})

# Add resources
qt_add_resources(${PROJECT_NAME} "qml_resources"
    PREFIX "/"
    FILES ${QML_FILES}
)

qt_add_resources(${PROJECT_NAME} "image_resources"
    PREFIX "/"
    FILES ${IMAGE_FILES}
)

# Common properties for all platforms
set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER ${APP_ID}
    MACOSX_BUNDLE_BUNDLE_NAME ${APP_NAME}
    PRODUCT_BUNDLE_IDENTIFIER ${APP_ID}
    WIN32_EXECUTABLE TRUE
)

# Android-specific configuration
if(ANDROID)
    # Setup Android OpenSSL
    include(FetchContent)
    FetchContent_Declare(android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
    add_android_openssl_libraries(${PROJECT_NAME})
    
    # Android configuration
    set(CMAKE_ANDROID_ARCH_ABI arm64-v8a)
    set(CMAKE_ANDROID_NDK ${ANDROID_NDK})
    set(CMAKE_ANDROID_SDK ${ANDROID_SDK})
    set(CMAKE_ANDROID_PACKAGE_NAME ${APP_ID})
    set(CMAKE_ANDROID_ACTIVITY_NAME "MainActivity")
    set(CMAKE_ANDROID_VERSION 35)
    
    # Copy icon for Android
    configure_file(${APP_ICON} ${CMAKE_CURRENT_BINARY_DIR}/android/res/drawable/icon.png COPYONLY)
    
    # Set Android-specific properties
    set_target_properties(${PROJECT_NAME} PROPERTIES
        ANDROID_PACKAGE_NAME ${CMAKE_ANDROID_PACKAGE_NAME}
        ANDROID_ACTIVITY_NAME ${CMAKE_ANDROID_ACTIVITY_NAME}
        ANDROID_VERSION_CODE 1
    )
    
    # Setup Android manifest
    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    file(COPY "${CMAKE_SOURCE_DIR}/android/AndroidManifest.xml" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/android")
    
    # Commented out alternative Android configuration approach
    # set_target_properties(${PROJECT_NAME} PROPERTIES
    #     QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
    #     QT_ANDROID_PACKAGE_NAME "io.anton.couplesapp"
    #     QT_ANDROID_TARGET_SDK_VERSION 35
    #     QT_ANDROID_VERSION_CODE 20
    #     QT_ANDROID_VERSION_NAME "2.0"
    # )
endif()

# iOS-specific configuration
if(IOS)
    set(CMAKE_IOS_DEPLOYMENT_TARGET "18.4" CACHE STRING "Minimum iOS deployment version")
    set_target_properties(${PROJECT_NAME} PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/mac/Info.plist
        # XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "" # Set your Development Team ID here if needed
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET ${CMAKE_IOS_DEPLOYMENT_TARGET}
    )
    
    # Handle iOS resources
    set_source_files_properties(${APP_ICON} PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
    set(RESOURCE_FILES ${APP_ICON})
    set_target_properties(${PROJECT_NAME} PROPERTIES
        RESOURCE "${RESOURCE_FILES}"
    )
endif()

# Link Qt libraries
target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Core Qt6::Quick Qt6::QuickControls2)

# Finalize executable
qt_finalize_executable(${PROJECT_NAME})
