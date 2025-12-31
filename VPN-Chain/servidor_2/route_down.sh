#!/bin/bash
ip rule del from 10.8.0.0/24 table 100
ip route flush table 100
