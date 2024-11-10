#!/bin/bash

# change supervisor socket file
sed -i 's|/var/run/supervisor.sock|/u01/socket/supervisor.sock|g' /etc/supervisor/supervisord.conf

supervisord -n