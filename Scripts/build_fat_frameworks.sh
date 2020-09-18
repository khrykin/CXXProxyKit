#!/bin/sh

PROJECT="$1"
BUILD_DIR="$2"

FRAMEWORK_NAME=CXXProxyKit

IOS_SCHEME="$FRAMEWORK_NAME"
MACOS_SCHEME="${FRAMEWORK_NAME}MacOS"

# make sure the output directory exists
mkdir -p "${FAT_DIR}" > /dev/null 2>&1

dataPath=$BUILD_DIR/tmp

simulatorSdk=iphonesimulator
simulatorDataPath=$BUILD_DIR/$simulatorSdk

echo "*** Building iOS Framework... ***"

xcodebuild -quiet\
    BITCODE_GENERATION_MODE=bitcode \
    OTHER_CFLAGS="-fembed-bitcode" \
    -project "$PROJECT" \
    -scheme "$IOS_SCHEME" \
    ONLY_ACTIVE_ARCH=NO \
    -configuration "Release" \
    -derivedDataPath "${dataPath}/iphoneos" \
    -sdk "iphoneos" \
    clean build

echo "*** Building Simulator Framework... ***"

xcodebuild -quiet\
    BITCODE_GENERATION_MODE=bitcode \
    OTHER_CFLAGS="-fembed-bitcode" \
    -project "$PROJECT" \
    -scheme "$IOS_SCHEME" \
    ONLY_ACTIVE_ARCH=NO \
    -configuration "Release" \
    -derivedDataPath "${dataPath}/iphonesimulator" \
    -sdk "iphonesimulator" \
    clean build

echo "*** Building MacOS Framework... ***"

xcodebuild -quiet\
    BITCODE_GENERATION_MODE=bitcode \
    OTHER_CFLAGS="-fembed-bitcode" \
    -project "$PROJECT" \
    -scheme "$MACOS_SCHEME" \
    ONLY_ACTIVE_ARCH=NO \
    -configuration "Release" \
    -derivedDataPath "${dataPath}/macosx" \
    -sdk "macosx" \
    clean build

IOS_FRAMEWORK_PATH="${dataPath}/iphoneos/Build/Products/Release-iphoneos/$FRAMEWORK_NAME.framework/"
SIMUTATOR_FRAMEWORK_PATH="${dataPath}/iphoneos/Build/Products/Release-iphonesimulator/$FRAMEWORK_NAME.framework/"

IOS_BINARY_PATH="$IOS_FRAMEWORK_PATH/$FRAMEWORK_NAME"
SIMUTATOR_BINARY_PATH="$SIMUTATOR_FRAMEWORK_PATH/$FRAMEWORK_NAME"

SIMULATOR_SWIFT_MODULES_DIR="$SIMUTATOR_FRAMEWORK_PATH/Modules/$FRAMEWORK_NAME.swiftmodule/."

FAT_IOS_FRAMEWORK_PATH="$BUILD_DIR/${FRAMEWORK_NAME}.framework"

MACOS_BINARY_PATH="${dataPath}/macosx/Build/Products/Release/$FRAMEWORK_NAME.framework/$FRAMEWORK_NAME"



echo "*** Creating Fat iOS Framework... ***"

# Copy Swift modules from iphonesimulator build (if it exists) to the copied framework directory
if [ -d "$SIMULATOR_SWIFT_MODULES_DIR" ]; then
    cp -R "$SIMULATOR_SWIFT_MODULES_DIR" "$IOS_FRAMEWORK_PATH/Modules/$FRAMEWORK_NAME.swiftmodule"
fi

# Create universal binary file using lipo
lipo \
    -create $IOS_BINARY_PATH $SIMUTATOR_BINARY_PATH \
    -output $IOS_FRAMEWORK_PATH/$FRAMEWORK_NAME

cp -R $IOS_FRAMEWORK_PATH $FAT_IOS_FRAMEWORK_PATH

# update Info.plist
/usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms: string iPhoneSimulator" "$FAT_IOS_FRAMEWORK_PATH/Info.plist"

rm -r "$dataPath"

open "$BUILD_DIR"

#createFatFramework() {
#    local frameworkName=$1
#    local frameworkWithFormat=$1.framework
#    local deviceFramework=$2
#    local simFramework=$3
#    local outputDir=$4
#
#
#    # create fat binary
#    lipo \
#    -create $simFramework/$frameworkName $deviceFramework/$frameworkName \
#    -output $outputDir/$frameworkName
#
#    # prepare fat-framework
#    [ -d $outputDir/$frameworkWithFormat ] && rm -r $outputDir/$frameworkWithFormat
#    cp -r $deviceFramework $outputDir
#
#    # replace an original binary with just created one
#    rsync --remove-source-files -azv $outputDir/$frameworkName $outputDir/$frameworkWithFormat
#
#    # update Info.plist
#    /usr/libexec/PlistBuddy -c "Add :CFBundleSupportedPlatforms: string iPhoneSimulator" "${outputDir}/${frameworkWithFormat}/Info.plist"
#
#    # copy simulator architectures
#    cp -R $simFramework/Modules/$frameworkName.swiftmodule/. $outputDir/$frameworkWithFormat/Modules/$frameworkName.swiftmodule/
#}
#
#shift 8
#
#while (( "$#" ));
#do
#	framework=$1
#	echo "*** Building ${framework}... ***"
#	buildFramework ${framework}
#	echo "*** BUILD ${framework} SUCCESS ***"
#
#
#    echo "*** Creating fat-framework ${framework}... ***"
#    deviceFramework=$dataPath/${framework}/Build/Products/$CONFIGURATION-$SDK/${framework}.framework
#    simFramework=$simulatorDataPath/${framework}/Build/Products/$CONFIGURATION-$simulatorSdk/${framework}.framework
#
#    createFatFramework "${framework}" "${deviceFramework}" "${simFramework}" "${FAT_DIR}"
#    echo "*** Creating fat-framework ${framework} SUCCESS ***"
#
#shift
#done
