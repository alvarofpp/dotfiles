#!/bin/bash

# -------------
# | FUNCTIONS |
# -------------
# Remove warning of the Gtk-Message
function zenity() {
    /usr/bin/zenity "$@" 2>/dev/null
}

# Cores
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m'

function Main() {
  way=$( \
    zenity --list --text "What you want?" --radiolist \
    --column "pick" --column "options" \
    TRUE "Fix bugs" \
    FALSE "Programs and others" \
    FALSE "Programming" \
    FALSE "Anaconda" \
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
  elif [ "$way" == "Anaconda" ]; then
    Anaconda
  else
    Programming
  fi
}

# Função para imprimir o inicio e fim de uma instalação
function printTerminal() {
  case $1 in
    "red") printf "${RED}$2${NC}\n" ;;
    "green") printf "${GREEN}$2${NC}\n" ;;
    "start") printf "${GREEN}Installing $2${NC}\n" ;;
    "finish") printf "${RED}($2) Successfully installed${NC}\n" ;;
  esac
}


# ----
# Bugs
# ----
function Bugs() {
  options=$( \
    zenity --list --title "Fix bugs" --checklist \
    --column "select" --column "options" \
    FALSE "Unrecognized clicks with touchpad" \
    False "Right click touchpad not working" \
    --separator=":" \
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Unrecognized clicks with touchpad") ClickTouchpad ;;
      "Right click touchpad not working") RightClick ;;
    esac
  done
  IFS=""
}

function ClickTouchpad() {
  printTerminal green "Correcting clicks with the touchpad"
  synclient TapButton1=1 TapButton2=3 TapButton3=2
  printTerminal red "Corrected"
}

function RightClick() {
  printTerminal green "Correcting right click touchpad"
  printTerminal start "GNOME Tweak Tool"
  sudo apt install -y gnome-tweak-tool
  printTerminal finish "GNOME Tweak Tool"
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
    FALSE "Sublime Text" \
    FALSE "Tex live" \
    FALSE "Texmaker" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Git") Git ;;
      "RStudio") RStudio ;;
      "Sound control") SoundControl ;;
      "Spotify") Spotify ;;
      "Sublime Text") SublimeText ;;
      "Tex live") TexLive ;;
      "Texmaker") Texmaker ;;
    esac
  done
  IFS=""
}

function Git() {
  sudo apt update
  printTerminal start "Git"
  sudo apt install -y git
  printTerminal finish "Git"
}

function SoundControl() {
  sudo apt update
  printTerminal green "Installing program for sound control"
  sudo apt install -y pavucontrol
  printTerminal finish "Sound control"
}

function Spotify() {
  printTerminal green "Adding the Spotify repository signing keys to be able to verify downloaded packages"
  curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add -
  printTerminal green "Adding the Spotify repository"
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  printTerminal start "Spotify"
  sudo apt update && sudo apt install -y spotify-client
  printTerminal finish "Spotify"
}

function SublimeText() {
  printTerminal green "Install the GPG key"
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  printTerminal green "Channel stable to use"
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  printTerminal green "Updating list of available packages"
  sudo apt update
  printTerminal start "Sublime Text"
  sudo apt install -y sublime-text
  printTerminal finish "Sublime Text"
}

function TexLive() {
  sudo apt update
  printTerminal start "Tex Live"
  sudo apt install -y texlive-full
  printTerminal finish "Tex live"
}

function Texmaker() {
  sudo apt update
  printTerminal start "Texmaker"
  sudo apt install -y texmaker
  printTerminal finish "Texmaker"
}


# ---------
# Programming
# ---------
function Programming() {
  options=$( \
    zenity --list --title "Programming languages" \
    --text "Select the languages you prefer" --checklist \
    --column "select" --column "options" \
    FALSE "Java 12" \
    FALSE "Postgres + PGAdmin3" \
    FALSE "PHP 7.4 + Laravel" \
    FALSE "Python 3.8" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Node.js") Nodejs ;;
      "Java 12") Java ;;
      "Postgres + PGAdmin3") Postgres ;;
      "PHP 7.4 + Laravel") PHPLaravel ;;
      "Python 3.8") Python ;;
      "R-base") Rbase ;;
    esac
  done
  IFS=""
}

