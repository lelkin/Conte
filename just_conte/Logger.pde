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
  
  /*
  Input: participantId is an 1 or 2 digit int representing the participant number
  */
  Logger(int participantId, EventWriter eventWriter){
    DateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd-HH-mm-ss");
    String time = dateFormat.format(Calendar.getInstance().getTime());
    String id = nf(participantId, 2); // 2 for 2 digits
    // file name
    String filename;
    String dirName = String.format("log" + File.separator + "P%s", id);
    if(retentionTest){
      filename = String.format("log" + File.separator  + "P%s" + File.separator + "P%s_%s_%d_conte_retention_%d_%s.txt", id, id, gameType, numCommands, retentionNum, time);
      println(filename);
    } else {
      filename = String.format("log" + File.separator + "P%s" + File.separator + "P%s_%s_%d_conte_%s.txt",id, id, gameType, numCommands, time);
    }   
    this.eventWriter = eventWriter;
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
  
  void update(){
    if(loggingEnabled){
      eventWriter.update();
    }
  }
  
  /*
  Enable logging
  */
  void enableLogging(){
    loggingEnabled = true;
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
  boolean isFlush;
  InputEvent(String subtype, long id, String touchType, int x, int y, boolean isFlush){
    this.subtype = subtype;
    this.id = id;
    this.touchType = touchType;
    this.x = x;
    this.y = y;
    this.isFlush = isFlush;
  }
  String eventType(){ return "I"; }
  String details(){
    String result = String.format("%s,%d,%s,%d,%d", subtype, id, touchType, x, y);
    return result;
  }
  boolean isFlushEvent(){ return isFlush; }
}

/*
Log raw touch input
Log format: I,t,id,U/D/M,x,y
*/
class TouchInputEvent extends InputEvent{
  static final String subtype = "t";
  TouchInputEvent(long id, String touchType, float x, float y){
    // flush true for up. can't have as separate var, this thing done must be calling super
    super(subtype, id, touchType, int(x), int(y), false);
  }
}

/*
Log accelerometer events
Log format: I,a,x,y,z,roll,pitch,yaw
*/
class AccelInputEvent implements Event{
  static final String subtype = "a";
  int x;
  int y;
  int z;
  // angles as degrees
  int roll;
  int pitch;
  int yaw;
  AccelInputEvent(int x, int y, int z, int roll, int pitch, int yaw){
    this.x = x;
    this.y = y;
    this.z = z;
    this.roll = roll;
    this.pitch = pitch;
    this.yaw = yaw;
  }
  String eventType(){ return "I"; }
  String details(){
    return String.format("%s,%d,%d,%d,%d,%d,%d", subtype, x, y, z, roll, pitch, yaw);
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
  int lastWrite; // last time write done
  int maxWriteDelay = 5000;
  
  PrintWriter writer;
  ArrayList<String> buffer;
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
      
      // create new file
      File file = new File(sketchPath(filename));
      this.writer = new PrintWriter(new FileWriter(file));
    } catch (IOException ex) {
      println("Uncaught exception:");
      println(ex);
      System.exit(0);
    }
  }
  
  void doLog(long timestamp, Event event) {
    this.buffer.add(String.format("%d,%s,%s\n", timestamp, event.eventType(), event.details())); 
    if (event.isFlushEvent() || (millis() - lastWrite > maxWriteDelay)) {
      for (String line: this.buffer) {
        this.writer.print(line);
      }
      this.buffer.clear();
      this.writer.flush();
      lastWrite = millis();
    }
  }
  
  /*
  Called every frame in just_conte
  */
  void update(){}
  
  /*
  Flushes buffer
  */
  void flush(){
    for (String line: this.buffer) {
      this.writer.print(line);
    }
    this.buffer.clear();
    this.writer.flush();
  }
  
  /*
  Logs schema to file
  */
  void logSchema(){
    this.writer.print("START LOG\n");
    this.writer.flush();
  }  
}