/*
MUST START THIS BEFORE JUST_CONTE
Otherwise will have OSC messages being received and sent to handelers in uninitialized classes on setup
*/

import java.util.*;

// game params CHECK THESE BEFORE RUNNING!!!
int participantId = 1;
int startScore = 0; //when recovering from crash will put in old score
//String gameType = "FastTap";
String gameType = "Conte";
boolean retentionTest = false; // if true just runs one retention block
int retentionNum = 24; // 0 min, 10 min, 24 hour
final int smallCommands = 9; // incase these change it's easier if they're in variables
final int bigCommands = 26;
final int numCommands = bigCommands;

boolean fakeMenu = false; // no clue what that is
boolean mirrored = true; // true for new mirrored conte menu, for fast tap doesn't matter

String windowName = "draw";
// canvas origin. will be (0,0) unless debugging. This is where the top left corner of the window will be
// origin Object is where actual drawing starts which can be different
final int originX = 0;
final int originY = 0;

// Where to listen for OSC events
final String myIP = "192.168.1.236"; // don't need in this program just a nice reminder where conte should send stuff too
final int myPort = 12000;

void setup(){
  //Tuio and Processing setup
  //size(1000,700,P3D);
  fullScreen(P3D);
  surface.setTitle(windowName);
  surface.setAlwaysOnTop(true); // make window always on top
  surface.setLocation(originX,originY);
  //noCursor(); // hide mouse cursior
  
  // init everything else
  oscApp = new OscAppInterface(this); // inits gameApp
  game = new Game(participantId, this);
  background(app.getBackground());
}

void draw(){
  background(app.getBackground());
  menu.drawBackgroundGrid();
  game.update();
  game.draw();
  oscApp.update(); // calls app.draw through a chain of stuff
}

/*---------- Misc ----------*/
void keyPressed(){
  // q to quit
  if(key == 'q'){
    exit();
  } else if(key == 'm'){
    menu.setActive();
  }
  //} else if(key == 'l'){
  //  menu.setInactive();
  //}
  else if(key == 'n'){
    menu.calibrate();
  } else if(key == 'r'){
    menu.toggleReal();
  } else if(key == 'i'){
    game.toggleInfo();
  }
  
  
  // space to start so doesn't conflict with conte
  if(!game.started && !game.skipModeEnabled){
    if(key == ' '){
      game.start();
    } else if(key == 's'){
      println("enabling skip mode");
      game.enableSkipMode();
    }
  }
  // game is in skip mode
  else if(game.skipModeEnabled){
    if(keyCode == RIGHT){
      game.skipBlock();
    } else if(keyCode == DOWN){
      game.skipEnemy();
    } else if(key == ' '){
      game.startFromSkip();
    }
  }
  // resume from break
  else if(game.betweenStageBreak){
    if(key == ' '){
      game.endBreak = true;
    }
  }
}

void keyReleased(){
  if(key == 'm'){
    menu.setInactive();
  }
}

void exit(){
  println("called exit");
  app.destroy();
  game.exit();
  super.exit();
}