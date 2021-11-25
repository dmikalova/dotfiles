#!/bin/sh

wmctrl -r :ACTIVE: -b remove,maximized_vert
wmctrl -r :ACTIVE: -b remove,maximized_horz
WIN=$(xdotool getwindowfocus)
xdotool windowsize "${WIN}" 30% 50%
xdotool windowmove "${WIN}" 0% 0%
