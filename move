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
int intervaloMovimentoInimigo = 40;  // Ajuste esse valor para controlar a velocidade dos monstros
int recursos_jogador = 0;            // Quantidade de recursos que o jogador possui
int vidas_jogador = 3;
int vida_base = 3;                     //Vida inicial da Base

typedef struct {
    int x;
    int y;
    int dx;
    int dy;
    int visitado[MAX_LINHAS][MAX_COLUNAS]; // Matriz para armazenar as posições visitadas
} Inimigo;

typedef struct {
    int x;
    int y;
    int dx;
    int dy;
} Jogador;

// Função para redefinir o deslocamento do inimigo
void redefineDeslocamento(Inimigo *inimigo) {
    inimigo->dx = 0;
    inimigo->dy = 0;

    // Tenta mover para a direita
    if ((mapa[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 'C' || mapa[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 'M' || mapa[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 'S') &&
        inimigo->visitado[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 0) {
        inimigo->dx = 1;
        return;
    }

    // Tenta mover para a esquerda
    if ((mapa[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 'C' || mapa[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 'M' || mapa[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 'S') &&
        inimigo->visitado[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 0) {
        inimigo->dx = -1;
        return;
    }

    // Tenta mover para baixo
    if ((mapa[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 'C' || mapa[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 'M' || mapa[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 'S') &&
        inimigo->visitado[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 0) {
        inimigo->dy = 1;
        return;
    }

    // Tenta mover para cima
    if ((mapa[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 'C' || mapa[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 'M' || mapa[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 'S') &&
        inimigo->visitado[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 0) {
        inimigo->dy = -1;
        return;
    }
}

// Função para mover o inimigo ao longo do caminho
void moveInimigo(Inimigo *inimigo, int largura, int altura) {
    int novoX = inimigo->x + inimigo->dx * LADO;
    int novoY = inimigo->y + inimigo->dy * LADO;

    // Verifica se a nova posição está dentro dos limites
    if (novoX >= 0 && novoX < largura && novoY >= 0 && novoY < altura) {
        inimigo->visitado[inimigo->y / LADO][inimigo->x / LADO] = 1; // Marca a posição atual como visitada
        inimigo->x = novoX;
        inimigo->y = novoY;
    }
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

//Função para "desenhar" o mapa
void desenharMapa() {
    for (int i = 0;i<MAX_LINHAS;i++) {
        for (int j = 0;j<MAX_COLUNAS;j++) {
            Color cor;

            switch (mapa[i][j]) {
                case 'W':
                    cor = DARKGRAY;
                    break;
                case 'R':
                    cor = RED;
                    break;
                case 'B':
                    cor = PURPLE;
                    break;
                case 'H':
                    cor = GREEN;
                    break;
                case 'S':
                    cor = YELLOW;
                    break;
                case 'T':
                    cor = BLUE;
                    break;
                default:
                    cor = BLACK;
                    break;
            }

            DrawRectangle(j * 20, i * 20, 20, 20, cor);//j (coordenada horizontal) e i(coordenada vertical)
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


//Função para perder vida
void perde_vida(Jogador *jogador, Inimigo *inimigos, int maxInimigos) {
    for (int i = 0; i < maxInimigos; i++) {
        if (inimigos[i].x == jogador->x && inimigos[i].y == jogador->y) {
            vidas_jogador--;
            break; // Sai do loop assim que a colisão é detectada
        }
    }
}


//Função para ver se um inimigo "colidiu" com a base
void verificar_colisao_base(Inimigo *inimigos, int max_inimigos) {
    for (int i = 0;i<max_inimigos;i++) {
        int col_inimigo = inimigos[i].x / LADO;
        int lin_inimigo = inimigos[i].y / LADO;

        for (int i = 0; i < MAX_LINHAS; i++) {
            for (int j = 0; j < MAX_COLUNAS; j++) {
                if (mapa[i][j] == 'S') {
                    int col_base = j;
                    int lin_base = i;

                    if (col_inimigo == col_base && lin_inimigo == lin_base) {
                        vida_base--; //Reduz a vida da base
                        if (vida_base <= 0) {
                            vida_base = 0;
                            //Adicione a lógica para quando a base perder toda a vida (fim de jogo)
                        }
                    }
                }
            }
        }
    }
}

//Função para "desenhar" a base com a vida restante trocando de cor
void desenhar_base() {
    for (int i = 0; i < MAX_LINHAS; i++) {
        for (int j = 0; j < MAX_COLUNAS; j++) {
            if (mapa[i][j] == 'S') {
                Color cor;
                switch (vida_base) {
                    case 3: cor = YELLOW; break;
                    case 2: cor = ORANGE; break;
                    case 1: cor = RED; break;
                    default: cor = DARKGRAY; break;
                }
                DrawRectangle(j * LADO, i * LADO, LADO, LADO, cor);
            }
        }
    }
}

//Função para teletransportar o jogador entre buracos
void teletransportar_jogador(Jogador *jogador, int largura, int altura) {
    if (mapa[jogador->y / LADO][jogador->x / LADO] == 'H') {
        int destinoX = jogador->x;
        int destinoY = jogador->y;
        int maiorDistancia = 0;

        if (jogador->dx != 0) { // Movimento horizontal
            if (jogador->dx > 0) { // Movimento para a direita
                for (int i = 0; i < MAX_COLUNAS; i++) {
                    if (mapa[jogador->y / LADO][i] == 'H') {
                        if (i > jogador->x / LADO) {
                            if (i - jogador->x / LADO > maiorDistancia) {
                                maiorDistancia = i - jogador->x / LADO;
                                destinoX = i * LADO;
                            }
                        }
                    }
                }
            } else { // Movimento para a esquerda
                for (int i = 0; i < MAX_COLUNAS; i++) {
                    if (mapa[jogador->y / LADO][i] == 'H') {
                        if (i < jogador->x / LADO) {
                            if (jogador->x / LADO - i > maiorDistancia) {
                                maiorDistancia = jogador->x / LADO - i;
                                destinoX = i * LADO;
                            }
                        }
                    }
                }
            }
        } else if (jogador->dy != 0) { // Movimento vertical
            if (jogador->dy > 0) { // Movimento para baixo
                for (int i = 0; i < MAX_LINHAS; i++) {
                    if (mapa[i][jogador->x / LADO] == 'H') {
                        if (i > jogador->y / LADO) {
                            if (i - jogador->y / LADO > maiorDistancia) {
                                maiorDistancia = i - jogador->y / LADO;
                                destinoY = i * LADO;
                            }
                        }
                    }
                }
            } else { // Movimento para cima
                for (int i = 0; i < MAX_LINHAS; i++) {
                    if (mapa[i][jogador->x / LADO] == 'H') {
                        if (i < jogador->y / LADO) {
                            if (jogador->y / LADO - i > maiorDistancia) {
                                maiorDistancia = jogador->y / LADO - i;
                                destinoY = i * LADO;
                            }
                        }
                    }
                }
            }
        }

        jogador->x = destinoX;
        jogador->y = destinoY;
    }
}

int main() {
    // Inicializa a janela
    InitWindow(LARGURA, ALTURA, "Jogo Tower Defense");

    // Cria os inimigos
    Inimigo inimigos[MAX_INIMIGOS]; //cria varios inimigos com as caracteristicas da struct Inimigo
    Jogador jogador = {0}; // Inicializa o jogador com zero, garantindo que x, y, dx, e dy comecem com valores conhecidos.

    // Inicializa a matriz de visitados para cada inimigo
    for (int i = 0; i < MAX_INIMIGOS; i++) {
        for (int lin = 0; lin < MAX_LINHAS; lin++) {
            for (int col = 0; col < MAX_COLUNAS; col++) {
                inimigos[i].visitado[lin][col] = 0;
            }
        }
    }

    // Ler o mapa do arquivo e inicializar posições do jogador e dos inimigos
    lerMapa("mapa1.txt", &jogador, inimigos, MAX_INIMIGOS);

    SetTargetFPS(60);

    srand(time(NULL)); //garante que a semente seja diferente a cada execução do programa

    bool gameOver = false;
    double gameOverTime = 0.0;

    while (!WindowShouldClose()) {
        if (!gameOver) {
            deslocamentoJogador(&jogador);
            moveJogador(&jogador, LARGURA, ALTURA);
            pegar_recurso(&jogador); // Verifica se o jogador pega um recurso
            perde_vida(&jogador, inimigos, MAX_INIMIGOS);
            verificar_colisao_base(inimigos, MAX_INIMIGOS);//Verifica a colisão dos inimigos com a base

            // Verifica se o jogador perdeu todas as vidas
            if (vidas_jogador <= 0) {
                gameOver = true;
                gameOverTime = GetTime();
            }

            framesParaMoverInimigo++;
            if (framesParaMoverInimigo >= intervaloMovimentoInimigo) {
                for (int i = 0; i < MAX_INIMIGOS; i++) {
                    moveInimigo(&inimigos[i], LARGURA, ALTURA);
                    redefineDeslocamento(&inimigos[i]);
                }

                framesParaMoverInimigo = 0;  // Reinicia o contador de frames
            }
        } else {
            // Verifica se 3 segundos se passaram desde o "Game Over"
            if (GetTime() - gameOverTime >= 3.0) {
                break; // Sai do loop principal para fechar o jogo
            }
        }

        teletransportar_jogador(&jogador,LARGURA,ALTURA);

        BeginDrawing();
        ClearBackground(GREEN);

        // Desenhar o mapa
        desenharMapa();
        DrawRectangle(jogador.x, jogador.y, LADO, LADO, WHITE);
        for (int i = 0; i < MAX_INIMIGOS; i++) {
            DrawRectangle(inimigos[i].x, inimigos[i].y, LADO, LADO, BLUE);
        }

        // Mostra a quantidade de recursos e vidas na tela
        DrawText(TextFormat("Recursos: %d", recursos_jogador), 10, 10, 20, BLACK);
        DrawText(TextFormat("Vidas: %d", vidas_jogador), 10, 40, 20, BLACK); // Ajustei a posição do texto

        // Se o jogo acabou, mostra a mensagem de "Game Over"
        if (gameOver) {
            DrawText("Game Over", LARGURA / 2 - MeasureText("Game Over", 50) / 2, ALTURA / 2 - 50, 50, RED);
        }

        EndDrawing();
    }

    CloseWindow();

    return 0;
}
