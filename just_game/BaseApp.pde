/*
Parent class for DrawApp and GameApp
Also creates touch2Tuio Process
*/

import de.looksgood.ani.*;

// touch2Tuio process stuff
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.BufferedWriter;

class BaseApp extends App{
  // Tuio
  Process tuioServer; // for touch2Tuio
  BufferedReader tuioServerOut; // reading from touch2Tuio Process
  
   // current command
  int currClass; // Classifier.classification for the current classification
  Contact currContact; // the current contact
  Command currCmd; // the command associated with this contact point
  Stroke currStroke; // The stroke we're currently drawing
  MultiPoint currMultiPoint; // tracking info about points with multiple contact points
  Icon icon; // icon for feedback
  PGraphics pg; // dummy here so that stroke stuff still works
  
  int bgd; // background colour - assume some shade of grey
  boolean showInfo = false;
  
  // colour
  int r = 0;
  int g = 0;
  int b = 0;
  
  // feedback
  final float feedbackTime = 2; // how many seconds for icon feedback to be displayed
  boolean inputEnabled = true; // when false only log input
  
  //Queue<PVector[]> testQueue; // TEST
  
  BaseApp(PApplet parent, EventWriter eventWriter){
    // tuio server
    setupTuio(); // start tuio server
    
    // origin so draws in right spot
    coords = new Origin();
    
    logger = new Logger(participantId, eventWriter);
    bgd = 100;
    classifier = new Classifier();
    setupCommands();
    setupCommandToDraw();
    linkClassifierToContact();
    resetClassification();
    currMultiPoint = null;
    icon = null;
    Ani.init(parent);   
    pg = createGraphics(width,height);
    if(gameType.equals("FastTap")){
      menu = new MenuFastTap();
    } else if(gameType.equals("Conte")){
      menu = new Menu3D();
    }
    //testQueue = new LinkedList<PVector[]>(); // TEST
  }
  
  void setupTuio(){
    // run touch2tuio
    String fullPath = "C:\\Users\\Lisa\\Documents\\GitHub\\Conte\\conte2\\Touch2Tuio\\x64\\Release\\Touch2Tuio_x64.exe";
    //String fullPath = "C:\\Users\\Lisa Elkin\\Documents\\GitHub\\conte2\\Touch2Tuio\\x64\\Release\\Touch2Tuio_x64.exe";
    //tuioServer = exec(fullPath, windowName, myIP, "3333"); // new process
    tuioServer = exec(fullPath, windowName); // new process
    tuioServerOut = new BufferedReader(
            new InputStreamReader( tuioServer.getInputStream())); // normal tuioServer output, yes output is called input
    delay(100); // delay to read server startup messages
    // read sartup message
    try{
      while(tuioServerOut.ready()){
        println(tuioServerOut.readLine());
      }
    }
    catch(IOException exception){
    }
  }
  
  /*
  Destructor. Called when program exits.
  Needed to shut down touch2tuio server and read final log from it
  */
  void destroy(){    
    // getOutputStream is the input stream to the subprocess
    // write newline to shut down touch2tuio
    BufferedWriter tuioServerIn = new BufferedWriter(
            new OutputStreamWriter( tuioServer.getOutputStream()));
    try{
      tuioServerIn.newLine();
      tuioServerIn.flush();
    }
    catch(IOException exception){
    }
    
    // destroy the process
    tuioServer.destroy();
    
    // read result of destroying process and close streams
    try{
      while(tuioServerOut.ready()){
        println(tuioServerOut.readLine());
      }    
      tuioServerIn.close();
      tuioServerOut.close();
    }
    catch(IOException exception){
    }
  }
  
  /*
  Game logs when it gets delay. This doesn't do anything
  */
  void delayed(){
  }
  
  
  // TEST
  //  void addToTestQueue(PVector[] pts){
  //    if(testQueue.size() >= 50){
  //      testQueue.remove();
  //    }
  //    testQueue.add(pts);
  //  } 
  //  
  //  void drawTestQueue(){
  //    stroke(255);
  //    strokeWeight(2);
  //    for(PVector[] pts : testQueue){
  //      for(int i = 0; i < pts.length - 1; i++){
  //        PVector point1 = pts[i];
  //        PVector point2 = pts[i+1];
  //        line(point1.x, point1.y, point2.x, point2.y);
  //      }
  //    }
  //    
  //
  //  }
    // END TEST
  
  
  /*---------- UPDATE ----------*/ 
  /*
  Called by stateManager when conte is now touching the screen
  Input: classification is the Classifier classification of the point
         pts is the array of points - needs to be an array since sometimes it bundles multiple into one point
         id is the id number of the touch point
         eventType is a PointHolder.eventType and it's down, move, or up as determined by SMT
           might not use this info but might need it later
  */
  void down(int classification, PVector[] pts, long id, int eventType){
    setClassification(classification);
    
    // log this down event
    logger.doLog(new ConteInputEvent(id, "D", pts[pts.length-1].x, pts[pts.length-1].y, currContact));
    
    if(inputEnabled){
      // if contact valid
      if(currContact != null && isActive(currContact)){   
        if(currCmd != null){ // black and white aren't mapped to anything - they'll be null
          if(currContact.numPts > 1){
            doNewMultiPoint(pts, id, eventType);
          }      
          // all non-draw are executed on up
          if(currCmd.drawCmd){
            doNewStroke(pts, id);
          }
        }
      }
    }
    
    //addToTestQueue(pts); // TEST
  }
  
