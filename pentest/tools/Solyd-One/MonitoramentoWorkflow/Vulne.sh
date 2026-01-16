#!/usr/bin/env bash

BUG_BOUNTY_DIR="./"

find "$BUG_BOUNTY_DIR" -type f -name "subs.txt" | parallel -j 4 --bar '
       	SUBS_FILE={}
	DOMAIN_DIR=$(dirname "$SUBS_FILE")
	DOMAIN=$(basename "$DOMAIN_DIR")
        NUCLEI_OUT="$DOMAIN_DIR/nuclei_out.txt"
	
	echo  "Iniciando VULN  para o $DOMAIN"


	nuclei -l "$SUBS_FILE" -silent -severity high,critical | anew "$NUCLEI_OUT" 
    '

