#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <netdb.h>


int main(int argc, char *argv[]){

        if (argc != 3) {
                printf("Usage: ./dnsbrute example.com wordlist.txt");
                return 1;
        }

        const char *domain = argv[1];
        const char *wordlist = argv[2];

        FILE *file = fopen(wordlist, "r");
        if (!file) {
                perror("Erro ao abrir arquivo.");
                return 1;
        }

        char subdomain[1024];
        while (fgets(subdomain, sizeof(subdomain), file)) {
                subdomain[strcspn(subdomain, "\n")] = 0;

                char fulldomain[1024];
                sprintf(fulldomain, "%s.%s", subdomain, domain);

                struct hostent *host = gethostbyname(fulldomain);
                if (host) {
                        struct in_addr **addr_list = (struct in_addr **)host->h_addr_list;
                        for (int i = 0; addr_list[i] != NULL; i++) {
                                printf("%s -> %s\n", fulldomain, inet_ntoa(*addr_list[i]));
                        }
                }
        }

}
 