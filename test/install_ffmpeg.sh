#!/bin/sh

sudo add-apt-repository -y ppa:mc3man/trusty-media
sudo apt-get -qq update
sudo apt-get install -y ffmpeg

# sudo apt-get install -y at-spi2-core
