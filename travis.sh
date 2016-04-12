#!/usr/bin/env bash

set -e

xctool -project PersistentObject.xcodeproj -scheme "PersistentObject Mac" test
xctool -project PersistentObject.xcodeproj -scheme "PersistentObject iOS" -sdk iphonesimulator9.3 -destination "platform=iOS Simulator,name=iPhone 6" test