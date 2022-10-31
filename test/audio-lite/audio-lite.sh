#!/bin/bash

set -e

source dev-container-features-test-lib

check "Mumble is running" service mumble-server status
check "Pulseaudio is running" pulseaudio --check
check "mumd is running" kill -0 $(pidof mumd)

reportResults