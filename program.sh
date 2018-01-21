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
    TRUE "Double-click with touchpad" \
    FALSE "Input of sound not recognize" \
    --separator=":"\
  );
}


# --------
# Programs
# --------
function Programs() {
  options=$( \
    zenity --list --title "Programs" --text "Select the programs you prefer" --checklist \
    --column "select" --column "options" \
    TRUE "Git" \
    TRUE "Spotify" \
    FALSE "PHPStorm" \
    FALSE "DataGrip" \
    FALSE "Anaconda" \
    FALSE "PGAdmin" \
    --separator=":"\
  );
}


# ---------
# Languages
# ---------
function Languages() {
  options=$( \
    zenity --list --title "Programming languages" --text "Select the languages you prefer" --checklist \
    --column "select" --column "options" \
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
