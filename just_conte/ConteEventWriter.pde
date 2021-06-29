class ConteEventWriter extends EventWriter{
  // flush freq
  int lastFlushTime = 0; // last time automatic flush was done
  final int flushFreq = 5000; // how often must flush buffer
  
  ConteEventWriter() {
    super();
  }
  
  void logSchema(){
    String[] schemaArr = {
    "# CONTE ",
    "#<time>,E,experiment,{type:start, id:<participantId>}",
    "#<time>,E,experiment,{type:end, id:<participantId>}",
    "schema,{type:I, subtype:t, description:touch, data:[{name:id, type:long}, {name:event, type:str, description:U/D/M}, {name:x, type:int}, {name:y, type:int}]}",
    "schema,{type:I, subtype:a, description:accelerometer, data:[{name:x, type:int}, {name:y, type:int}, {name:z, type:int}, {name:roll, type:int}, {name:pitch, type:int}, {name:yaw, type:int}]}"
    };
    for(String schemaStr : schemaArr){
      this.writer.print(schemaStr+"\n");
    }
    super.logSchema();
  }
  
  /*
  Flushes log every few seconds since there are no real flush events here
  */
  void update(){
    int currTime = millis();
    int elapsedFlushTime = currTime - lastFlushTime;
    if(elapsedFlushTime > flushFreq){
      lastFlushTime = currTime;
      super.flush();
    }
  }
}