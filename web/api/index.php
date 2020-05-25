<?php

header("Content-Type: text/plain");

echo '
------------------------------------------------------------------------------
General endpoints:
------------------------------------------------------------------------------

GET /
GET /mobro
    the MoBro configuration page

GET /version
    returns: the current version number

GET /log
    returns: the current logfile (from this boot)
    params (optional):
      lines: only return the most recent n lines
      count: include log files of previous n boots (max = 10, default = 0)

------------------------------------------------------------------------------
API endpoints:
------------------------------------------------------------------------------

GET  /api
     returns: this page

GET  /api/temp
     returns: the current CPU temperature

GET  /api/top
     returns: the output of the "top" command. i.e.: CPU/RAM Usage, Processes...

POST /api/restart
     restarts the Raspberry Pi
     params (optional):
       delay: delay in minutes before restart (default = 0)

POST /api/shutdown
     shuts down the Raspberry Pi
     params (optional):
       delay: delay in minutes before shutdown (default = 0)
';