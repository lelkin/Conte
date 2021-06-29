/*
Used to log stuff
Based off of Terence Dickson's code
*/

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.io.FileWriter;
import java.io.PrintWriter;

/*---------- LOGGER -----------*/

Logger logger; // global logger object

class Logger{
  EventWriter eventWriter = null;
  boolean loggingEnabled = false; // gets turned on on game start
  int participantId;
  
  /*
  Input: participantId is an 1 or 2 digit int representing the participant number
         eventWriter is the EventWriter object (CUSTOM CLASS THAT'S NOT A JAVA THING) used by this log to write events
  */
  Logger(int participantId, EventWriter eventWriter){
    this.participantId = participantId;
    this.eventWriter = eventWriter;
    //createFileAndLogSchema();
  }
  
  /*
  Creates the logger file and logs the schema (if it should be logged)
  Input: startStage, startBlock, startEnemy: start point, 1-indexed. Used for filename.
  */
  void createFileAndLogSchema(int startStage, int startBlock, int startEnemy){
    DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd-HH-mm-ss");
    String time = dateFormat.format(Calendar.getInstance().getTime());
    String id = nf(participantId, 2); // 2 for 2 digits
    // file name
    String filename;
    String dirName = retentionTest ? String.format("log/P%s", id) : String.format("log/P%s/Originals", id);
    if(retentionTest){
      filename = String.format("log/P%s/P%s_%s_%d_game_retention_%d_%s.txt", id, id, gameType, numCommands, retentionNum, time);
      println(filename);
    } else {
      // Commented out august 8, 2018
      //filename = String.format("log/P%s/Originals/P%s_%s_%d_game_%s.txt",id, id, gameType, numCommands, time);
      
      //// Changed to this august 8, 2018
      filename = String.format("log/P%s/Originals/P%s_%s_%d_game_stage%d_block%d_task%d_%s.txt",id, id, 
                                 gameType, numCommands, startStage, startBlock, startEnemy, time);
    }
    this.eventWriter.createFile(filename, dirName);
    println("Logging to", filename);
    eventWriter.logSchema();
  }
  
  /*
  Logs an event
  Input: event is the event to log
  */
  void doLog(Event event){
    if(loggingEnabled){
      eventWriter.doLog(System.currentTimeMillis(), event);
    }
  }
  
  /*
  Enable logging.
  Also creates file and logs schema if this has not already been done
  Input: startStage, startBlock, startEnemy: start point, 1-indexed. Read from skip file.
  */
  void enableLogging(int startStage, int startBlock, int startEnemy){
    loggingEnabled = true;
    
    if(!this.eventWriter.isFileCreated()){
      createFileAndLogSchema(startStage, startBlock, startEnemy);
    }
  }
  
  /*
  Disable logging
  */
  void disableLogging(){
    loggingEnabled = false;
  }
  
  /*
  To query if logger is enabled
  */
  boolean isEnabled(){
    return loggingEnabled;
  }
  
  /*
  Input format: label, value, label, value,...
  Input: Strings in the order of label, value pairs
  Output: valid JSON string
  */
  String buildJSON(String... args){
    StringBuilder result = new StringBuilder();
    result.append("{");
    for(int i = 0; i < args.length; i+=2){
      String label = args[i];
      String value = args[i+1];
      result.append(label);
      result.append(":");
      result.append(value);
      result.append(",");
    }
    if(args.length > 0){
      result.deleteCharAt(result.length() - 1); // delete comma at end
    }
    result.append("}");
    return result.toString();
  }
  
  /*
  Builds and single JSON array containing args and returns it
  Input: Strings to be put into an array
  Output: A JSON array containing the elements of args
  */
  String buildJSONArr(String... args){
    StringBuilder result = new StringBuilder();
    result.append("[");
    for(int i = 0; i < args.length; i++){
      result.append(args[i]);
      result.append(",");
    }
    if(args.length > 0){
      result.deleteCharAt(result.length() - 1); // remove comma at end
    }
    result.append("]");
    return result.toString();
    // OLD
  }
}

