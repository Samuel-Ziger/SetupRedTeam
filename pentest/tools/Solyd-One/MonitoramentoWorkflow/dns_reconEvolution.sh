#!/usr/bin/env bash

BUG_BOUNTY_DIR="./"

# Exporta a função ou variáveis se precisar, mas no parallel inline funciona bem
find "$BUG_BOUNTY_DIR" -type f -name "domains.txt" | while read -r domain_path; do

    COMPANY_DIR=$(dirname "$domain_path")
    export COMPANY_DIR

    # Dica: Adicionei '--nolock' no parallel para evitar travamentos em execuções longas
    cat "$domain_path" | parallel -j 4 --bar '
        DOMAIN={}
        DOMAIN_DIR="$COMPANY_DIR/domains/$DOMAIN"
        SUBS="$DOMAIN_DIR/subs.txt"
        NEW_SUBS="$DOMAIN_DIR/new_subs_temp.txt"
        
        # Wordlist para o Fuzzing (Ajuste o caminho para a sua preferida!)
        WORDLIST="/usr/share/wordlists/dirb/common.txt"

        mkdir -p "$DOMAIN_DIR"
        echo "[*] Iniciando recon DNS para: $DOMAIN"

        # 1. O Pulo do Gato: 
        # O output do anew vai para o arquivo principal (SUBS) E para o temporário (NEW_SUBS)
        subfinder -d "$DOMAIN" -silent | anew "$SUBS" > "$NEW_SUBS"

        # 2. Verifica se o arquivo temporário tem conteúdo (se achou coisa nova)
        if [ -s "$NEW_SUBS" ]; then
            count=$(wc -l < "$NEW_SUBS")
            echo "[!] $count novos subdomínios em $DOMAIN! Iniciando Recon Ativo..."
            
            # Criar pasta para logs do fuzzing
            mkdir -p "$DOMAIN_DIR/fuzzing"

            # 3. Resolve os domínios para URLs válidas com httpx antes de fuzzar
            # Isso evita que o ffuf perca tempo com domínios mortos
            cat "$NEW_SUBS" | httpx -silent -threads 10 | while read url; do
                
                # Extrai nome limpo para o arquivo de log
                clean_name=$(echo "$url" | sed "s|https\?://||" | tr -cd "[:alnum:].-")
                
                echo "[+] Fuzzing em: $url"
                
                # 4. Executa o FFUF
                # -mc 200,301,302,403: Filtra códigos de resposta interessantes
                # -fs: É bom ajustar filtros de tamanho depois, mas comece simples
                ffuf -u "$url/FUZZ" \
                     -w "$WORDLIST" \
                     -mc 200,301,302,405 \
                     -o "$DOMAIN_DIR/fuzzing/${clean_name}.json" \
                     -s 
            done

            # Limpa o temporário
            rm "$NEW_SUBS"
        else
            echo "[-] Nenhum subdomínio novo para $DOMAIN."
            rm -f "$NEW_SUBS"
        fi
    '
done
