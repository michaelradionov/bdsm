#!/bin/bash
# set -e

SCRIPT_URL='https://raw.githubusercontent.com/michaelradionov/wp_rehost/master/wp_rehost.sh'

# Colors
L_RED='\033[1;31m'
L_GREEN='\033[1;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
D_GREY='\033[1;30m'
D_VIOL='\033[1;34m'
NC='\033[0m'

check_command_exec_status () {
  if [ $1 -eq 0 ]
    then
      echo -e "${YELLOW}Success!${NC}"
      echo
  else
    echo -e "${L_RED}ERROR${NC}"
    echo
  fi
}

echo 'Installing WPREHOST script...'

if [ ! -d ~/.gg-tools/ ]; then
  echo 'Making ~/.gg-tools directory for any Go Git Script'
  mkdir ~/.gg-tools
  check_command_exec_status $?
fi

echo 'Copying script in wprehost.sh'
curl -s $SCRIPT_URL >> ~/.gg-tools/wprehost.sh
check_command_exec_status $?

echo "Making backup of your '~/.bashrc' in ~/.bashrc.backup"
cp ~/.bashrc ~/.bashrc.backup
check_command_exec_status $?

echo "Check for line 'source ~/.gg-tools/wprehost.sh' in your '~/.bashrc' file..."
isInstalled=`grep -n -e 'source ~/.gg-tools/wprehost.sh' ~/.bashrc | cut -d : -f 1`
if [[ ! $isInstalled ]]; then
  echo "Adding sourcing line at the end of your .bashrc"
  echo '' >> ~/.bashrc
  echo 'source ~/.gg-tools/wprehost.sh' >> ~/.bashrc
  check_command_exec_status $?
else
  echo 'Ok, it is installed already'
fi

echo ''
echo -e "Sourcing ~/.gg-tools/wprehost.sh"
source ~/.gg-tools/wprehost.sh
check_command_exec_status $?