function Java() {
  sudo apt update
  printTerminal green "Adding Oracle PPA"
  sudo add-apt-repository ppa:linuxuprising/java
  sudo apt update
  printTerminal start "Java 12"
  sudo apt install -y oracle-java12-installer
  sudo apt install -y oracle-java12-set-default
  printTerminal finish "Java 12"
}

function Postgres() {
  sudo apt update
  printTerminal start "PostgreSQL + PGAdmin3"
  sudo apt install -y postgresql postgresql-contrib pgadmin3
  printTerminal finish "PostgreSQL + PGAdmin3"
}

function PHPLaravel() {
  sudo apt update
  printTerminal green "Adding PPA"
  sudo apt-add-repository ppa:ondrej/php -y
  printTerminal start "PHP 7.4"
  sudo apt install -y php-mbstring
  sudo apt install -y composer -y
  sudo apt install -y php7.4-pgsql -y
  sudo apt install -y apache2 libapache2-mod-php7.4 -y
  sudo apt install -y php7.4-dev -y
  sudo apt install -y php7.4-zip -y
  sudo apt install -y php7.4-xml -y
  sudo apt install -y php7.4-mbstring -y
  sudo apt install -y php7.4-cgi -y
  sudo apt install -y php7.4-curl -y
  sudo apt install -y php7.4-zip
  printTerminal start "Curl"
  sudo apt install -y curl php-curl
  printTerminal finish "Curl"
  printTerminal start "Composer"
  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
  printTerminal finish "Curl"
  printTerminal finish "PHP 7.4"

  composer global require "laravel/installer"
  export PATH=$PATH:$HOME/.config/composer/vendor/bin
  printTerminal finish "Laravel"
}

function Python() {
  sudo apt update
  printTerminal green "Installing the prerequisites"
  sudo apt install -y software-properties-common
  printTerminal green "Add the deadsnakes PPA to your sources list"
  sudo add-apt-repository ppa:deadsnakes/ppa
  printTerminal start "Python 3.8"
  sudo apt install -y python3.8
  printTerminal finish "Python 3.8"
}


# ---------
# Anaconda
# ---------
function Anaconda() {
  options=$( \
    zenity --list --title "Anaconda" --text "Extensions and more" --checklist \
    --column "select" --column "options" \
    FALSE "Jupyter" \
    FALSE "Jupyter Lab" \
    FALSE "Jupyter Nbextensions Configurator" \
    FALSE "Jupyter Themes" \
    FALSE "Python packages for data science" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Jupyter") Jupyter ;;
      "Jupyter Lab") JupyterLab ;;
      "Jupyter Nbextensions Configurator") JupyterNbextensionsConfigurator ;;
      "Jupyter Themes") JupyterThemes ;;
      "Python packages for data science") PythonPackages ;;
    esac
  done
  IFS=""
}

function Jupyter() {
  printTerminal start "Jupyter"
  conda install -c conda-forge jupyter
  printTerminal finish "Jupyter"
}

function JupyterLab() {
  printTerminal start "Jupyter Lab"
  conda install -c conda-forge jupyterlab
  printTerminal finish "Jupyter Lab"
}

function JupyterNbextensionsConfigurator() {
  printTerminal start "Jupyter Nbextensions Configurator"
  conda install -c conda-forge jupyter_contrib_nbextensions
  conda install -c conda-forge jupyter_nbextensions_configurator
  printTerminal finish "Jupyter Nbextensions Configurator"
}

function JupyterThemes() {
  printTerminal start "Jupyter Themes"
  mkdir -p $(jupyter --data-dir)/nbextensions
  cd $(jupyter --data-dir)/nbextensions
  mkdir jupyter_themes && cd jupyter_themes
  wget https://raw.githubusercontent.com/merqurio/jupyter_themes/master/theme_selector.js
  cd ../ && jupyter nbextension enable jupyter_themes/theme_selector
  printTerminal finish "Jupyter Themes"
}

function PythonPackages() {
  printTerminal start "Python packages"
  conda install -c conda-forge numpy
  conda install -c conda-forge matplotlib
  conda install -c conda-forge pandas
  printTerminal finish "Python packages"
}


# --------
# | CODE |
# --------

Main