/*---------- LOG EVENT -----------*/


/*
An interface for anything which can be recorded in the logfile.
*/

interface Event {  
  /*
   A unique identifier that can be used to identify the class of this event.
   Output: the unique identifier
   */
  String eventType();
  
  /*
  A comma delineated string containing all the extra parameters specific to the event. 
  One parameter might be a JSON str
  Output: the string
  */
  String details();
  
  /*
  Returns true if the logger should be flushed immediately after this event.
  If this is false, the buffer will not be flushed until it receives a flush event.
  Output: true if should flush, false otherwise
  */
  boolean isFlushEvent();
}

/*
Log Input events
*/
class InputEvent implements Event{
  String subtype;
  long id;
  String touchType;
  int x;
  int y;
  InputEvent(String subtype, long id, String touchType, int x, int y){
    this.subtype = subtype;
    this.id = id;
    this.touchType = touchType;
    this.x = x;
    this.y = y;
  }
  String eventType(){ return "I"; }
  String details(){
    String result = String.format("%s,%d,%s,%d,%d", subtype, id, touchType, x, y);
    return result;
  }
  boolean isFlushEvent(){ return false; }
}

/*
Log conte events
Log format: I,c,id,U/D/M/C,x,y,classification
(U: Up, D: Down, M: Move, C: Cancel)
*/
class ConteInputEvent extends InputEvent{
  static final String subtype = "c";
  Contact contact; // conte contact point
  ConteInputEvent(long id, String touchType, float x, float y, Contact contact){
    super(subtype, id, touchType, int(x), int(y));
    this.contact = contact;
  }
  String details(){
    String result = super.details();
    result = String.format("%s,%s", result, contact);
    return result;    
  }
}

/*
Log multipoint events
Log format: I,mp,id,U/D/M,x,y,classification
Note that U,D,M are t U,D,M not conte events
id is the id of the point that U,D,M pertains to for this entry
x,y are the average coordinates of all points in contact with the screen
*/
class MultiPointInputEvent extends InputEvent{
  static final String subtype = "mp";
  Contact contact; // conte contact point
  MultiPointInputEvent(long id, String touchType, float x, float y, Contact contact){
    super(subtype, id, touchType, int(x), int(y));
    this.contact = contact;
  }
  String details(){
    String result = super.details();
    result = String.format("%s,%s", result, contact);
    return result;    
  }
}

// old flat menu
///*
//Log menu events
//Log format: T,m,U/D/M,id1,x1,y1,id2,x2,y2,degs,B/W
//T for technique
//m for menu
//U/D/M Up Down Move
//id1 and id2 are the touch ids of the two menu end points on the screen
//(x1, y1), (x2,y2) are locations of end point contact points on screen
//degs menu rotation
//B/W: black side, white side
//*/
//class MenuTechniqueEvent implements Event{
//  static final String subtype = "m"; 
//  String eventType; // U/M/D
//  long id1;
//  int x1;
//  int y1;
//  long id2;
//  int x2;
//  int y2;
//  int degs;
//  Contact side; // B/W
//  MenuTechniqueEvent(String eventType, long id1, int x1, int y1, long id2, int x2, int y2, int degs, Contact side){
//    this.eventType = eventType;
//    this.id1 = id1;
//    this.x1 = x1;
//    this.y1 = y1;
//    this.id2 = id2; 
//    this.x2 = x2;
//    this.y2 = y2;
//    this.degs = degs;
//    this.side = side;
//  }
//  String eventType(){ return "T"; }
//  String details(){
//    return String.format("%s,%s,%d,%d,%d,%d,%d,%d,%d,%s", subtype, eventType, id1, x1, y1, id2, x2, y2, degs, side);
//  }
//  boolean isFlushEvent(){ return false; }
//}

