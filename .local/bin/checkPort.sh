#!/bin/zsh

lsof -nP -iTCP -sTCP:LISTEN | grep $1
