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
    FALSE "Programs and others" \
    FALSE "Programming" \
  );

  # Checks if user clicked "Cancel"
  if [ $? -eq 1 ]; then
    exit 1
  fi

  # Redirects to the desired option
  if [ "$way" == "Fix bugs" ]; then
    Bugs
  elif [ "$way" == "Programs and others" ]; then
    ProgramsOthers
  else
    Programming
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
    --separator=":" \
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
function ProgramsOthers() {
  options=$( \
    zenity --list --title "Programs" --text "Select the programs you prefer" --checklist \
    --column "select" --column "options" \
    FALSE "Git" \
    FALSE "Sound control" \
    FALSE "Spotify" \
    FALSE "Tex live" \
    FALSE "Texmaker" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Git") Git ;;
      "Sound control") SoundControl ;;
      "Spotify") Spotify ;;
      "Tex live") TexLive ;;
      "Texmaker") Texmaker ;;
    esac
  done
  IFS=""
}

function Git() {
  sudo apt-get update
  echo "Installing Git"
  sudo apt-get install git
  echo "(Git) Successfully installed"
}

function SoundControl() {
  sudo apt-get update
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

function TexLive() {
  sudo apt-get update
  echo "Installing Tex Live"
  sudo apt-get install texlive-full
  echo "(Tex live) Successfully installed"
}

function Texmaker() {
  sudo apt-get update
  echo "Installing Texmaker"
  sudo apt-get install texmaker
  echo "(Texmaker) Successfully installed"
}


# ---------
# Programming
# ---------
function Programming() {
  options=$( \
    zenity --list --title "Programming languages" --text "Select the languages you prefer" --checklist \
    --column "select" --column "options" \
    FALSE "Node.js" \
    FALSE "Java 8" \
    FALSE "Postgres" \
    FALSE "PHP" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Node.js") Nodejs ;;
      "Java 8") Java8 ;;
      "Postgres") Postgres ;;
      "PHP") PHP ;;
    esac
  done
  IFS=""
}

function PHP() {
  sudo apt-get update
  echo "Input PPA"
  sudo apt-add-repository ppa:ondrej/php -y
  echo "Installing PHP 7.1"
  sudo apt-get install -y --force-yes php7.1-cli php7.1 \
  php7.1-pgsql php7.1-sqlite3 php7.1-gd \
  php7.1-curl php7.1-memcached \
  php7.1-imap php7.1-mysql php7.1-mbstring \
  php7.1-xml php7.1-zip php7.1-bcmath php7.1-soap \
  php7.1-intl php7.1-readline
  echo "Installing Apache 2"
  sudo apt-get install apache2
  echo "Installing Curl"
  sudo apt-get install curl
  echo "Installing Composer"
  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer
  echo "(PHP) Successfully installed"
}

function Postgres() {
  sudo apt-get update
  echo "Installing PHP 7.1"
  sudo apt-get install postgresql postgresql-contrib
  echo "(Postgres) Successfully installed"
}

function Nodejs() {
  sudo apt-get update
  echo "Installing NPM"
  sudo apt-get install npm
  echo "Installing Node.js"
  sudo apt-get install nodejs
  echo "(Node.js) Successfully installed"
}

function Java8() {
  sudo apt-get update
  echo "Adding Oracle PPA"
  sudo add-apt-repository ppa:webupd8team/java
  sudo apt-get update
  echo "Installing Java 8"
  sudo apt-get install oracle-java8-installer
  echo "(Java 8) Successfully installed"
}


# --------
# | CODE |
# --------

Main
