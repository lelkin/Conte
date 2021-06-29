/*
Screen origin
Tuio positions come in as [0,1] as ratio of location on entire display
Information needed for proper offsets and scales
*/

Screens screens; // global origin

class Screens{
  // for scaling
  // PPI on Lisa's computer where all thresholds were set
  // DO NOT CHANGE. MACHINE INDEPENDENT!
  final float originalPPI = 165.63;
  
  // this program
  // DO NOT CHANGE. WILL UPDATE ON START
  PVector origin = new PVector(0,0);
  
  // sensor program
  final int sensorW = 2732; // TO CHANGE, jb: 2048, iPad Pro: 2732, lisa: 1920, surface: 2736
  final int sensorH = 2048; // TO CHANGE, jb: 1536, iPad Pro: 2048, lisa: 1080, surface: 1824
  // http://pixensity.com/
  final float sensorPPI = 264.68; // TO CHANGE, jb: 324.05, , iPad Pro: 264.68, lisa: 165.63, surface: 267.34
  final int sensorOriginX = 0;
  final int sensorOriginY = 0;
  
  Screens(){
    //setOrigin(); // don't need this we'll just stick it at 0,0 since they're dummy coords anyway
  }
  
  /*
    Returns actual canvas coordinates of touch.
    TuioCursor coords are [0,1] as a ratio of SCREEN COORDINATES
    Function finds origin of canvas to compute offset
    Input: x and y are the ratio of coordinates wrt screen coordinates of touch sensor
    Output: PVector containing the canvas coordinates of the touch
  */  
  PVector fromSensor(float x, float y){
    float sensorScreenX = x * sensorW - sensorOriginX;
    float sensorScreenY = y * sensorH - sensorOriginY;
    
    // scale touch by scaling factor
    float scaledX = (originalPPI/sensorPPI) * sensorScreenX;
    float scaledY = (originalPPI/sensorPPI) * sensorScreenY;
    
    // scale touch by screen, subtract canvas origin
    float canvasX = scaledX - screens.origin.x;
    float canvasY = scaledY - screens.origin.y;
    
    PVector result = new PVector(canvasX, canvasY);
    return result;   
  }
  
  /*
  scales coords back into sensor [0,1]
  */
  PVector toSensor(float canvasX, float canvasY){
    float scaledX = canvasX - screens.origin.x;
    float scaledY = canvasY - screens.origin.y;
    
    float sensorScreenX = scaledX * (sensorPPI/originalPPI);
    float sensorScreenY = scaledY * (sensorPPI/originalPPI);
    
    float x = (sensorScreenX + sensorOriginX)/sensorW;
    float y = (sensorScreenY + sensorOriginY)/sensorH;
    
    PVector result = new PVector(x,y);
    return result;
  }
  
  
  //void setOrigin(){
  //  // window location -- needed to scale and translate tuio input
  //  com.jogamp.nativewindow.util.Point p = new com.jogamp.nativewindow.util.Point(); // empty "vector"
  //  ((com.jogamp.newt.opengl.GLWindow)surface.getNative()).getLocationOnScreen(p); // put window origin in p
  //  origin = new PVector(p.getX(), p.getY()); // set static origin
  //}
}