  /*
  Called by stateManager on a move event. Note this might be a touch down but we've already seen down for conte
  Input: classification is the Classifier classification of the point
         pts is the array of points - needs to be an array since sometimes it bundles multiple into one point
  */
  void move(PVector[] pts, long id, int eventType){
    // log this move event
    logger.doLog(new ConteInputEvent(id, "M", pts[pts.length-1].x, pts[pts.length-1].y, currContact));
    
    if(inputEnabled){
      // if contact valid
      if(currContact != null && isActive(currContact)){
        if(currCmd!=null){
          if(currCmd.drawCmd){
            updateStrokeWrapper(pts, id, eventType);
          } 
          // updateStrokeWrapper handles the update for draw commands - need to handle it explicitly for non-draw
          else if(currContact.numPts > 1){
            currMultiPoint.update(id, pts, eventType);
          }
        } // currCmd != null
      }
    }
    
    //addToTestQueue(pts); // TEST
  }
  
  /*
  Called by stateManager when conte is no longer touching the screen
  Input: pts is an array of the newest points we just saw for this contact poin
         id is the id number of the touch point
         eventType is a pointHolder event - downEvent, movedEvent, upEvent
  */
  void up(PVector[] pts, long id, int eventType){
    // log this up event
    logger.doLog(new ConteInputEvent(id, "U", pts[pts.length-1].x, pts[pts.length-1].y, currContact)); 
    
    if(inputEnabled){
      // if contact valid do below
      if(currContact != null && isActive(currContact)){   
        if(currCmd!=null){
          if(currCmd.drawCmd){
            updateStrokeWrapper(pts, id, eventType);
            cleanUpDrawCmd(pts[pts.length-1]);
          } else {
            executeCommandWrapper(pts, id, eventType);
          }
        }
      } 
      // using invalid point is wrong
      else {
        countAsWrong(currContact, pts[pts.length-1]);
      }
      resetClassification();
    }
  }
  
  /*
  Called by stateManager when we should delete the points we've just seen (ie on a roll up to menu).
  Input: pts is an array of the newest points we just saw for this contact poin
         id is the id number of the touch point
         eventType is a pointHolder event - downEvent, movedEvent, upEvent
  Note: Input only needed for logger
  */
  void cancel(PVector[] pts, long id){
    // log this cancel event
    logger.doLog(new ConteInputEvent(id, "C", pts[pts.length-1].x, pts[pts.length-1].y, currContact));
    if(inputEnabled){
      resetClassification();
    }
  }
  
  /*
  Backup in case no pts on updateQueue to send value with
  I don't actually think this will ever get called
  */
  void cancel(){
    logger.doLog(new ConteInputEvent(0, "C", 0, 0, currContact));
    if(inputEnabled){
      resetClassification();
    }
  }
  
  /*----------- HELPERS FOR DOWN, MOVE, UP, AND CANCEL ----------*/
  
  /*
  Sets the currClass and currCmd fields
  Input: classification is the current classification
  */
  void setClassification(int classification){
    currClass = classification;
    currContact = classToContact.get(currClass);
    currCmd = commands.get(currContact);
  }
    
  /*
  Sets currClass and currCmd back to their default states
  */
  void resetClassification(){
    currClass = -1;
    currCmd = null;
    currStroke = null;
    currContact = null;
  }
  
  // used by game to count enemy as wrong
  void countAsWrong(Contact c, PVector pt){}
  
  /*
  Returns true if this contact is active
  False otherwise
  Input: contact is the contact to check
  Output: true or false
  */
  boolean isActive(Contact contact){
    if(contact != null){
      boolean onActiveEnd = (numCommands == bigCommands) || contact.end.equals("W");
      return onActiveEnd;
    } else {
      return false;
    }
  }
  
   
  /*
  Given a command that requires a stroke, start the new stroke and add the new pts to it
  Input: pts is the array of points to add to the the stroke
         id is the id number of the point
  Note: Don't update stroke on down if it's a multi contact point stroke
  */
  void doNewStroke(PVector[] pts, long id){
    currStroke = new Stroke(currCmd, r, g, b);
    if(currContact.numPts == 1){
      updateStroke(pts,id);
    }
  }
  
