/*
Everything from combined_touch_and_accel sketch that doesn't need to be in the main pde
Also has a Conte class that's used to encapsulate communication between the drawing app and the old stuff
*/

/*---------- FROM COMBINED_TOUCH_AND_ACCEL ----------*/
import TUIO.*;
import java.util.Vector;
import java.util.concurrent.*;

// global conte object and tuioClient
Conte conte;
TuioProcessing tuioClient;

class Conte{
  
  // threadsafe queue that holds all touch events after they come in, before processed by main thread
  ConcurrentLinkedQueue<PointHolder> pointHolderQueue;
  boolean debug; // show debug stuff
  
  Conte(PApplet parent, boolean debug){
    // offset info
    screens = new Screens();
    
    // tuio client
    tuioClient = new TuioProcessing(parent); // start tuio client
    
    // osc
    oscSender = new OSCSender();
    
    this.debug = debug;
    
    // init all objects
    pointCollection = new PointCollection();
    pointHolderQueue = new ConcurrentLinkedQueue<PointHolder>();
    accelerometer = new Accel(parent);
    classifier = new Classifier();
    stateManager = new StateManager3D(); // global is in StateManger tab
    
    // Link my stuff to Dan's stuff
    linkClassifierToContact();   
    
    logger = new Logger(participantId, new ConteEventWriter());
    logger.enableLogging(); // no skip stuff here so can do this right away
    logConteStart();
  }
 
  void update(){  
    accelerometer.getData(); // gets accelerometer data
    pointCollection.update(); // pulls data from threadsafe queue, updates map and main queue.
    pointCollection.mergeClassification(); // merges accelerometer data and point data
    stateManager.update(); // updates the current state of conte. Should go after menu.update to check if menu is on
  }
  
  /*
  Does the drawing stuff from the original thing. Have to separate so that the drawing can be done on top
  ie the menu goes on top of the app's drawings
  */
  void draw(){
    if(debug){
      stateManager.drawState();
      pointCollection.drawQueue(); // draws all the points in the queue
    }  
  }
  
  void touchDown(TuioCursor touch){
    PointHolder pointHolder = new PointHolder(touch, PointHolder.downEvent);
    pointHolderQueue.add(pointHolder);
  }
  
  void touchMoved(TuioCursor touch){
    PointHolder pointHolder = new PointHolder(touch, PointHolder.movedEvent);
    pointHolderQueue.add(pointHolder);
  }
  
  void touchUp(TuioCursor touch){
    PointHolder pointHolder = new PointHolder(touch, PointHolder.upEvent);
    pointHolderQueue.add(pointHolder);
  }
  
  /*
  Logs start of conte program
  */
  void logConteStart(){
    String JSONStr = logger.buildJSON("\"type\"", "\"start\"", "\"id\"", str(participantId));
    
    logger.doLog(new JSONEvent("E", "experiment", true, JSONStr));
  }
  
  /*
  Logs end of conte program
  */
  void logConteEnd(){
    String JSONStr = logger.buildJSON("\"type\"", "\"end\"", "\"id\"", str(participantId));    
    logger.doLog(new JSONEvent("E", "experiment", true, JSONStr));
  }
}