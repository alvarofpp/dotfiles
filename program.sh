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
  printTerminal green "Correcting clicks with the touchpad"
  synclient TapButton1=1 TapButton2=3 TapButton3=2
  printTerminal red "Corrected"
}


# --------
# Programs
# --------
function ProgramsOthers() {
  options=$( \
    zenity --list --title "Programs" --text "Select the programs you prefer" --checklist \
    --column "select" --column "options" \
    FALSE "Git" \
    FALSE "RStudio" \
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
      "RStudio") RStudio ;;
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
  printTerminal start "Git"
  sudo apt-get install git
  printTerminal finish "Git"
}

function RStudio() {
  printTerminal start "RStudio"
  sudo apt-get install gdebi-core
  wget https://download2.rstudio.org/rstudio-server-1.1.423-amd64.deb
  sudo gdebi rstudio-server-1.1.423-amd64.deb
  printTerminal finish "RStudio"
}

function SoundControl() {
  sudo apt-get update
  printTerminal green "Installing program for sound control"
  sudo apt-get install pavucontrol
  printTerminal finish "Sound control"
}

function Spotify() {
  printTerminal green "Adding the Spotify repository signing keys to be able to verify downloaded packages"
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 931FF8E79F0876134EDDBDCCA87FF9DF48BF1C90
  printTerminal green "Adding the Spotify repository"
  echo deb http://repository.spotify.com stable non-free | sudo tee /etc/apt/sources.list.d/spotify.list
  printTerminal green "Updating list of available packages"
  sudo apt-get update
  printTerminal start "Spotify"
  sudo apt-get install spotify-client
  printTerminal finish "Spotify"
}

function TexLive() {
  sudo apt-get update
  printTerminal start "Tex Live"
  sudo apt-get install texlive-full
  printTerminal finish "Tex live"
}

function Texmaker() {
  sudo apt-get update
  printTerminal start "Texmaker"
  sudo apt-get install texmaker
  printTerminal finish "Texmaker"
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
    FALSE "Postgres + PGAdmin3" \
    FALSE "PHP + Laravel" \
    FALSE "R-base" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Node.js") Nodejs ;;
      "Java 8") Java8 ;;
      "Postgres + PGAdmin3") Postgres ;;
      "PHP + Laravel") PHPLaravel ;;
      "R-base") Rbase ;;
    esac
  done
  IFS=""
}

function PHPLaravel() {
  sudo apt-get update
  printTerminal green "Adding PPA"
  sudo apt-add-repository ppa:ondrej/php -y
  printTerminal start "PHP 7.2"
  sudo apt-get install php-mbstring
  sudo apt-get install composer -y
  sudo apt-get install php7.2-pgsql -y
  sudo apt-get install apache2 libapache2-mod-php7.2 -y
  sudo apt-get install php7.2-dev -y
  sudo apt-get install php7.2-zip -y
  sudo apt-get install php7.2-xml -y
  sudo apt-get install php7.2-mbstring -y
  sudo apt-get install php7.2-cgi -y
  sudo apt-get install php7.2-curl -y
  sudo apt-get install php7.2-zip
  printTerminal start "Curl"
  sudo apt-get install curl php-curl
  printTerminal finish "Curl"
  printTerminal start "Composer"
  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
  printTerminal finish "Curl"
  printTerminal finish "(PHP 7.2)"

  composer global require "laravel/installer"
  export PATH=$PATH:$HOME/.config/composer/vendor/bin
  printTerminal finish "Laravel"
}

function Postgres() {
  sudo apt-get update
  printTerminal start "PostgreSQL + PGAdmin3"
  sudo apt-get install postgresql postgresql-contrib pgadmin3
  printTerminal finish "PostgreSQL + PGAdmin3"
}

function Nodejs() {
  sudo apt-get update
  printTerminal start "NPM"
  sudo apt-get install npm
  printTerminal start "Node.js"
  sudo apt-get install nodejs
  printTerminal finish "Node.js"
}

function Java8() {
  sudo apt-get update
  printTerminal green "Adding Oracle PPA"
  sudo add-apt-repository ppa:webupd8team/java
  sudo apt-get update
  printTerminal start "Java 8"
  sudo apt-get install oracle-java8-installer
  printTerminal finish "Java 8"
}

function Rbase() {
  printTerminal green "Add repository CRAN"
  sudo add-apt-repository 'deb [arch=amd64,i386] https://cran.rstudio.com/bin/linux/ubuntu xenial/'
  sudo apt-get update
  printTerminal start "R-base"
  sudo apt-get install r-base
  printTerminal finish "R-base"
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
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Jupyter") Jupyter ;;
      "Jupyter Lab") JupyterLab ;;
      "Jupyter Nbextensions Configurator") JupyterNbextensionsConfigurator ;;
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


# --------
# | CODE |
# --------

Main
