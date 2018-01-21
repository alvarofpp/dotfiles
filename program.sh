#!/bin/bash

# ---------
# FUNCTIONS
# ---------
function Main() {
  way=$( \
    zenity --list --text "What you want?" --radiolist \
    --column "pick" --column "options" \
    TRUE "Fix bugs" \
    FALSE "Programs" \
    FALSE "Languages" \
  );

  # Checks if user clicked "Cancel"
  if [ $? -eq 1 ];
  then
    exit 1
  fi

  # Redirects to the desired option
  if [ "$way" == "Fix bugs" ];
  then
    Bugs
  elif [ "$way" == "Programs" ];
  then
    Programs
  else
    Languages
  fi
}

function Bugs() {
  options=$( \
    zenity --list --title "Fix bugs" --checklist \
    --column "pick" --column "options" \
    TRUE "Double-click with touchpad" \
    FALSE "Input of sound not recognize" \
    --separator=":"\
  );
}

function Programs() {
  options=$( \
    zenity --list --title "Programs" --text "Select the programs you prefer" --checklist \
    --column "pick" --column "options" \
    FALSE "Git" \
    FALSE "PHP" \
    FALSE "Python" \
    FALSE "R" \
    --separator=":"\
  );
}

function Languages() {
  options=$( \
    zenity --list --title "Languages" --text "Select the languages you prefer" --checklist \
    --column "pick" --column "options" \
    FALSE "Git" \
    FALSE "PHP" \
    FALSE "Python" \
    FALSE "R" \
    --separator=":"\
  );
}

# ---------
# CODE
# ---------

Main
