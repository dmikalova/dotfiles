#!/bin/sh

WIN=$(xdotool getwindowfocus)
xdotool windowsize "${WIN}" 30% 50%
xdotool windowmove "${WIN}" 70% 0%