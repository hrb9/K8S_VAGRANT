#!/bin/bash
set -e

echo "[INFO] Configuring load balancer (HAProxy)..."

sudo apt-get update -y
sudo apt-get install -y haproxy

sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
    log stdout format raw local0
    maxconn 4096

defaults
    log global
    mode tcp
    option tcplog
    timeout connect 10s
    timeout client 1m
    timeout server 1m

frontend k8s_frontend
    bind 0.0.0.0:6443
    default_backend k8s_backend

backend k8s_backend
    balance roundrobin
    server k8s-master-1 192.168.56.101:6443 check
    server k8s-master-2 192.168.56.102:6443 check
    server k8s-master-3 192.168.56.103:6443 check
EOF

sudo systemctl restart haproxy
sudo systemctl enable haproxy
echo "[INFO] HAProxy installed and configured."
