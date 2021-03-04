#!/bin/sh
set -x
set -e

export Q_DATA_MUT=http://127.0.0.1:8529
export Q_DATA_HOT=${Q_DATA_MUT}
export Q_SLOW_QUERIES_MUT=${Q_DATA_MUT}
export Q_SLOW_QUERIES_HOT=${Q_DATA_MUT}
export Q_REQUESTS_MODE=rest
export Q_REQUESTS_SERVER=http://127.0.0.1
export Q_HOST=127.0.0.1
export Q_PORT=4000

cd $HOME/ton-q-server
exec node index.js