#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define LARGURA 1200
#define ALTURA 600
#define LADO 20
#define MAX_LINHAS 30
#define MAX_COLUNAS 60

#define MAX_INIMIGOS 10


char mapa[MAX_LINHAS][MAX_COLUNAS];
int PosicaoJogadorX=-1;
int PosicaoJogadorY=-1;

int framesParaMoverMonstro = 0;
int intervaloMovimentoMonstro = 10;  // Ajuste esse valor para controlar a velocidade dos monstros

int dx=0, dy=0;

typedef struct {
    int x;
    int y;
    int dx;
    int dy;
} Inimigo;

// Função para redefinir o deslocamento do inimigo
void redefineDeslocamento(Inimigo *inimigo) {
    do {
        inimigo->dx = (GetRandomValue(-1,1)) * LADO; // -LADO, 0 ou LADO
        inimigo->dy = (GetRandomValue(-1,1)) * LADO; // -LADO, 0 ou LADO
    } while (inimigo->dx == 0 && inimigo->dy == 0); // Garante que pelo menos um deslocamento é não-zero
}

// Função para inicializar as posições dos inimigos
void inicializaPosicao(Inimigo *inimigo) {
    inimigo->x = GetRandomValue(0, LARGURA / LADO - 1) * LADO;
    inimigo->y = GetRandomValue(0, ALTURA / LADO - 1) * LADO;

}

// Função para mover o inimigo
int moveInimigo(Inimigo *inimigo, int largura, int altura) {
    int novoX = inimigo->x + inimigo->dx;
    int novoY = inimigo->y + inimigo->dy;

    // Verifica se a nova posição não é uma parede
    if (mapa[novoY / LADO][novoX / LADO] == 'W') {
        return 0; // Movimento para uma parede
    }

    // Verifica se a nova posição está dentro dos limites
    if (novoX >= 0 && novoX < largura && novoY >= 0 && novoY < altura) {
        inimigo->x = novoX;
        inimigo->y = novoY;
        return 1; // Movimento bem-sucedido
    }
    return 0; // Movimento falhou
}


void lerMapa(const char *nomeArquivo)
{
    FILE *file = fopen(nomeArquivo, "r"); // ponteiro  *file do TIPO FILE recebe leitura do arquivo, "r" Abre um arquivo texto para leitura. O arquivo deve existir antes de ser aberto.
    if (file == NULL)
    {
        printf("Erro ao abrir o arquivo %s\n", nomeArquivo);
        exit(1);
    }

    int linha = 0;
    int coluna = 0;
    while (linha < MAX_LINHAS && coluna < MAX_COLUNAS)
    {
        int c = fgetc(file); //esta função já passa a apontar para o próximo caractere, automaticamente, até encontrar -1 (EOF).

        if (c == EOF) // fim do arquivo
        {
            break;
        }
        if (c == '\n')
        {
            linha++;
            coluna = 0;
        }
        else
        {
            mapa[linha][coluna] = c;
            if (c=='J') //não esta ficando no lugar do J, coloquei posição fixa (40,40) ate ajustarmos
            {
                PosicaoJogadorX= 40;
                PosicaoJogadorY= 40;
            }
//            if (c=='M')
//            {
//                for (int i = 0; i < MAX_INIMIGOS; i++) {
//                    inicializaPosicao(&inimigos[i]);
//                }
//
//            }
            coluna++;
        }
    }

    fclose(file);
}

void desenharMapa()
{
    for (int i = 0; i < MAX_LINHAS; i++)
    {
        for (int j = 0; j < MAX_COLUNAS; j++)
        {
            Color cor; //variavel cor do TIPO COR (esse tipo é existente na biblioteca Rayllib)

            switch (mapa[i][j])
            {
            case 'W':
                cor = DARKGRAY;
                break;      // Jogador
            //case 'M':
              //  cor = BLUE;
                //break;       // Inimigo
            case 'R':
                cor = RED;
                break;     // Recurso
            case 'H':
                cor = GREEN;
                break;     // Buraco
            case 'S':
                cor = YELLOW;
                break;    // Base
            default:
                cor = LIGHTGRAY;
                break;      // Espaço em branco
            }

            DrawRectangle(j * 20, i * 20, 20, 20, cor);
        }
    }
}






