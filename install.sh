#!/bin/bash
set -e

SCRIPT_URL='https://raw.githubusercontent.com/michaelradionov/wp_rehost/master/wp_rehost.sh'

# Красим
L_RED='\033[1;31m' # светло-красный цвет
L_GREEN='\033[1;32m' # светло-зелёный цвет
YELLOW='\033[1;33m' # жёлтый цвет
WHITE='\033[1;37m' # белый цвет
D_GREY='\033[1;30m' # тёмно-серый цвет
D_VIOL='\033[1;34m' # фиолетовый
NC='\033[0m' # нет цвета

check_command_exec_status () {
  if [ $1 -eq 0 ]
    then
      echo -e "${YELLOW}Выполнено успешно!${NC}"
      echo
      sleep 1
  else
    echo -e "${L_RED}ERROR${NC}"
    echo
  fi
}

echo 'Installing WPREHOST script...'

echo 'Making ~/.gg-tools directory for any Go Git Script'
mkdir ~/.gg-tools
check_command_exec_status $?

echo 'Copying script in wprehost.sh'
curl -s $SCRIPT_URL >> ~/.gg-tools/wprehost.sh
check_command_exec_status $?

echo "Making backup of your '~/.bashrc' in ~/.bashrc.backup"
cp ~/.bashrc ~/.bashrc.backup
check_command_exec_status $?

echo "Adding sourcing line in the end of your .bashrc"
echo '' >> ~/.bashrc
echo 'source ~/.gg-tools/wprehost.sh' >> ~/.bashrc
check_command_exec_status $?

echo ''
echo -e "Now restart your terminal or run this:"
echo ''
echo -e "${L_RED}source ~/.gg-tools/wprehost.sh${NC}";
echo ''
