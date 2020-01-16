#!/bin/sh

logfile=/tmp/$$.log
exec > $logfile 2>&1
rsync -tmva --delete ~/Downloads /Volumes/rs_hdd/
rsync -tmva --delete ~/Documents /Volumes/rs_hdd/
rsync -tmva --delete ~/projects /Volumes/rs_hdd/
rsync -tmva --delete ~/Pictures /Volumes/rs_hdd/
rsync -tmva --delete ~/Music /Volumes/rs_hdd/
rsync -tmva --delete ~/Movies /Volumes/rs_hdd/
rsync -tmva --delete ~/VirtualBox* /Volumes/rs_hdd/
rsync -tmva --delete ~/PycharmProjects /Volumes/rs_hdd/
