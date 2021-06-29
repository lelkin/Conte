// overall globals -- ONLY NEEDED FOR FILE NAME TO MATCH GAME
int participantId = 1;
String gameType = "FastTap";
//String gameType = "Conte";
boolean retentionTest = false; // if true just runs one retention block
int retentionNum = 0; // 0 min, 10 min, 24 hour
final int smallCommands = 9; // incase these change it's easier if they're in variables
final int bigCommands = 26;
final int numCommands = smallCommands;


boolean udpSeen = false; // flag for first udp message to print

// Where to send OSC events
final String remoteIP = "192.168.1.236"; // TO CHANGE, iPad: "192.168.1.96" (lisa: "192.168.1.236"), (surface: "192.168.1.49")
final int remotePort = 12000;

void setup(){  
  //Tuio and Processing setupx
  size(1, 1, P3D);
  surface.setLocation(0,0);
  
  // init everything else
  conte = new Conte(this, false);
}

void draw(){
  conte.update(); // the draw function from the orignal sketch
  conte.draw();
}

/*---------- Tuio calls must be in main class ----------*/
/*---------- Actually using these ----------*/

// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) {
  conte.touchDown(tcur);
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) {
  conte.touchMoved(tcur);
}

// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) {
  conte.touchUp(tcur);
}

/*---------- Dummy, must still be implemented ----------*/
// called when an object is added to the scene
void addTuioObject(TuioObject tobj) {}

// called when an object is moved
void updateTuioObject (TuioObject tobj) {}

// called when an object is removed from the scene
void removeTuioObject(TuioObject tobj) {}

// called when a blob is added to the scene
void addTuioBlob(TuioBlob tblb) {}

// called when a blob is moved
void updateTuioBlob (TuioBlob tblb) {}

// called when a blob is removed from the scene
void removeTuioBlob(TuioBlob tblb) {}

// called at the end of each TUIO frame
void refresh(TuioTime frameTime) {}

/*---------- UDP receive must be in main class ----------*/
void receive( byte[] data ){
  if(!udpSeen){
    println("UDP");
    udpSeen = true;
  }
  //println("receive upd", frameCount);
  if(accelerometer != null){
    accelerometer.receive(data);
  }
}

/*---------- Misc ----------*/
void keyPressed(){
  // q to quit
  if(key == 'q'){
    exit();
  }
}

void exit(){
  println("called exit");
  conte.logConteEnd();
  super.exit();
}