  /*
  Updates singlepoint and multipoint stroke. Also updates multipoint for multi point draw commands
  Input: pts is the array of most recently seen PVectors for this point
         id is the id of this point
         eventType is a pointHolder event - up down move
  Note: Always only called for draw commands
  */
  void updateStrokeWrapper(PVector[] pts, long id, int eventType){        
    // multiPoint - update multipoint and stroke
    if(currContact.numPts > 1){
      PVector avgPt = currMultiPoint.update(id, pts, eventType);
      if(avgPt != null){
        updateMultiStroke(avgPt, id);
      }
    } 
    
    // non-multipoint
    else{
      updateStroke(pts, id);
    }
  }
  
  /*
  Update the current stroke
  Input: pts is the array of points to add to the stroke
         id is the id number of the point
  */
  void updateStroke(PVector[] pts, long id){
    currStroke.update(pts, id);
  }
  
  /*
  Updates the current stroke when it's a multipoint - input is single PVector instead of array
  Input: pt is the single point to update with
         id is the id number of the point
  */
  void updateMultiStroke(PVector pt, long id){
    currStroke.update(pt, id);
  }
  
  /*
  Logs the stroke being done
  */
  void cleanUpDrawCmd(PVector pt){
  }
  
  /*
  Creates a new multipoint and assigns it to currMultiPoint. Also updates it with the input args
  Input: pts is the array of PVectors that we saw on down
         id is the id number of the contact point
         eventType is the type of event this is - it should be down but it's useful to have it to pass it along
  */
  void doNewMultiPoint(PVector[] pts, long id, int eventType){
    currMultiPoint = new MultiPoint(currContact);
    currMultiPoint.update(id, pts, eventType);
  }
  
  /*
  Wrapper for executing commands - it's different for multipoint contact and singlepoint contact
  Input: pts is the array of points we just saw for this contact point
         id is the id of the point (from tuio)
         eventType is the pointHolder eventType - upEvent, movedEvent, downEvent             
  */
  void executeCommandWrapper(PVector[] pts, long id, int eventType){
    if(currContact.numPts > 1){
      PVector avgPt = currMultiPoint.update(id, pts, eventType);
      executeCommand(avgPt);
    } else {
      executeCommand(pts[pts.length -1]);
    }
  }
  
  /*
  Shows feedback for one-time commands
  */
  void executeCommand(PVector pts){
    setupFeedback(pts); // sets up the icon for this command
  }
  
  /*
  Sets up icon and Ani so that new feedback can be drawn
  */
  void setupFeedback(PVector pts){
    icon = new Icon(currCmd.img, pts.x, pts.y);
    Ani.to(icon, feedbackTime, "alpha", 0);
  }
  
  /*
  Draws to screen
  */
  void draw(){
    drawStrokes(); // draw all strokes on screen
    drawFeedback(); // draw feedback for commands
    if(showInfo){
      drawFrameRate();
    }
  }
  
  /*
  Draws currStroke to screen
  */
  void drawStrokes(){
    boolean drawToPg = false; // drawing to canvas
    
    // draw the current stroke if there is one
    if(currStroke != null){
      currStroke.draw(drawToPg);
    }
  }
  
  /*
  Draws feedback for commands
  */
  void drawFeedback(){
    if(icon != null){
      icon.draw();
    }
  }
  
  /*
  Draws the frame rate in the top right corner of the screen
  */
  void drawFrameRate(){
    fill(0); // changed for game
    textAlign(RIGHT, CENTER);
    textSize(30);
    text("frame rate: " + str(int(frameRate)), width-10, 10);    
  }
  
  
  /*---------- GET INFO ----------*/
  
  /*
  returns the single int representing the background colour
  Output: int for background
  Note: will have to change this if it's not some shade of grey
  */
  int getBackground(){
    return bgd;
  }
  
  /*
  returns the current stroke
  */
  Stroke getCurrStroke(){
    return currStroke;
  }
  
  
  /*
  Returns String that is JSON array of contact commmand pairs in successive order 
  ie contact1, command1, contact2, command2 etc..
  */
  String contactCommandJSON(){
    String[] result = new String[2*commands.size()];
    int i = 0;
    for(Contact contact : commands.keySet()){
      result[i] = "\"" + contact.name() + "\"";
      Command command = commands.get(contact);
      result[i+1] = "\"" + command.name + "\"";
      i += 2;
    }
    return logger.buildJSONArr(result);
  }
  
  /*---------- GAME SPECIFIC ----------*/
  void doMenuScoreDeduction(){}
  void disableFeedback(){
  }
  
  /*
  down, move, and up will get called either way. But only log them if input is disabled
  */
  void enableInput(){
    inputEnabled = true;
  }
  void disableInput(){
    inputEnabled = false;
  }
}