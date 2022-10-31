#!/bin/bash

set -e

source dev-container-features-test-lib

sleep 5

check "Mumble is running" kill -0 $(pidof murmurd)
check "Pulseaudio is running" kill -0 $(pidof pulseaudio)
check "mumd is running" kill -0 $(pidof mumd)

reportResults