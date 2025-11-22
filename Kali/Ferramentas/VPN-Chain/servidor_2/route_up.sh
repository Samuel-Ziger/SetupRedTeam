#!/bin/bash
# Redireciona o tráfego padrão pela VPN (tun1)
ip rule add from 10.8.0.0/24 table 100
ip route add default dev tun0 table 100
