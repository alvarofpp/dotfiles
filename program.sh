#!/bin/bash

# -------------
# | FUNCTIONS |
# -------------
# Remove warning of the Gtk-Message
function zenity() {
    /usr/bin/zenity "$@" 2>/dev/null
}

function Main() {
  way=$( \
    zenity --list --text "What you want?" --radiolist \
    --column "pick" --column "options" \
    TRUE "Fix bugs" \
    FALSE "Programs" \
    FALSE "Programming languages" \
  );

  # Checks if user clicked "Cancel"
  if [ $? -eq 1 ]; then
    exit 1
  fi

  # Redirects to the desired option
  if [ "$way" == "Fix bugs" ]; then
    Bugs
  elif [ "$way" == "Programs" ]; then
    Programs
  else
    Languages
  fi
}


# ----
# Bugs
# ----
function Bugs() {
  options=$( \
    zenity --list --title "Fix bugs" --checklist \
    --column "select" --column "options" \
    FALSE "Unrecognized clicks with touchpad" \
    FALSE "Unrecognized sound input" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Unrecognized clicks with touchpad") ClickTouchpad ;;
    esac
  done
  IFS=""
}

function ClickTouchpad() {
  echo "Correcting clicks with the touchpad."
  synclient TapButton1=1 TapButton2=3 TapButton3=2
  echo "Corrected."
}


# --------
# Programs
# --------
function Programs() {
  options=$( \
    zenity --list --title "Programs" --text "Select the programs you prefer" --checklist \
    --column "select" --column "options" \
    FALSE "Git" \
    FALSE "Sound control" \
    FALSE "Spotify" \
    FALSE "Sublime Text" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Git") Git ;;
      "Sound control") SoundControl ;;
      "Spotify") Spotify ;;
    esac
  done
  IFS=""
}

function Git() {
  echo "Installing Git"
  sudo apt-get install git
  echo "(Git) Successfully installed"
}

function SoundControl() {
  echo "Installing program for sound control"
  sudo apt-get install pavucontrol
  echo "(Sound control) Successfully installed"
}

function Spotify() {
  echo "Adding the Spotify repository signing keys to be able to verify downloaded packages"
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 0DF731E45CE24F27EEEB1450EFDC8610341D9410
  echo "Adding the Spotify repository"
  echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
  echo "Updating list of available packages"
  sudo apt-get update
  echo "Installing Spotify"
  sudo apt-get install spotify-client
  echo "(Spotify) Successfully installed"
}


# ---------
# Languages
# ---------
function Languages() {
  options=$( \
    zenity --list --title "Programming languages" --text "Select the languages you prefer" --checklist \
    --column "select" --column "options" \
    FALSE "Java" \
    FALSE "PHP" \
    FALSE "Python" \
    FALSE "R" \
    --separator=":"\
  );
}


# --------
# | CODE |
# --------

Main
