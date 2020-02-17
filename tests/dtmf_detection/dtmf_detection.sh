#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

./utils/dtmf2wav.py 0123456789 digits.wav > /dev/null

gst-launch-1.0 -m filesrc location=./digits.wav ! decodebin ! audioresample ! audioconvert ! dtmfdetect ! filesink location=./digits2.wav | grep dtmf-event

