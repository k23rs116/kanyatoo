// Processing block puzzle game with scoring, colors, combo, effects, and game over

int SIZE = 8;
int CELL = 60;
int TRAY_H = 140;

color EMPTY = color(255);
color[][] grid = new color[SIZE][SIZE];

boolean gameOver = false;
int score = 0;
int clearEffectTimer = 0;
int combo = 0; // combo counter for consecutive clears

// color palette (colors do NOT affect clearing)
color[] palette = {
  color(255,100,100), color(100,200,100), color(100,150,255),
  color(255,200,100), color(200,120,255), color(120,255,200)
};

// Shapes
boolean[][][] shapes = {
  { {true,false}, {true,false}, {true,true} }, // L
  { {true,true,true},{true,true,true},{true,true,true} }, // 3×3
  { {true},{true},{true} }, // vertical 3
  { {true,true,true} } // horizontal 3
};

int SHAPE_COUNT = shapes.length;
int[] trayShape = new int[3];
color[] trayColor = new color[3];
int[] trayX = new int[3];
int[] trayY = new int[3];
boolean[] dragging = new boolean[3];
int dragOffsetX, dragOffsetY;
float TRAY_SCALE = 0.5;

void settings(){ size(SIZE*CELL, SIZE*CELL+TRAY_H); }
void setup(){ initGrid(); initTray(); }

void initGrid(){ for(int r=0;r<SIZE;r++) for(int c=0;c<SIZE;c++) grid[r][c]=EMPTY; }

void initTray(){ for(int i=0;i<3;i++){ trayShape[i]=(int)random(SHAPE_COUNT); trayColor[i]=palette[(int)random(palette.length)]; trayX[i]=60+i*150; trayY[i]=SIZE*CELL+20; dragging[i]=false; }}

void draw(){ background(240);
  drawGrid(); drawTray(); drawDraggingBlocks(); drawScore();
  if(clearEffectTimer>0){ // simple flash effect that scales with combo
    float alpha = map(clearEffectTimer,0,20,0,120);
    fill(255, alpha); rect(0,0,width,height);
    clearEffectTimer--; }
  if(gameOver){ drawGameOver(); }
}

void drawScore(){ fill(0); textSize(20); textAlign(LEFT,BASELINE); text("Score: "+score, 10, SIZE*CELL+TRAY_H-10);
  if(combo>1){ fill(0); textSize(16); text("Combo x"+combo, 120, SIZE*CELL+TRAY_H-10); }
}

void drawGameOver(){ fill(0,180); rect(0,0,width,height);
  fill(255); textSize(48); textAlign(CENTER,CENTER);
  text("GAME OVER", width/2, height/2 - 40);
  textSize(28);
  text("Score: "+score, width/2, height/2);
  textSize(22);
  text("Click to Continue", width/2, height/2 + 50);
  textAlign(LEFT,BASELINE);
}

void drawGrid(){ for(int r=0;r<SIZE;r++){
    for(int c=0;c<SIZE;c++){
      stroke(0);
      fill(grid[r][c]);
      rect(c*CELL, r*CELL, CELL, CELL);
    }
  }
}

void drawShapeScaled(int si,int x,int y,float s, color col){ boolean[][] sm=shapes[si];
  for(int r=0;r<sm.length;r++){
    for(int c=0;c<sm[0].length;c++){
      if(sm[r][c]){
        fill(col);
        stroke(0);
        rect(x + c*CELL*s, y + r*CELL*s, CELL*s, CELL*s);
      }
    }
  }
}

void drawTray(){ if(gameOver) return;
  for(int i=0;i<3;i++) if(!dragging[i]) drawShapeScaled(trayShape[i], trayX[i], trayY[i], TRAY_SCALE, trayColor[i]);
}

void drawDraggingBlocks(){ for(int i=0;i<3;i++) if(dragging[i]) drawShapeScaled(trayShape[i], mouseX-dragOffsetX, mouseY-dragOffsetY, 1.0, trayColor[i]); }

