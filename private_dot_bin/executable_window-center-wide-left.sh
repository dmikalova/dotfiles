#!/bin/sh

WIN=$(xdotool getwindowfocus)
xdotool windowsize "${WIN}" 80% 100%
xdotool windowmove "${WIN}" 0% 0%
