/* 
    Nibbles Game in Turbo C
    
    by George M. Tzoumas
    
    July 6, 2001
    
    (designed and written within 2 hours ;-))

This program is distributed in the hope that it will be useful, 
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
Use this software AT YOUR OWN RISK.

*/

#include<conio.h>
#include<stdlib.h>
#include<string.h>
#include<time.h>
#include<dos.h>

typedef struct {
    int x, y;
} TPoint;

#define BMAX 500
#define BOARD_W 80
#define BOARD_H 49
#define BSTR "Û"

/* LDRU */

typedef enum {LEFT, DOWN, RIGHT, UP} direction;
#define S_OK       0
#define S_GAMEOVER 1

int delta_x[4] = {-1, 0, 1, 0};
int delta_y[4] = {0, 1, 0, -1};
int skins[] = {LIGHTGREEN, LIGHTMAGENTA, LIGHTBLUE};

typedef struct {
    TPoint body[BMAX];
    TPoint tail;
    int len, score, grow, state, id, index;
    int speed;
    int sc;
    direction dir;
    int mvlock;
} TPlayer;


#define MAXPLAYERS 3

int PLAYERS;

TPlayer pl[MAXPLAYERS];
TPoint pnum;
int num;
int gameload;

int visible(TPoint p)
{
    return p.x > 0 && p.y > 1 && p.x <= BOARD_W && p.y <= BOARD_H+1;
}

void pl_init(TPlayer *p, int aid, int index)
{
    p->len = 2;
    memset(p->body, 0, BMAX);
    p->body[0].x = (int) (index* (1.0*BOARD_W / PLAYERS) + 1.0);
    p->body[0].y = BOARD_H / 2 + 1;
    p->body[1].x = p->body[0].x+1;
    p->body[1].y = p->body[0].y;
    p->tail = p->body[0];
    p->grow = 0;
    p->state = S_OK;
    p->id = aid;
    p->index = index;
    p->dir = RIGHT;
    p->speed = 1;
    p->sc = p->speed;
    p->mvlock = 0;
}

void pl_draw(TPlayer *p)
{
    int i;
    if (visible(p->tail)) {
        gotoxy(p->tail.x, p->tail.y);
        cputs(" ");
    }
    for (i=0; i<p->len; i++) {
        if (visible(p->body[i])) {
            gotoxy(p->body[i].x, p->body[i].y);
            textcolor(skins[p->index]);
            cputs(BSTR);
          }
    }
}

void pl_move(TPlayer *p, direction adir)
{
    int i;
    if (p->state != S_OK) return;
    p->tail = p->body[0];
    if (p->grow == 0)
      for (i=0; i<p->len-1; i++) p->body[i] = p->body[i+1];
    else p->grow--, i = p->len++;
    p->body[i].x = p->body[i-1].x + delta_x[adir];
    p->body[i].y = p->body[i-1].y + delta_y[adir];
    if (!visible(p->body[i])) p->state = S_GAMEOVER;
    p->mvlock = 0;
}

void status(void)
{
    int i;
    gotoxy(1,1);
    textbackground(BLACK);
    clreol();
    for (i=0; i<PLAYERS; i++) {
        gotoxy((int) (i* (1.0*BOARD_W / PLAYERS) + 1.0), 1);
        textcolor(skins[i]);
        cprintf("PLAYER%d: %d", pl[i].id, pl[i].score);
    }
    textbackground(BLUE);
}

void looses(int player)
{
    int j;
    gotoxy(1,1);
    textbackground(RED);
    textcolor(YELLOW);
    clreol();
    cprintf("PLAYER %d LOOSES!", pl[player].id);
    delay(3000);
    for (j=0; j<PLAYERS; j++) if (j!=player) pl[j].score++;
    textbackground(BLUE);
}

