![usage](/pic/logo.jpg)
![usage](/pic/pic.png)

# BDSM (Bash Database SQL Manager)

Bash script to easily
- get DB credentials from your CMS/framework config file
- export DB,
- import DB,
- search in DB,
- search/replace in DB,
- pull database from remote server,
- and lot more. Look at the screenshot above!

# Supported engines
- WordPress
- Laravel
- Prestashop 1.6
- Prestashop 1.7
- ...

Please request your engine by creating new issue on Github! Give me your engine's config file example and I'll add it to the script. 👍

## Installation
Fast way (in one step). Worked on Mac, Linux and Windows (terminals with bash support)
```shell
eval "$(curl "https://raw.githubusercontent.com/michaelradionov/gg_installer/master/gg_installer.sh")" && gg_installer bdsm
```
Since BDSM can install other usefull scripts, you can install ALL OF THEM simply running
```
bdsm --install-all
```

## Usage

1. `cd` in website root directory
2. Execute `bdsm`
3. Follow instructions. Enjoy!
4. ~~💰 Donate~~. Nah! Just give this repo a star and I will appreciate it! ⭐️

## Requirements

- Bash support. Check by executing `bash --version`
- Mysql CLI support. Check by executing `mysql --version` and `mysqldump --version`
- cURL CLI support. Check by executing `curl --version`
- Sourcing ~/.bashrc file on session start. Check by:
    1. executing `echo 'echo "It works"' >> ~/.bashrc`
    2. then start new terminal session. If you see "It works!" then you good.
    3. Then **delete** this line from your ~/.bashrc.
- For the previous item. If you don't know where is ~/.bashrc, you should execute `cd` (without parameters), then `pwd`. Output will be your home path, it equals `~`.
- If you have literally ANY trouble with installing and using script, please, create an issue in Github repo https://github.com/michaelradionov/bdsm.