void mousePressed(){ if(gameOver){ gameOver=false; score=0; combo=0; initGrid(); initTray(); return; }
  for(int i=0;i<3;i++){
    boolean[][] s=shapes[trayShape[i]];
    int w=int(s[0].length*CELL*TRAY_SCALE);
    int h=int(s.length*CELL*TRAY_SCALE);
    if(mouseX>trayX[i]&&mouseX<trayX[i]+w && mouseY>trayY[i]&&mouseY<trayY[i]+h){
      dragging[i]=true;
      // always treat grab as center of the (scaled) shape so placement is consistent
      dragOffsetX=int(w/2);
      dragOffsetY=int(h/2);
    }
  }
}

void mouseReleased(){ if(gameOver) return;
  for(int i=0;i<3;i++) if(dragging[i]){
    boolean[][] s=shapes[trayShape[i]];
    // compute snapped cell position based on mouse center and shape size
    int shapeW = s[0].length * CELL;
    int shapeH = s.length * CELL;
    int snappedX = round((mouseX - shapeW/2) / (float)CELL) * CELL;
    int snappedY = round((mouseY - shapeH/2) / (float)CELL) * CELL;
    int r = snappedY / CELL;
    int c = snappedX / CELL;
    if(canPlace(s,r,c)){
      placeShape(s,r,c,trayColor[i]);
      trayShape[i]=(int)random(SHAPE_COUNT);
      trayColor[i]=palette[(int)random(palette.length)];
      int cleared = checkAndClear();
      if(cleared>0){ clearEffectTimer=20; combo++; score += cleared * combo; }
      else { combo = 0; }
      checkGameOver();
    }
    dragging[i]=false;
  }
}

boolean canPlace(boolean[][] s,int r,int c){
  for(int i=0;i<s.length;i++){
    for(int j=0;j<s[0].length;j++){
      if(s[i][j]){
        int rr=r+i, cc=c+j;
        if(rr<0||rr>=SIZE||cc<0||cc>=SIZE) return false;
        if(grid[rr][cc]!=EMPTY) return false;
      }
    }
  }
  return true;
}

void placeShape(boolean[][] s,int r,int c, color col){
  for(int i=0;i<s.length;i++){
    for(int j=0;j<s[0].length;j++){
      if(s[i][j]) grid[r+i][c+j]=col;
    }
  }
}

// returns number of cleared cells (for scoring)
int checkAndClear(){
  int clearedCells = 0;
  boolean[] rowCleared = new boolean[SIZE];
  boolean[] colCleared = new boolean[SIZE];

  for(int r=0;r<SIZE;r++){
    boolean full=true;
    for(int c=0;c<SIZE;c++) if(grid[r][c]==EMPTY) { full=false; break; }
    if(full){ rowCleared[r]=true; }
  }
  for(int c=0;c<SIZE;c++){
    boolean full=true;
    for(int r=0;r<SIZE;r++) if(grid[r][c]==EMPTY) { full=false; break; }
    if(full){ colCleared[c]=true; }
  }

  for(int r=0;r<SIZE;r++) if(rowCleared[r]){ clearRow(r); clearedCells += SIZE; }
  for(int c=0;c<SIZE;c++) if(colCleared[c]){ clearCol(c); clearedCells += SIZE; }

  return clearedCells;
}

void clearRow(int r){ for(int c=0;c<SIZE;c++) grid[r][c]=EMPTY; }
void clearCol(int c){ for(int r=0;r<SIZE;r++) grid[r][c]=EMPTY; }

void checkGameOver(){
  for(int t=0;t<3;t++){
    boolean[][] s = shapes[trayShape[t]];
    for(int r=0;r<SIZE;r++){
      for(int c=0;c<SIZE;c++){
        if(canPlace(s,r,c)) return;
      }
    }
  }
  gameOver = true;
}
