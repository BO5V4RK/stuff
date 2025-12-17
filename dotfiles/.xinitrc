#!/bin/sh

####################
#     monitors     #
####################
xrandr --output eDP-1 --mode 1920x1200 --rate 120.00
#xrandr --output HDMI-1 --mode 1360x768 --rate 60.00 --above eDP-1 &
#xrandr --output DP-1 --mode 1920x1080 --rate 60.00 --right-of eDP-1 &

####################
#    wallpaper     #
####################
feh --bg-fill --randomize ~/.wallpapers/* &

####################
#   transparency   #
####################
picom -b --config ~/.config/picom/picom.conf &

####################
#  startup_sound   #
####################
mplayer -ao alsa ~/Sounds/smooth-gadget-activation-sound-250072.mp3 &

####################
#    status_bar    #
####################
slstatus &

####################
#     brave        #
####################
#brave &

####################
#     ghostty      #
####################
#ghostty &

####################
#      DWM         #
####################
exec dwm
