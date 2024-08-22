#include "raylib.h"
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define LARGURA 1200
#define ALTURA 600
#define LADO 20
#define MAX_LINHAS 30
#define MAX_COLUNAS 60


char mapa[MAX_LINHAS][MAX_COLUNAS];
int framesParaMoverInimigo = 0;
int intervaloMovimentoInimigo = 15;  // Ajuste esse valor para controlar a velocidade dos monstros
int recursos_jogador = 0;            // Quantidade de recursos que o jogador possui
int vidas_jogador = 1;
int vida_base = 3;   //Vida inicial da Base
int numInimigos = 5; // Número atual de inimigos

typedef struct {
    int x;
    int y;
    int dx;
    int dy;
    int visitado[MAX_LINHAS][MAX_COLUNAS]; // Matriz para armazenar as posições visitadas
    int x_inicial; // Posição inicial x
    int y_inicial; // Posição inicial y
} Inimigo;

typedef struct {
    int x;
    int y;
    int dx;
    int dy;
    int x_inicial; // Posição inicial x
    int y_inicial; // Posição inicial y
} Jogador;

// Função para redefinir o deslocamento do inimigo
void redefineDeslocamento(Inimigo *inimigo) {
    inimigo->dx = 0;
    inimigo->dy = 0;

    // Tenta mover para a direita
    if ((mapa[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 'C' || mapa[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 'M' || mapa[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 'S' ||
         mapa[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 'P') && inimigo->visitado[inimigo->y / LADO][(inimigo->x / LADO) + 1] == 0) {
        inimigo->dx = 1;
        return;
    }

    // Tenta mover para a esquerda
    if ((mapa[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 'C' || mapa[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 'M' || mapa[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 'S'||
         mapa[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 'P') && inimigo->visitado[inimigo->y / LADO][(inimigo->x / LADO) - 1] == 0) {
        inimigo->dx = -1;
        return;
    }

    // Tenta mover para baixo
    if ((mapa[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 'C' || mapa[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 'M' || mapa[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 'S' ||
         mapa[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 'P') && inimigo->visitado[(inimigo->y / LADO) + 1][inimigo->x / LADO] == 0) {
        inimigo->dy = 1;
        return;
    }

    // Tenta mover para cima
    if ((mapa[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 'C' || mapa[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 'M' || mapa[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 'S' ||
         mapa[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 'P') && inimigo->visitado[(inimigo->y / LADO) - 1][inimigo->x / LADO] == 0) {
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
                jogador->x_inicial = jogador->x;
                jogador->y_inicial = jogador->y;

            }
            if (c == 'M' && inimigoIndex < maxInimigos) {
                inimigos[inimigoIndex].x = coluna * LADO;
                inimigos[inimigoIndex].y = linha * LADO;
                inimigos[inimigoIndex].x_inicial = inimigos[inimigoIndex].x;
                inimigos[inimigoIndex].y_inicial = inimigos[inimigoIndex].y;
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
                case 'P':
                    cor = PURPLE;
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

    Sound pegarItens = LoadSound("pegaritens.mp3");

    //Verifica a posição do recurso no mapa
    int col = jogador->x / LADO;
    int lin = jogador->y / LADO;

    //Verifica se a posição contém um recurso
    if (mapa[lin][col] == 'R') {
        recursos_jogador++;  // Incrementa o contador de recursos do jogador
        mapa[lin][col] = ' '; // Remove o recurso do mapa
        PlaySound(pegarItens);
    }
}

void largar_recurso(Jogador *jogador){

    Sound dropItens = LoadSound("dropitens.mp3");

    //Verifica a posição do recurso no mapa
    int col = jogador->x / LADO;
    int lin = jogador->y / LADO;

    if(recursos_jogador > 0){
        mapa[lin][col] = 'P'; // Larga o recurso do mapa
        PlaySound(dropItens);
        recursos_jogador--;  // Decrementa o contador de recursos do jogador
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

void eliminarInimigo(Inimigo *inimigos, int *vidaBase, int *numInimigos, char mapa[MAX_LINHAS][MAX_COLUNAS]) {

    Sound monstroMorre = LoadSound("monstromorrendo.mp3");

    for (int i = 0; i < *numInimigos; i++) {
        int col_inimigo = inimigos[i].x / LADO;
        int lin_inimigo = inimigos[i].y / LADO;

        // Verifica se a posição do inimigo é um recurso no mapa
        if (mapa[lin_inimigo][col_inimigo] == 'P') {
            // Remove o recurso do mapa
            mapa[lin_inimigo][col_inimigo] = 'C';

            // Remove o inimigo da lista movendo o último inimigo para a posição do inimigo removido
            for (int j = i; j < *numInimigos - 1; j++) {
                inimigos[j] = inimigos[j + 1];
            }
            (*numInimigos)--; // Reduz o número total de inimigos
            i--; // Ajusta o índice para a próxima iteração após a remoção
            PlaySound(monstroMorre);
        }
        // Verifica colisão do inimigo com a base
        if (mapa[lin_inimigo][col_inimigo] == 'S') {
            (*vidaBase)--; //colocar entre parenteses para garantir que o endereço apontado seja decrementado e não a variavel vidaBase.
            // Remove o inimigo da lista movendo o último inimigo para a posição do inimigo removido
            for (int j = i; j < *numInimigos - 1; j++) {
                inimigos[j] = inimigos[j + 1];
            }
            (*numInimigos)--; // Reduz o número total de inimigos
            i--; // Ajusta o índice para a próxima iteração após a remoção
            PlaySound(monstroMorre);
        }
    }

}


void salvarJogo(Jogador *jogador, Inimigo *inimigos, int maxInimigos, int recursos)
{
    FILE *arquivo = fopen("JogoSalvo.bin", "wb");
    if (arquivo == NULL)
    {
        printf("Erro ao abrir o arquivo para salvar!\n");
        return;
    }

    // Salvar dados do jogador
    fwrite(jogador, sizeof(Jogador), 1, arquivo);

    // Salvar dados dos inimigos
    for (int i = 0; i < maxInimigos; i++)
    {
        fwrite(&inimigos[i], sizeof(Inimigo), 1, arquivo);
    }

    // Salvar quantidade de recursos
    fwrite(&recursos, sizeof(int), 1, arquivo);

    fclose(arquivo);
    printf("Jogo salvo com sucesso!\n");
}

// Função para carregar o estado do jogo
void carregarJogo(Jogador *jogador, Inimigo *inimigos, int maxInimigos, int *recursos)
{
    FILE *arquivo = fopen("JogoSalvo.bin", "rb");
    if (arquivo == NULL)
    {
        printf("Erro ao abrir o arquivo para carregar!\n");
        return;
    }

    // Carregar dados do jogador
    fread(jogador, sizeof(Jogador), 1, arquivo);

    // Carregar dados dos inimigos
    for (int i = 0; i < maxInimigos; i++)
    {
        fread(&inimigos[i], sizeof(Inimigo), 1, arquivo);
    }

    // Carregar quantidade de recursos
    fread(recursos, sizeof(int), 1, arquivo);

    fclose(arquivo);
    printf("Jogo carregado com sucesso!\n");
}

int MenuPrincipal(Inimigo *inimigos, int maxInimigos, Jogador *jogador, Jogador *jogadorsalvo, int *recursos)
{
    int continuar = 0;
    bool paused = true;
    while (paused && continuar != 1)
    {
        if (IsKeyPressed(KEY_N))
        {
            continuar = 1;
            lerMapa("Mapa4.txt", jogador, inimigos, numInimigos);

        }
        if (IsKeyPressed(KEY_C))
        {
            lerMapa("Mapa4.txt", jogador, inimigos, numInimigos);
            carregarJogo(jogador, inimigos, maxInimigos, &recursos_jogador);
            continuar = 1;
            paused=false;
        }
        if (IsKeyPressed(KEY_Q))
        {
            CloseWindow();
            exit(0); // Encerra o programa imediatamente
        }
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Pressione N para Novo Jogo",LARGURA/2 - MeasureText("Pressione N para Novo Jogo",30)/2, 100, 30, RED);
        DrawText("Pressione C para Carregar Jogo",LARGURA/2 - MeasureText("Pressione C para Carregar Jogo",30)/2, 240, 30, RED);
        DrawText("Pressione Q para Sair Sem Salvar",LARGURA/2 - MeasureText("Pressione Q para Sair Sem Salvar",30)/2, 380, 30, RED);
        EndDrawing();
    }
    return continuar;
}

int MenuPause(Inimigo *inimigos, int maxInimigos, Jogador *jogador, Jogador *jogadorsalvo, int *recursos)
{
    int continuar = 0;
    bool paused=true;
    while (paused&&continuar != 1)
    {
        if (IsKeyPressed(KEY_C))
        {
            continuar = 1;
            paused=false;
        }
        if(IsKeyPressed(KEY_L))
        {
            carregarJogo(jogador, inimigos, maxInimigos, &recursos_jogador);
            continuar = 1;
            paused=false;
        }
        if (IsKeyPressed(KEY_S))
        {
            salvarJogo(jogador, inimigos, maxInimigos, recursos_jogador);
        }
        if (IsKeyPressed(KEY_V))
        {
            continuar = MenuPrincipal(inimigos, numInimigos, jogador,jogadorsalvo,&recursos_jogador);

        }
        if (IsKeyPressed(KEY_F))
        {
            CloseWindow();
            exit(0); // Encerra o programa imediatamente
        }
        BeginDrawing();
        ClearBackground(RAYWHITE);
        DrawText("Pressione C para continuar",LARGURA/2 - MeasureText("Pressione C para continuar",30)/2, ALTURA / 5 - 30, 30, RED);
        DrawText("Pressione L para carregar jogo",LARGURA/2 - MeasureText("Pressione L para carregar jogo",30)/2, (ALTURA / 5 - 30)*2, 30, RED);
        DrawText("Pressione S para salvar jogo",LARGURA/2 - MeasureText("Pressione S para salvar jogo",30)/2, (ALTURA / 5 - 30)*3, 30, RED);
        DrawText("Pressione V para voltar ao menu",LARGURA/2 - MeasureText("Pressione V para voltar ao menu",30)/2, (ALTURA / 5 - 30)*4, 30, RED);
        DrawText("Pressione F para fechar o jogo",LARGURA/2 - MeasureText("Pressione F para fechar o jogo",30)/2, (ALTURA / 5 - 30)*5, 30, RED);
        EndDrawing();
    }
    return continuar;
}



int main() {
    // Inicializa a janela
    InitWindow(LARGURA, ALTURA, "Jogo Tower Defense");

    // Inicializa o sistema de áudio
    InitAudioDevice();

    // Carregar o arquivo de áudio
    Music soundtrack = LoadMusicStream("soundtrack.mp3");
    Music gameover = LoadMusicStream("gameover.mp3");
    Music win = LoadMusicStream("win.mp3");


    // Carregar o arquivo de audio como sound para reproduzir apenas uma vez
    Sound pegarItens = LoadSound("pegaritens.mp3");
    Sound monstroMorre = LoadSound("monstromorrendo.mp3");
    Sound personagemMorre= LoadSound("personagemmorre.mp3");
    Sound dropItens = LoadSound("dropitens.mp3");


    // Reproduzir a música
    PlayMusicStream(soundtrack);


    // Cria os inimigos
    Inimigo inimigos[numInimigos]; //cria varios inimigos com as caracteristicas da struct Inimigo
    Jogador jogador = {0}; // Inicializa o jogador com zero, garantindo que x, y, dx, e dy comecem com valores conhecidos.

    Inimigo inimigosalvo [numInimigos];
    Jogador jogadorsalvo = {0};

    // Inicializa a matriz de visitados para cada inimigo
    for (int i = 0; i < numInimigos; i++) {
        for (int lin = 0; lin < MAX_LINHAS; lin++) {
            for (int col = 0; col < MAX_COLUNAS; col++) {
                inimigos[i].visitado[lin][col] = 0;
            }
        }
    }

    SetTargetFPS(60);

    bool gameOver = false;
    double gameOverTime = 0.0;

    int comparador = MenuPrincipal(inimigos, numInimigos, &jogador, &jogadorsalvo, &recursos_jogador);

    if (comparador == 1)
    {
        while (!WindowShouldClose()) {
            // Atualiza o stream de música
            UpdateMusicStream(soundtrack);
            UpdateMusicStream(gameover);

            if (!gameOver) {

                if (IsKeyPressed(KEY_P))
                {
                    MenuPause(inimigos, numInimigos, &jogador,&jogadorsalvo,&recursos_jogador);
                }

                deslocamentoJogador(&jogador);
                moveJogador(&jogador, LARGURA, ALTURA);
                pegar_recurso(&jogador); // Verifica se o jogador pega um recurso
                perde_vida(&jogador, inimigos, numInimigos);


                // Verifica se o jogador perdeu todas as vidas
                if(vidas_jogador <= 0) {
                    gameOver = true;
                    StopMusicStream(soundtrack);
                    PlayMusicStream(gameover);
                    gameOverTime = GetTime();
                }
                // Verifica se a base perdeu todas as vidas
                if(vida_base <= 0){
                    gameOver = true;
                    StopMusicStream(soundtrack);
                    PlayMusicStream(gameover);
                    gameOverTime = GetTime();
                }

                framesParaMoverInimigo++;
                if (framesParaMoverInimigo >= intervaloMovimentoInimigo) {
                    for (int i = 0; i < numInimigos; i++) {
                        moveInimigo(&inimigos[i], LARGURA, ALTURA);
                        redefineDeslocamento(&inimigos[i]);
                    }

                    framesParaMoverInimigo = 0;  // Reinicia o contador de frames
                }

                // Eliminar inimigos que passaram por recursos
                eliminarInimigo(inimigos, &vida_base, &numInimigos, mapa);

            } else {
                // Verifica se 3 segundos se passaram desde o "Game Over"
                if (GetTime() - gameOverTime >= 3.0) {
                    break; // Sai do loop principal para fechar o jogo
                }
            }

            if (IsKeyPressed(KEY_R)){
                largar_recurso(&jogador);
                // Reproduzir o efeito sonoro
            }


            teletransportar_jogador(&jogador,LARGURA,ALTURA);

            BeginDrawing();
            ClearBackground(GREEN);

            // Desenhar o mapa
            desenharMapa();
            DrawRectangle(jogador.x, jogador.y, LADO, LADO, WHITE);
            for (int i = 0; i < numInimigos; i++) {
                DrawRectangle(inimigos[i].x, inimigos[i].y, LADO, LADO, BLUE);
            }

            // Mostra a quantidade de recursos e vidas na tela
            DrawText(TextFormat("Recursos: %d", recursos_jogador), 10, 10, 20, RED);
            DrawText(TextFormat("Vidas: %d", vidas_jogador), 10, 40, 20, RED);
            DrawText(TextFormat("Base: %d", vida_base), 10, 70, 20, RED);

            // Se o jogo acabou, mostra a mensagem de "Game Over"
            if (gameOver) {
                DrawText("Game Over", LARGURA / 2 - MeasureText("Game Over", 50) / 2, ALTURA / 2 - 50, 50, RED);
            }

            EndDrawing();
        }
    }
    // Descarregar a música e fechar a janela
    UnloadMusicStream(soundtrack);
    UnloadMusicStream(gameover);
    UnloadSound(dropItens);
    UnloadSound(monstroMorre);
    UnloadSound(pegarItens);

    CloseAudioDevice();

    CloseWindow();

    return 0;
}
