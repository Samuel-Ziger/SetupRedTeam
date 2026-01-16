#!/usr/bin/env bash

BUG_BOUNTY_DIR="./"

find "$BUG_BOUNTY_DIR" -type f -name "domains.txt" | while read -r domain_path; do

    COMPANY_DIR=$(dirname "$domain_path")

    cat "$domain_path" | parallel -j 4 --bar '
        DOMAIN={}
        DOMAIN_DIR="'$COMPANY_DIR'/domains/$DOMAIN"
        SUBS="$DOMAIN_DIR/subs.txt"

	mkdir -p "$DOMAIN_DIR"
	echo  "Iniciando recon dns para o $DOMAIN"


	subfinder -d "$DOMAIN" -silent | anew "$SUBS"
    '

done
