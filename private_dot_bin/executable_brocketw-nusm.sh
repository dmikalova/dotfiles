#!/bin/sh

-c google-chrome-stable "Google Chrome"
WIN=$(xdotool getwindowfocus)
xdotool windowsize "${WIN}" 767 100%
xdotool windowmove "${WIN}" 0% 0%