/*
Log menu events
Log format: T,m,A/D,id1,x1,y1,id2,x2,y2,degs,B/W
T for technique
m for menu
A/D/O for activate/deactivate/open
NOTE: Activate and deactivate are on key pressed and released respectively
      Open is when the menu is actually DISPLAYED on the screen, after the delay time is finished
*/
class MenuTechniqueEvent implements Event{
  static final String subtype = "m"; 
  String menuType; // A/D
  MenuTechniqueEvent(String menuType){
    this.menuType = menuType;
  }
  String eventType(){ return "T"; } // for technique
  String details(){
    return String.format("%s,%s", subtype, menuType);
  }
  boolean isFlushEvent(){ return false; }
}

/*
Logs menu calibration
Log format: T,c,oldyaw,newyaw
T for technique
c for calibrate
*/
class CalibrateTechniqueEvent implements Event{
  static final String subtype = "c";
  int oldYaw;
  int newYaw;
  CalibrateTechniqueEvent(int oldYaw, int newYaw){
    this.oldYaw = oldYaw;
    this.newYaw = newYaw;
  }
  String eventType(){ return "T"; } // for technique
  String details(){
    return String.format("%s,%d,%d", subtype, oldYaw, newYaw);
  }
  boolean isFlushEvent(){ return false; }
}

/*
Logs menu selections
Used by fast tap technique.
A selection can be made on the menu and anohter one made before the menu is closed
The final selection made will be the command issued but this tracks all selections made on the menu
*/
class MenuSelectionTechniqueEvent implements Event{
  static final String subtype = "ms";
  Contact contact;
  MenuSelectionTechniqueEvent(Contact contact){
    this.contact = contact;
  }
  String eventType(){ return "T"; } // for technique
  String details(){
    return String.format("%s,%s", subtype, contact);
  }
  boolean isFlushEvent(){ return false; }
}

/*
Log any event with the format: type,subtype,JSON
Eg: E,block,JSON
*/
class JSONEvent implements Event{
  String type;
  String subtype;
  boolean flushEvent;
  String JSON;
  JSONEvent(String type, String subtype, boolean flushEvent, String JSON){
    this.type = type;
    this.subtype = subtype;
    this.flushEvent = flushEvent;
    this.JSON = JSON;
  }
  String eventType(){ return type; }
  String details(){
    return String.format("%s,%s", subtype, JSON);
  }
  boolean isFlushEvent(){ return flushEvent; }
}

/*---------- EVENT WRITER -----------*/

/*
A writer that prints output to a log file. The format is a series of lines:
  timestamp, event, details
The timestamp is the system time in milliseconds when the event occured
The event is a unique identifier saying what kind of event it is
The details are the event-specific details, sometimes containing JSON.
*/
class EventWriter{
  PrintWriter writer;
  ArrayList<String> buffer;
  boolean fileCreated = false; // will be turned to true once createFile is successfully executed
  EventWriter() {
      this.buffer = new ArrayList<String>();
  }
  
  void createFile(String filename, String dirName){
    try {
      // create dir if not exists
      File dir = new File(sketchPath(dirName));
      if(!dir.exists()){
        dir.mkdirs();
      }
      // create new fileR
      File file = new File(sketchPath(filename));
      this.writer = new PrintWriter(new FileWriter(file));
      fileCreated = true;
    } catch (IOException ex) {
      println("Uncaught exception:");
      println(ex);
      System.exit(0);
    }
  }
  
  /*
  Returns true if the eventwriter file has been created, false otherwise.
  */
  boolean isFileCreated(){
    return fileCreated;
  }
  
  void doLog(long timestamp, Event event) {
    this.buffer.add(String.format("%d,%s,%s\n", timestamp, event.eventType(), event.details())); 
    if (event.isFlushEvent()) {
      for (String line: this.buffer) {
        this.writer.print(line);
      }
      this.buffer.clear();
      this.writer.flush();
    }
  }
  
  /*
  Logs schema to file
  */
  void logSchema(){
    this.writer.print("START LOG\n");
    this.writer.flush();
  }  
}