int main(void)
{
    int ch = 0, i, j, k, pc;
    int restart = 0;

    srand(time(NULL));
    textmode(C4350);
    clrscr();
    textcolor(LIGHTCYAN);
    gotoxy(35,20); cputs("NIBBLES v1.1");
    gotoxy(32,22); cputs("Copyright 2001 by");
    gotoxy(32,24); cputs("George M. Tzoumas");
    textcolor(LIGHTGREEN);
    gotoxy(20, 27); cputs("  PLAYER1         PLAYER2         PLAYER3");
    textcolor(GREEN);
    gotoxy(20, 28); cputs("UP     = o      UP     = w      UP     = g");
    gotoxy(20, 29); cputs("DOWN   = l      DOWN   = s      DOWN   = b");
    gotoxy(20, 30); cputs("LEFT   = k      LEFT   = a      LEFT   = v");
    gotoxy(20, 31); cputs("RIGHT  = ;      RIGHT  = d      RIGHT  = n");
    gotoxy(20, 32); cputs("SPEED+ = i      SPEED+ = q      SPEED+ = f");
    gotoxy(20, 33); cputs("SPEED- = p      SPEED- = e      SPEED- = h");
    textcolor(LIGHTBLUE);
    gotoxy(30, 38); cputs("How many players [1..3] ? ");
    while (kbhit()) getch();
    do {
        ch = getch();
    } while (ch < '1' || ch > '3');
    PLAYERS = ch-'0';

    textbackground(BLUE);
    clrscr();

    for (i=0; i<PLAYERS; i++) pl_init(&pl[i], i+1, i);
    gameload = PLAYERS;
    for (i=0; i<PLAYERS; i++) pl[i].score = 0;
    status();
    for (i=0; i<PLAYERS; i++) pl_draw(&pl[i]);
    pnum.x = rand() % BOARD_W + 1;
    pnum.y = rand() % BOARD_H + 2;
    num = rand() % 9 + 1;
    pc = 0;
    while (kbhit()) getch();

    while (1) { /* game loop */
        if (kbhit()) ch = getch();
        if (ch == 27) break;
        switch (ch) {
            case 'k': if (pl[0].mvlock == 0 && pl[0].dir != RIGHT) {
                          pl[0].dir = LEFT;
                          pl[0].mvlock = 1;
                      }
                      break;
            case 'l': if (pl[0].mvlock == 0 && pl[0].dir != UP) {
                          pl[0].dir = DOWN;
                          pl[0].mvlock = 1;
                      }
                      break;
            case ';': if (pl[0].mvlock == 0 && pl[0].dir != LEFT) {
                          pl[0].dir = RIGHT;
                          pl[0].mvlock = 1;
                      }
                      break;
            case 'o': if (pl[0].mvlock == 0 && pl[0].dir != DOWN) {
                          pl[0].dir = UP;
                          pl[0].mvlock = 1;
                      }
                      break;
            case '8': pl[0].grow += 9; break;
            case 'i': pl[0].speed++; gameload++; break;
            case 'p': if (pl[0].speed>1) {pl[0].speed--; gameload--;}
                      break;
        }
        if (PLAYERS >=2 ) switch(ch) {
            case 'a': if (pl[1].mvlock == 0 && pl[1].dir != RIGHT) {
                          pl[1].dir = LEFT;
                          pl[1].mvlock = 1;
                      }
                      break;
            case 's': if (pl[1].mvlock == 0 && pl[1].dir != UP) {
                          pl[1].dir = DOWN;
                          pl[1].mvlock = 1;
                      }
                      break;
            case 'd': if (pl[1].mvlock == 0 && pl[1].dir != LEFT) {
                          pl[1].dir = RIGHT;
                          pl[1].mvlock = 1;
                      }
                      break;
            case 'w': if (pl[1].mvlock == 0 && pl[1].dir != DOWN) {
                          pl[1].dir = UP;
                          pl[1].mvlock = 1;
                      }
                      break;
            case '1': pl[1].grow += 9; break;
            case 'q': pl[1].speed++; gameload++; break;
            case 'e': if (pl[1].speed>1) {pl[1].speed--; gameload--;}
                      break;
        }
        if (PLAYERS >=3) switch(ch) {
            case 'v': if (pl[2].mvlock == 0 && pl[2].dir != RIGHT) {
                          pl[2].dir = LEFT;
                          pl[2].mvlock = 1;
                      }
                      break;
            case 'b': if (pl[2].mvlock == 0 && pl[2].dir != UP) {
                          pl[2].dir = DOWN;
                          pl[2].mvlock = 1;
                      }
                      break;
            case 'n': if (pl[2].mvlock == 0 && pl[2].dir != LEFT) {
                          pl[2].dir = RIGHT;
                          pl[2].mvlock = 1;
                      }
                      break;
            case 'g': if (pl[2].mvlock == 0 && pl[2].dir != DOWN) {
                          pl[2].dir = UP;
                          pl[2].mvlock = 1;
                      }
                      break;
            case 'r': pl[2].grow += 9; break;
            case 'f': pl[2].speed++; gameload++; break;
            case 'h': if (pl[2].speed>1) {pl[2].speed--; gameload--;}
                      break;
        }
        for (i=0; i<PLAYERS; i++)
          if (pl[i].len + pl[i].grow > BMAX) pl[i].grow = BMAX - pl[i].len;
        ch = 0;

        pl_move(&pl[pc], pl[pc].dir);
        pl_draw(&pl[pc]);
        if (--pl[pc].sc == 0) {
            pl[pc].sc = pl[pc].speed;
            pc = (pc+1) % PLAYERS;
        }


        textattr(15);
        gotoxy(pnum.x, pnum.y);
        cprintf("%d",num);
        textbackground(BLUE);


        for (i=0; i<PLAYERS; i++) for (j=0; j<PLAYERS; j++)
          for (k = pl[j].len-1-(i==j); k >= 0; k--)
            if (memcmp(&pl[i].body[pl[i].len-1], &pl[j].body[k], sizeof(TPoint))==0) {
              pl[i].state = S_GAMEOVER;
              if (k == pl[j].len-1) pl[j].state = S_GAMEOVER;
              break;
            }

        for (i=0; i<PLAYERS; i++) if (pl[i].state == S_GAMEOVER) {
            looses(i);
            restart = 1;
        }
        for (i=0; i<PLAYERS; i++) {
            if (memcmp(&pl[i].body[pl[i].len-1], &pnum, sizeof(TPoint)) == 0) {
                pl[i].grow += num;
                pl[i].score++;
                pnum.x = rand() % BOARD_W + 1;
                pnum.y = rand() % BOARD_H + 2;
                num = rand() % 9 + 1;
                break;
            }
        }

        if (restart) {
            clrscr();
            for (i=0; i<PLAYERS; i++) pl_init(&pl[i], i+1, i);
            gameload = PLAYERS;
            while (kbhit()) getch();
            restart = 0;
        }
        status();
        delay(60.0/gameload);
    }
    textmode(C80);
    return 0;
}

