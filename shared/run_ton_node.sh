#!/bin/sh
set -x
set -e


local _base_path=$HOME/ton-node_01
cd $_base_path
exec ton_node_startup --config ./cfg_startup >> $_base_path/ton-node.log 2>>$_base_path/ton-node.err
