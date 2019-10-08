#!/bin/sh

if [ "${TRAVIS_OS_NAME}" = "linux" ]; then
  SWIFT_VERSION_NUMBER=5.1
  SWIFT_PLATFORM=ubuntu16.04
  SWIFT_BRANCH=swift-${SWIFT_VERSION_NUMBER}-release
  SWIFT_VERSION=swift-${SWIFT_VERSION_NUMBER}-RELEASE

  echo "Downloading the Swift ${SWIFT_VERSION_NUMBER} toolchain..."
  wget https://swift.org/builds/${SWIFT_BRANCH}/$(echo ${SWIFT_PLATFORM} | tr -d .)/${SWIFT_VERSION}/${SWIFT_VERSION}-${SWIFT_PLATFORM}.tar.gz
  tar xzf ${SWIFT_VERSION}-${SWIFT_PLATFORM}.tar.gz
  export PATH="${TRAVIS_BUILD_DIR}"/${SWIFT_VERSION}-${SWIFT_PLATFORM}/usr/bin:"${PATH}"
fi

echo "Using Swift version:"
swift -version

echo "Building package..."
swift build