int deveMover(int x, int y,int dx, int dy, int larg, int alt){

    if (dx == 1) { // Movimento para a direita
        // Verifica se não ultrapassa os limites do mapa
        if (x + LADO < larg) {
            // Verifica se a próxima posição não é uma parede
            if (mapa[y / LADO][x / LADO + 1] != 'W') {
                return 1;
            }
        }
    }

    if(dx == -1){ // Movimento para a esquerda
        // Verifica se não ultrapassa os limites do mapa
        if (x - LADO > 0) {
            // Verifica se a próxima posição não é uma parede
            if (mapa[y / LADO][x / LADO -1 ] != 'W') {
                return 1;
            }
        }
    }

    if(dy == 1){ // Movimento para cima
        if (y < ALTURA) {
            // Verifica se a próxima posição não é uma parede
            if (mapa[y / LADO + 1][x / LADO] != 'W') {
                return 1;
            }
        }
    }

    if(dy == -1){ // Movimento para baixo
        if (y + LADO > 0) {
            // Verifica se a próxima posição não é uma parede
            if (mapa[y / LADO- 1][x / LADO] != 'W') {
                return 1;
            }
        }
    }else{
        return 0;
    }

}

void move(int dx, int dy, int *x, int *y){
    if(dx == 1){
        *x+=20;
    }
    if(dx == -1){
        *x-=20;
    }
    if(dy == 1){
        *y+=20;
    }
    if(dy == -1){
        *y-=20;
    }
    if(dy == 0){
        *y=*y;
    }
    if(dx == 0){
        *x=*x;
    }
}

int main()
{
    // Inicializa a janela
    InitWindow(1200, 600, "Jogo Tower Defense");

    // Ler o mapa do arquivo
    lerMapa("mapa1.txt");

    SetTargetFPS(60);

    srand(time(NULL)); //garante que a semente seja diferente a cada execução do programa

    // Cria os inimigos
    Inimigo inimigos[MAX_INIMIGOS]; //cria varios inimigos com as caracteristicas da struct Inimigo
    for (int i = 0; i < MAX_INIMIGOS; i++) {
        inicializaPosicao(&inimigos[i]);
        redefineDeslocamento(&inimigos[i]);
    }

    while (!WindowShouldClose())
    {

        if (IsKeyPressed(KEY_RIGHT)){
            dx = 1;
            if(deveMover(PosicaoJogadorX, PosicaoJogadorY, dx, dy, LARGURA, ALTURA)== 1){
                move(dx, 0, &PosicaoJogadorX, &PosicaoJogadorY);
                dx=0;
            }
        }

        if (IsKeyPressed(KEY_LEFT)){
            dx = -1;
            if(deveMover(PosicaoJogadorX, PosicaoJogadorY, dx, dy, LARGURA, ALTURA)== 1){
                move(dx, 0, &PosicaoJogadorX, &PosicaoJogadorY);
                dx=0;
            }
        }


        if (IsKeyPressed(KEY_UP)){
            dy = -1;
            if(deveMover(PosicaoJogadorX, PosicaoJogadorY, dx, dy, LARGURA, ALTURA)== 1){
                move(0, dy, &PosicaoJogadorX, &PosicaoJogadorY);
                dy=0;
            }
        }

        if (IsKeyPressed(KEY_DOWN)){

            dy = 1;
            if(deveMover(PosicaoJogadorX, PosicaoJogadorY, dx, dy, LARGURA, ALTURA)== 1){
                move(0, dy, &PosicaoJogadorX, &PosicaoJogadorY);
                dy=0;
            }
        }

        if (IsKeyPressed(KEY_DOWN)){

            dy = 1;
            if(deveMover(PosicaoJogadorX, PosicaoJogadorY, dx, dy, LARGURA, ALTURA)== 1){
                move(0, dy, &PosicaoJogadorX, &PosicaoJogadorY);
                dy=0;
            }
        }

        framesParaMoverMonstro++;
        if (framesParaMoverMonstro >= intervaloMovimentoMonstro) {

            for (int i = 0; i < MAX_INIMIGOS; i++) {
                if (!moveInimigo(&inimigos[i], LARGURA, ALTURA)) {
                    redefineDeslocamento(&inimigos[i]); //se o movimento falhar, redefine o movimento
                }
            }

            framesParaMoverMonstro = 0;  // Reinicia o contador de frames
        }


        BeginDrawing();
        ClearBackground(GREEN);


        // Desenhar o mapa
        desenharMapa();
        DrawRectangle(PosicaoJogadorX, PosicaoJogadorY, LADO, LADO, WHITE);
        for (int i = 0; i < MAX_INIMIGOS; i++) {
            DrawRectangle(inimigos[i].x, inimigos[i].y, LADO, LADO, BLUE);
        }

        EndDrawing();
    }

    CloseWindow();

    return 0;
}


