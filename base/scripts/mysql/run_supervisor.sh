#!/bin/bash

# change supervisor socket file
sed -i 's|/var/run/supervisor.sock|/kdbdata/socket/supervisor.sock|g' /etc/supervisor/supervisord.conf

supervisord -n