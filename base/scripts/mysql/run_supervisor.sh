#!/bin/bash

# change supervisor socket file
sed -i 's|/var/run/supervisor.sock|/kdb/socket/supervisor.sock|g' /etc/supervisor/supervisord.conf

supervisord -n