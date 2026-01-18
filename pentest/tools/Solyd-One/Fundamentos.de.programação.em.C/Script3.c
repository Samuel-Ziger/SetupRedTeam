#include <stdio.h>
#include <string.h>

int main () {

	char alvo  [100];
	char resposta [4];
	int porta;

	printf("Digite o alvo:");
	scanf("%s", &alvo);

	printf("Digite a porta:");
	scanf("%i", &porta);
	
	printf("Você deseja realmente atacar o alvo %s ? \n", alvo);
	scanf("%s", resposta);
	if (strcmp(resposta, "sim") == 0){
		printf("Atacando %s na porta %i",alvo, porta);
}
else{
		printf("Cancelando ataque no alvo %s", alvo);
}

	return 0;

}

