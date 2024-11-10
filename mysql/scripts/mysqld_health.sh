#!/bin/bash

HOST="127.0.0.1"
PORT="3306"

function check_mysqld_health() {
    timeout 1 bash -c "cat < /dev/null > /dev/tcp/$HOST/$PORT"
}

check_mysqld_health