#!/bin/sh

set -xe

rsync -mvah --progress --delete ~/Documents /Volumes/rs_hdd/
rsync -mvah --progress --delete ~/Downloads /Volumes/rs_hdd/

IP="192.168.1.10"
PORT="873"
MOUNT="backup"
rsync -mavh --size-only --progress /Volumes/rs_hdd/Pictures rsync://${IP}:${PORT}/${MOUNT}/
rsync -mavh --size-only --progress /Volumes/rs_hdd/Documents rsync://${IP}:${PORT}/${MOUNT}/
rsync -mavh --size-only --progress /Volumes/rs_hdd/Downloads rsync://${IP}:${PORT}/${MOUNT}/
rsync -mavh --size-only --progress /Volumes/rs_hdd/Photo_video rsync://${IP}:${PORT}/${MOUNT}/
rsync -mavh --size-only --progress /Volumes/rs_hdd/Movies_archive rsync://${IP}:${PORT}/${MOUNT}/
rsync -mavh --size-only --progress /Volumes/rs_hdd/rs rsync://${IP}:${PORT}/${MOUNT}/
rsync -mavh --size-only --progress /Volumes/rs_hdd/SVETA rsync://${IP}:${PORT}/${MOUNT}/
rsync -mavh --size-only --progress /Volumes/rs_hdd/ARTEM rsync://${IP}:${PORT}/${MOUNT}/
#for dir in Documents Downloads Movies Desktop; do
#	rsync -av --delete /Users/segorov/${dir} rsync://${IP}:${PORT}/${MOUNT}
#done
