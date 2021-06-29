/*
Container class for incoming osc messages
Gives fields proper names
*/

// global Origin
Origin coords;

class Origin {
  PVector coords = new PVector(0,0);
  
  Origin(){
    setOrigin();
  }
  
  void setOrigin(){
    // window location -- needed to scale and translate tuio input
    com.jogamp.nativewindow.util.Point p = new com.jogamp.nativewindow.util.Point(); // empty "vector"
    ((com.jogamp.newt.opengl.GLWindow)surface.getNative()).getLocationOnScreen(p); // put window origin in p
    coords = new PVector(p.getX(), p.getY()); // set static origin
  }
  
  PVector getOrigin(){
    return coords;
  }
}

class AppMessage{
  // event types
  static final int downEvent = 0;
  static final int movedEvent = 1;
  static final int upEvent = 2;
  static final int airEvent = 3; // added for air messages
  
  String conteType; // type of conte event (down, move, up, air)
  int id; // id of point
  int classification; // classification on down (or same as single if air event)
  float x; // last seen x coord of point (-1 if air)
  float y; // last seen y coord of point (-1 if air)
  int yaw; // degrees
  int pitch; // degrees
  int roll; // degrees
  int ax; // x axis acceleration
  int ay; // y axis acceleration
  int az; // z axis acceleration
  int ptType; // type of event for individual point (down, move, up, air)
  int ptClass; // classification for this individual point (still voted on, just not necessarily same as on down)
  int numPts; // number of points in pts
  PVector[] pts = new PVector[numPts]; // point path
  
  /*
  message is the osc message that this object gets its data from
  */
  AppMessage(OscMessage curr){
    conteType = curr.addrPattern();
    id = curr.get(0).intValue(); // id is long which is encoded as float.
    classification = curr.get(1).intValue();
    x = getXCoords(curr.get(2).floatValue());
    y = getYCoords(curr.get(3).floatValue());
    yaw = curr.get(4).intValue();
    pitch = curr.get(5).intValue();
    roll = curr.get(6).intValue();
    ax = curr.get(7).intValue();
    ay = curr.get(8).intValue();
    az = curr.get(9).intValue();
    ptType = curr.get(10).intValue();
    ptClass = curr.get(11).intValue();
    numPts = curr.get(12).intValue();
    int offSet = 13; // for pts array
    pts = new PVector[numPts];
    for(int i = 0; i < numPts; i++){
      int xIndex = offSet + 2*i;
      int yIndex = offSet + 2*i + 1;
      float xVal = getXCoords(curr.get(xIndex).floatValue());
      float yVal = getYCoords(curr.get(yIndex).floatValue());
      PVector currVector = new PVector(xVal, yVal);
      pts[i] = currVector;
    }
  }
  
  float getXCoords(float x){
    PVector origin = coords.getOrigin();
    return (x * displayWidth - origin.x);
  }
  
  float getYCoords(float y){
    PVector origin = coords.getOrigin();
    return (y * displayHeight - origin.y);
  }
  
}