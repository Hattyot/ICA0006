#!/bin/bash
export VERSION=1.2.0
wget https://github.com/cafebazaar/keepalived-exporter/releases/download/v${VERSION}/keepalived-exporter-${VERSION}.linux-amd64.tar.gz
tar xvzf keepalived-exporter-${VERSION}.linux-amd64.tar.gz keepalived-exporter-${VERSION}.linux-amd64/keepalived-exporter
sudo mv keepalived-exporter-${VERSION}.linux-amd64/keepalived-exporter /usr/local/bin/