#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define LARGURA 1200
#define ALTURA 600
#define LADO 20
#define MAX_LINHAS 30
#define MAX_COLUNAS 60

#define MAX_INIMIGOS 5

char mapa[MAX_LINHAS][MAX_COLUNAS];
int framesParaMoverInimigo = 0;
int intervaloMovimentoInimigo = 10;  // Ajuste esse valor para controlar a velocidade dos monstros
int recursos_jogador = 0;            // Quantidade de recursos que o jogador possui

typedef struct {
    int x;
    int y;
    int dx;
    int dy;
} Jogador;

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

// Função para ler o mapa e inicializar posições do jogador e inimigos
void lerMapa(const char *nomeArquivo, Jogador *jogador, Inimigo *inimigos, int maxInimigos) {
    FILE *file = fopen(nomeArquivo, "r");
    if (file == NULL) {
        printf("Erro ao abrir o arquivo %s\n", nomeArquivo);
        exit(1);
    }

    int linha = 0;
    int coluna = 0;
    int inimigoIndex = 0;

    while (linha < MAX_LINHAS && coluna < MAX_COLUNAS) {
        int c = fgetc(file);

        if (c == EOF) {
            break;
        }
        if (c == '\n') {
            linha++;
            coluna = 0;
        }
        else {
            mapa[linha][coluna] = c;
            if (c == 'J') {
                jogador->x = coluna * LADO;
                jogador->y = linha * LADO;
            }
            if (c == 'M' && inimigoIndex < maxInimigos) {
                inimigos[inimigoIndex].x = coluna * LADO;
                inimigos[inimigoIndex].y = linha * LADO;
                redefineDeslocamento(&inimigos[inimigoIndex]); // Define o deslocamento inicial do inimigo
                inimigoIndex++;
            }
            coluna++;
        }
    }

    fclose(file);
}

// Função para desenhar o mapa
void desenharMapa() {
    for (int i = 0; i < MAX_LINHAS; i++) {
        for (int j = 0; j < MAX_COLUNAS; j++) {
            Color cor;

            switch (mapa[i][j]) {
            case 'W':
                cor = DARKGRAY;
                break;
            case 'R':
                cor = RED;
                break;
            case 'H':
                cor = GREEN;
                break;
            case 'S':
                cor = YELLOW;
                break;
            default:
                cor = LIGHTGRAY;
                break;
            }

            DrawRectangle(j * 20, i * 20, 20, 20, cor);
        }
    }
}

// Função para redefinir o deslocamento do Jogador
void deslocamentoJogador(Jogador *jogador){
    jogador->dx = 0; // Reseta o deslocamento horizontal
    jogador->dy = 0; // Reseta o deslocamento vertical

    if (IsKeyPressed(KEY_RIGHT)){
        jogador->dx = 1;
    }

    if (IsKeyPressed(KEY_LEFT)){
        jogador->dx = -1;
    }

    if (IsKeyPressed(KEY_UP)){
        jogador->dy = -1;
    }

    if (IsKeyPressed(KEY_DOWN)){
        jogador->dy = 1;
    }
}

// Função para mover o Jogador
int moveJogador(Jogador *jogador, int largura, int altura) {
    int novoX = jogador->x + jogador->dx*LADO;
    int novoY = jogador->y + jogador->dy*LADO;

    // Verifica se a nova posição não é uma parede
    if (mapa[novoY / LADO][novoX / LADO] == 'W') {
        return 0; // Movimento para uma parede
    }

    // Verifica se a nova posição está dentro dos limites
    if (novoX >= 0 && novoX < largura && novoY >= 0 && novoY < altura) {
        jogador->x = novoX;
        jogador->y = novoY;
        return 1; // Movimento bem-sucedido
    }
    return 0; // Movimento falhou
}


//Função para pegar recursos
void pegar_recurso(Jogador *jogador) {
    //Verifica a posição do recurso no mapa
    int col = jogador->x / LADO;
    int lin = jogador->y / LADO;

    //Verifica se a posição contém um recurso
    if (mapa[lin][col] == 'R') {
        recursos_jogador++;  // Incrementa o contador de recursos do jogador
        mapa[lin][col] = ' '; // Remove o recurso do mapa
    }
}

int main() {
    // Inicializa a janela
    InitWindow(LARGURA, ALTURA, "Jogo Tower Defense");

    // Cria os inimigos
    Inimigo inimigos[MAX_INIMIGOS]; //cria varios inimigos com as caracteristicas da struct Inimigo
    Jogador jogador = {0}; // Inicializa o jogador com zero, garantindo que x, y, dx, e dy comecem com valores conhecidos.

    // Ler o mapa do arquivo e inicializar posições do jogador e dos inimigos
    lerMapa("mapa1.txt", &jogador, inimigos, MAX_INIMIGOS);

    SetTargetFPS(60);

    srand(time(NULL)); //garante que a semente seja diferente a cada execução do programa

    while (!WindowShouldClose()) {
        deslocamentoJogador(&jogador);
        moveJogador(&jogador, LARGURA, ALTURA);
        pegar_recurso(&jogador); // Verifica se o jogador pega um recurso

        framesParaMoverInimigo++;
        if (framesParaMoverInimigo >= intervaloMovimentoInimigo) {
            for (int i = 0; i < MAX_INIMIGOS; i++) {
                if (!moveInimigo(&inimigos[i], LARGURA, ALTURA)) {
                    redefineDeslocamento(&inimigos[i]); //se o movimento falhar, redefine o movimento
                }
            }

            framesParaMoverInimigo = 0;  // Reinicia o contador de frames
        }

        BeginDrawing();
        ClearBackground(GREEN);

        // Desenhar o mapa
        desenharMapa();
        DrawRectangle(jogador.x, jogador.y, LADO, LADO, WHITE);
        for (int i = 0; i < MAX_INIMIGOS; i++) {
            DrawRectangle(inimigos[i].x, inimigos[i].y, LADO, LADO, BLUE);
        }

        //Mostra a quantidade de recursos na tela
        DrawText(TextFormat("Recursos: %d", recursos_jogador), 10, 10, 20, BLACK);

        EndDrawing();
    }

    CloseWindow();

    return 0;
}
