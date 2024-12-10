#!/bin/bash

sudo swapoff -a 
sudo fallocate -l 32G /swapfile  
sudo chmod 700 /swapfile
sudo swapoff -a
sudo fallocate -l 32G /swapfile 
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo swapon --show
free -m
