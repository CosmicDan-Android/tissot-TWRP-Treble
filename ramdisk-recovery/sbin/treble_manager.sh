#!/sbin/sh

chmod 777 /treble_manager/*
start treble_manager
sleep 1
kill `pidof recovery`
sleep 3
while kill -0 `pidof aroma`; do sleep 0.5; done
start recovery

