cmake_minimum_required(VERSION 3.16)
project(CouplesApp VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(APP_ICON images/icon.png)

find_package(Qt6 COMPONENTS Core Quick QuickControls2 REQUIRED)

if(ANDROID)
    include(FetchContent)
    FetchContent_Declare(android_openssl
        DOWNLOAD_EXTRACT_TIMESTAMP true
        URL https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)

    set(CMAKE_ANDROID_ARCH_ABI arm64-v8a)
    set(CMAKE_ANDROID_NDK ${ANDROID_NDK})
    set(CMAKE_ANDROID_SDK ${ANDROID_SDK})
    set(CMAKE_ANDROID_PACKAGE_NAME "com.example.couplesapp")
    set(CMAKE_ANDROID_ACTIVITY_NAME "MainActivity")
    set(CMAKE_ANDROID_VERSION 21)
    configure_file(${APP_ICON} ${CMAKE_CURRENT_BINARY_DIR}/android/res/drawable/icon.png COPYONLY)
endif()

set(PROJECT_SOURCES main.cpp)
qt_add_executable(${PROJECT_NAME} MANUAL_FINALIZATION ${PROJECT_SOURCES}
    views/CallAPI.js
)

if (ANDROID)
    add_android_openssl_libraries(${PROJECT_NAME})
endif()

qt_add_resources(${PROJECT_NAME} "qml_resources"
    PREFIX "/"
    FILES
        main.qml
        components/BottomNavigation.qml
        views/HubView.qml
        views/QuizzesView.qml
        # views/DailyQuestionView.qml
        # views/DateIdeasView.qml
        views/LinkerView.qml
        views/ProfileView.qml
        views/LoginRegisterView.qml
        views/RegisterView.qml
        views/CallAPI.js
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
        images/icon.png
)

set_target_properties(${PROJECT_NAME} PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER com.anton.couplesapp
    MACOSX_BUNDLE_BUNDLE_NAME "Couples App"
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/mac/Info.plist
    PRODUCT_BUNDLE_IDENTIFIER com.anton.couplesapp
    WIN32_EXECUTABLE TRUE
)

if(ANDROID)
    set_target_properties(${PROJECT_NAME} PROPERTIES
        ANDROID_PACKAGE_NAME ${CMAKE_ANDROID_PACKAGE_NAME}
        ANDROID_ACTIVITY_NAME ${CMAKE_ANDROID_ACTIVITY_NAME}
        ANDROID_VERSION_CODE 1
    )
endif()

if(IOS)
    set(CMAKE_IOS_DEPLOYMENT_TARGET "17.5" CACHE STRING "Minimum iOS deployment version")
    set_target_properties(${PROJECT_NAME} PROPERTIES
        # XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "" # Set your Development Team ID here if needed
        XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED NO
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET ${CMAKE_IOS_DEPLOYMENT_TARGET}
    )
    set_source_files_properties(${APP_ICON} PROPERTIES
        MACOSX_PACKAGE_LOCATION "Resources"
    )
    set(RESOURCE_FILES ${APP_ICON})
    set_target_properties(${PROJECT_NAME} PROPERTIES
        RESOURCE "${RESOURCE_FILES}"
    )
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Core Qt6::Quick Qt6::QuickControls2)
qt_finalize_executable(${PROJECT_NAME})

if(ANDROID)
    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_SOURCE_DIR}/android")
    file(COPY "${CMAKE_SOURCE_DIR}/android/AndroidManifest.xml" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}/android")
endif()
