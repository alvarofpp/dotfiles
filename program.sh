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
  sudo apt install gnome-tweak-tool
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
      "Sublime Text") SublimeText ;;
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
  curl -sS https://download.spotify.com/debian/pubkey.gpg | sudo apt-key add -
  printTerminal green "Adding the Spotify repository"
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  printTerminal start "Spotify"
  sudo apt-get update && sudo apt-get install spotify-client
  printTerminal finish "Spotify"
}

function SublimeText() {
  printTerminal green "Install the GPG key"
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  printTerminal green "Channel stable to use"
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  printTerminal green "Updating list of available packages"
  sudo apt-get update
  printTerminal start "Sublime Text"
  sudo apt-get install sublime-text
  printTerminal finish "Sublime Text"
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
    FALSE "Java 12" \
    FALSE "Postgres + PGAdmin3" \
    FALSE "PHP + Laravel" \
    FALSE "R-base" \
    --separator=":"\
  );

  IFS=":"
  for opt in $options; do
    case $opt in
      "Node.js") Nodejs ;;
      "Java 12") Java12 ;;
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
  printTerminal start "PHP 7.3"
  sudo apt-get install php-mbstring
  sudo apt-get install composer -y
  sudo apt-get install php7.3-pgsql -y
  sudo apt-get install apache2 libapache2-mod-php7.3 -y
  sudo apt-get install php7.3-dev -y
  sudo apt-get install php7.3-zip -y
  sudo apt-get install php7.3-xml -y
  sudo apt-get install php7.3-mbstring -y
  sudo apt-get install php7.3-cgi -y
  sudo apt-get install php7.3-curl -y
  sudo apt-get install php7.3-zip
  printTerminal start "Curl"
  sudo apt-get install curl php-curl
  printTerminal finish "Curl"
  printTerminal start "Composer"
  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
  printTerminal finish "Curl"
  printTerminal finish "(PHP 7.3)"

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

function Java12() {
  sudo apt-get update
  printTerminal green "Adding Oracle PPA"
  sudo add-apt-repository ppa:linuxuprising/java
  sudo apt update
  printTerminal start "Java 12"
  sudo apt install oracle-java12-installer
  sudo apt install oracle-java12-set-default
  printTerminal finish "Java 12"
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
