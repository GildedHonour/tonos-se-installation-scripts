#!/bin/sh
set -x
set -e


base_path=$HOME/ton-node_01
cd $base_path
exec ton_node_startup --config ./cfg_startup >> $base_path/ton-node.log 2>>$base_path/ton-node.err
