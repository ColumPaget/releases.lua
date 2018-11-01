SYNOPSIS
========

A lua script that grabs recent releases RSS feeds from fossies.org and freshcode.club, and outputs them at the text console. A limit can be placed on the number or days results returned. A list of package names can be specified on the command line to check for those particular packages.

LICENSE
=======

This script is released under the Gnu Public License version 3

DEPENDANCIES
============

libUseful (https://github.com/ColumPaget/libUseful) and libUseful-lua (https://github.com/ColumPaget/libUseful-lua) will need to be installed.

USAGE
=====

```
   lua releases.lua [options]                            - display latest releases
   lua releases.lua watch [options] [name] [name] ...    - display releases of named packages
   lua releases.lua help                                 - display this help

options:
   -days <n>      - show results for the last 'n' days
   -notext        - do not show text description of package
   -?             - show this help
   -h             - show this help
   -help          - show this help
   --help         - show this help
```

EXAMPLES
========

```
   lua releases.lua -days 2                - show releases for the last two days
   lua releases.lua -days 1 -notext        - show releases for the last 24 hours without descriptions
   lua releases.lua watch wine strace      - show releases for the programs 'wine' and 'strace'
```
