#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define LARGURA 1200
#define ALTURA 600
#define LADO 20
#define MAX_LINHAS 30
#define MAX_COLUNAS 60
#define MAX_INIMIGOS 4

char mapa[MAX_LINHAS][MAX_COLUNAS];
int frames_para_mover_inimigo = 0;
int intervalo_movimento_inimigo = 4;   //Controla a velocidade dos monstros
int recursos_jogador = 0;              //Quantos recursos o jogador tem, (inicia em 0)
int vidas_jogador = 3;                 //Quantas vidas o jogador começa
int vida_base = 3;                     //Vida inicial da Base
int torres[MAX_LINHAS][MAX_COLUNAS] = {0}; //Matriz que apresenta as torres

//Struct para o jogador e o inimigo
typedef struct {
    int x;
    int y;
    int dx;
    int dy;
} Entidade;

typedef Entidade Jogador;
typedef Entidade Inimigo;

//Função para redefinir o deslocamento da entidade
void redefine_deslocamento_entidade(Entidade *entidade) {
    do {
        entidade->dx = (GetRandomValue(-1, 1)) * LADO; //-LADO, 0 ou LADO
        entidade->dy = (GetRandomValue(-1, 1)) * LADO; //-LADO, 0 ou LADO
    } while (entidade->dx == 0 && entidade->dy == 0); //Garante que pelo menos um deslocamento é não-nulo
}

//Função para mover a entidade (jogador ou inimigo)
int move_entidade(Entidade *entidade, int largura, int altura) {
    int novo_x = entidade->x + entidade->dx;
    int novo_y = entidade->y + entidade->dy;

    //Vê se a nova posição não é uma parede
    if (mapa[novo_y / LADO][novo_x / LADO] == 'W') {
        return 0; // Movimento para uma parede
    }

    //Vê se a nova posição está dentro dos limites
    if (novo_x >= 0 && novo_x < largura && novo_y >= 0 && novo_y < altura) {
        entidade->x = novo_x;
        entidade->y = novo_y;
        return 1; //Movimento deu certo
    }
    return 0; //Movimento deu errado
}

//Função para ler o mapa e inicializar posições do jogador e inimigos
void ler_mapa(const char *nome_arquivo, Jogador *jogador, Inimigo *inimigos, int max_inimigos) {
    FILE *file = fopen(nome_arquivo, "r");
    if (file == NULL) {
        printf("Erro ao abrir o arquivo %s\n", nome_arquivo);
        exit(1);
    }

    int linha = 0;
    int coluna = 0;
    int inimigo_index = 0;

    while (linha<MAX_LINHAS && coluna<MAX_COLUNAS) {
        int c = fgetc(file);

        if (c == EOF) {
            break;
        }
        if (c == '\n') {
            linha++;
            coluna = 0;
        } else {
            mapa[linha][coluna] = c;
            if (c == 'J') {
                jogador->x = coluna * LADO;
                jogador->y = linha * LADO;
            }
            if (c == 'M' && inimigo_index<max_inimigos) {
                inimigos[inimigo_index].x = coluna * LADO;
                inimigos[inimigo_index].y = linha * LADO;
                redefine_deslocamento_entidade(&inimigos[inimigo_index]); //Define o deslocamento inicial do inimigo
                inimigo_index++;
            }
            coluna++;
        }
    }

    fclose(file);
}

