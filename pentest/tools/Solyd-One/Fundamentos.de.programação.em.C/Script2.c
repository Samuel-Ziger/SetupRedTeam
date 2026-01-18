#include <stdio.h>


int main () {

	char alvo  [100];
	int porta;

	printf("Digite o alvo:");
	scanf("%s", &alvo);

	printf("Digite a porta:");
	scanf("%i", &porta);

	printf("Ataquecando %s na porta %i",alvo, porta);
	return 0;

}

