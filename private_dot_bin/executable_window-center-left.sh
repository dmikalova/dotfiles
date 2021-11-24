#!/bin/sh

WIN=$(xdotool getwindowfocus)
xdotool windowsize "${WIN}" 70% 100%
xdotool windowmove "${WIN}" 0% 0%
