class GameEventWriter extends EventWriter{
  GameEventWriter(){
    super();
  }
  
  void logSchema(){
    String[] schemaArr = {
    "# CONTE GAME",
    "#<time>,E,experiment,{type:start, id:<participantId>, menuType:<Conte/FastTap>, numStages:<totalNumStages>, stageOrder:[permutation of {slow, medium, fast}], randomSeed:<randomSeed>, numCommands:<numCommands>, contactCommandPairs:<[contact1, command1,...]>}",
    "#<time>,E,experiment,{type:end, id:<participantId>, score:<score>}",
    "#<time>,E,experiment,{type:delay, stageNum:<stageNum>, blockNum:<blockNum>, trialNum:<trialNum>, score:<score>}",
    "#<time>,E,stage,{type:start, num:<stageNum>, stageType:<slow, medium, fast>, dropTime:<numSeconds>, numBlocks:<numBlocks>}",
    "#<time>,E,stage,{type:end, num:<stageNum>}",
    "#<time>,E,block,{type:start, stageNum:<stageNum>, num:<blockNum>, dropTime:<numSeconds>, taskOrder:[cmdName1,cmdName2,...]}",
    "#<time>,E,block,{type:end, num:<blockNum>}",
    "#<time>,E,task,{type:start, command:<cmd.name>, currScore:<currScore>, stageNum:<stageNum>, blockNum:<blockNum>, num:<enemyNum>, currScore:<score>, dropTime:<numSeconds>, pixelsPerSecond:<pixelsPerSecond>, startX:<startX>, width:<enemyWidth>, height:<enemyHeight>}",
    "#<time>,E,task,{type:end, num:<enemyNum>, endReason:<selected, offscreen, wrong, missed>}",
    "# retention test can end for wrong or missed",
    "#<time>,K,<correct,error>,{type:swipe, selected:<cmd.name>, correct:<cmd.name>, x1:<x1>, y1:<y1>, x2:<x2>, y2:<y2>}",
    "#<time>,K,<correct,error>,{type:tap, selected:<cmd.name>, correct:<cmd.name>, x:<x>, y:<y>",
    "#<time>,K,error,{type:miss, selected:<cmd.name>, correct:<cmd.name>, x:<x>, y:<y>}",
    "#<time>,K,error,{type:inactiveOrNull, selected:<cmd.name>, correct:<cmd.name>, x:<x>, y:<y>}",        
    "#<time>,K,pos,{x:<x>, y:<y>}",
    "# pos: falling enemy position",
    "#<time>,K,s,{type:create, cmd:<commandName>, tool:<toolName>, r:<red>, g:<green>, b:<blue>}",
    "#<time>,K,s,{type:update, pts:[{x:<xCoord>, y:<yCoord>},...]}",
    "#<time>,K,s,{type:end}",
    "# s: stroke", 
    "schema,{type:I, subtype:c, description:conte, data:[{name:id, type:long}, {name:event, type:str, description:U/D/M}, {name:x, type:int}, {name:y, type:int}, {name:contact, type:str}]}",
    "schema,{type:I, subtype:mp, description:multipoint, data:[{name:id, type:long}, {name:event, type:str, description:U/D/M}, {name:x, type:int}, {name:y, type:int}, {name:contact, type:str}]}",
    "schema,{type:T, subtype:m, description:menu, data:[{name:event, type:str, description:Activate(A)/Deactivate(D)/Open(O)}]}",
    "schema,{type:T, subType:ms, description:menu selection, data:[{name:contact, type:str, description:selected contact}]}",
    "different from actual selection. contact may be selected on menu and different contact then selected before menu deactivated.",
    "schema,{type:T, subtype:c, description:calibrate menu, data:[{name:old yaw, type:int, description:old yaw zero degs}, {name:new yaw, type:int, description:new yaw degs}]}"
    };
    for(String schemaStr : schemaArr){
      this.writer.print(schemaStr+"\n");
    }
    super.logSchema();
  }
}