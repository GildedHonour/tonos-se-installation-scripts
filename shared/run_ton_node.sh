#!/bin/sh
set -x
set -e


cd $HOME/ton-node_01
exec ton-node --config ./cfg_startup >> /var/log/ton-node.log 2>>/var/log/ton-node.err