//Função para "desenhar" o mapa
void desenhar_mapa() {
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

//Função para definir o deslocamento do jogador baseado nas teclas pressionadas
void define_deslocamento_jogador(Jogador *jogador) {
    jogador->dx = 0; //Reseta o deslocamento horizontal
    jogador->dy = 0; //Reseta o deslocamento vertical

    if (IsKeyPressed(KEY_RIGHT)) {
        jogador->dx = 1;
    }
    if (IsKeyPressed(KEY_LEFT)) {
        jogador->dx = -1;
    }
    if (IsKeyPressed(KEY_UP)) {
        jogador->dy = -1;
    }
    if (IsKeyPressed(KEY_DOWN)) {
        jogador->dy = 1;
    }
}

//Função para mover o jogador
int move_jogador(Jogador *jogador, int largura, int altura) {
    int novo_x = jogador->x + jogador->dx * LADO;
    int novo_y = jogador->y + jogador->dy * LADO;

    //Vê se a nova posição não é uma parede
    if (mapa[novo_y / LADO][novo_x / LADO] == 'W') {
        return 0; //Movimento para uma parede
    }

    //Vê se a nova posição está dentro dos limites
    if (novo_x >= 0 && novo_x < largura && novo_y >= 0 && novo_y < altura) {
        jogador->x = novo_x;
        jogador->y = novo_y;
        return 1; //Movimento deu certo
    }
    return 0; //Movimento deu errado
}

//Função para pegar recursos
void pegar_recurso(Jogador *jogador) {
    //Vê a posição do recurso no mapa
    int col = jogador->x / LADO;
    int lin = jogador->y / LADO;

    //Vê se a posição contém um recurso
    if (mapa[lin][col] == 'R') {
        recursos_jogador++;  //Aumenta o contador de recursos
        mapa[lin][col] = ' '; //Remove o recurso do mapa
    }
}

//Função para perder vida ao colidir com inimigos
void perde_vida(Jogador *jogador, Inimigo *inimigos, int max_inimigos) {
    for (int i = 0; i < max_inimigos; i++) {
        if (inimigos[i].x == jogador->x && inimigos[i].y == jogador->y) {
            vidas_jogador--;
            jogador->x = 20;
            jogador->y = 20;
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

//Função para construir uma torre
void construir_torre(Jogador *jogador) {
    int col = jogador->x / LADO;
    int lin = jogador->y / LADO;

    //Vê se a posição é válida para construir uma torre
    if (mapa[lin][col] == 'T' && recursos_jogador >= 2) {
        torres[lin][col] = 1; //Marca a posição como ocupada por uma torre
        recursos_jogador -= 2; //Consome 2 recursos para construir a torre
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
    //Janela
    InitWindow(LARGURA, ALTURA, "Jogo Tower Defense");

    //Cria os inimigos
    Inimigo inimigos[MAX_INIMIGOS]; //Cria vários inimigos com as características da struct Inimigo
    Jogador jogador = {0}; //Inicializa o jogador com zero, garantindo que x, y,e os deslocamentos comecem com valores conhecidos

    //Ler o mapa do arquivo e inicializar posições do jogador e dos inimigos
    ler_mapa("mapa1.txt", &jogador, inimigos, MAX_INIMIGOS);

    SetTargetFPS(60);

    srand(time(NULL)); //Garante que a seed seja diferente a cada execução do programa

    while (!WindowShouldClose()) {
        define_deslocamento_jogador(&jogador);
        move_jogador(&jogador, LARGURA, ALTURA);
        pegar_recurso(&jogador); //Vê se o jogador pega um recurso
        perde_vida(&jogador, inimigos, MAX_INIMIGOS); //Vê se o jogador colide com um inimigo

        //Verifica a colisão dos inimigos com a base
        verificar_colisao_base(inimigos, MAX_INIMIGOS);

        frames_para_mover_inimigo++;
        if (frames_para_mover_inimigo >= intervalo_movimento_inimigo) {
            for (int i = 0;i<MAX_INIMIGOS;i++) {
                if (!move_entidade(&inimigos[i], LARGURA, ALTURA)) {
                    redefine_deslocamento_entidade(&inimigos[i]); //Se o movimento falhar, redefine o movimento
                }
            }
            frames_para_mover_inimigo = 0; //Reinicia o contador de frames
        }
        if (IsKeyPressed(KEY_F)) {
        construir_torre(&jogador); //Permite construir uma torre ao pressionar 'F'
}
        //Define a tecla de teletransporte pelo buraco 'T'

            teletransportar_jogador(&jogador,LARGURA,ALTURA);

        BeginDrawing();
        ClearBackground(GREEN);

        //"Desenhar" o mapa
        desenhar_mapa();
        desenhar_base(); //"Desenhar" a base com a vida restante
        DrawRectangle(jogador.x, jogador.y, LADO, LADO, WHITE);
        for (int i = 0;i<MAX_INIMIGOS;i++) {
            DrawRectangle(inimigos[i].x, inimigos[i].y, LADO, LADO, PINK);
        }

        //Canto superior esquerdo da tela
        DrawText(TextFormat("Recursos: %d", recursos_jogador), 10, 10, 20, WHITE); //Mostra a quantidade de recursos que o jogador pegou
        DrawText(TextFormat("Vidas: %d", vidas_jogador), 10, 40, 20, WHITE); //Mostra as vidas restantes do jogador
        DrawText(TextFormat("Vida da Base: %d", vida_base), 10, 70, 20, WHITE); //Mostra a vida da base

        EndDrawing();
    }

    CloseWindow();

    return 0;
}
