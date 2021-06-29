/*
Info needed to draw
*/
class Stroke{
  final int copyThresh = 50; // how far the copy point can be from a stroke to copy it
  
  Command cmd; // what command is this stroke - will look up everything else based on command
  
  // colour
  int r;
  int g;
  int b;
  
  int strokeW; // strokeW is used as size in general (ie used as diam for paint ellipses)
  Tool tool; // tool to draw with
  
  ArrayList<PVector> pts; 
  float currLen = 0; // length of pts as sum of distance between consecutive pts

  
  /*
  Normal Constructor
  Input: cmd is the command this stroke came from
         r,g,b are the colours to draw in. They're from the current state of the app
  */
  Stroke(Command cmd, int r, int g, int b){
    this.cmd = cmd;
    this.r = r;
    this.g = g;
    this.b = b;
    pts = new ArrayList<PVector>();
    
    assignTool(cmd);
    logStrokeStart();
  }
  
  /*
  Copy Constructor
  Input: stroke is the stroke we're copying
         copyCoords is the point we copied from
         pasteCoords is the point we're pasting at
  All points in the new stroke will be offset from pasteCoords the same amount they were offset from copyCoords
  */
  Stroke(Stroke stroke, PVector copyCoords, PVector pasteCoords){
    this.cmd = stroke.cmd;
    this.r = stroke.r;
    this.g = stroke.g;
    this.b = stroke.b;
    this.strokeW = stroke.strokeW;
    this.tool = stroke.tool;
    pts = new ArrayList<PVector>();
    copyAndOffsetPoints(stroke.pts, copyCoords, pasteCoords);
    this.currLen = stroke.currLen;
  }
  
  /*
  Given a Command, look up the corresponding tool and assign it
  Input: cmd is the command for this stroke
  */
  void assignTool(Command cmd){
    String name = cmd.name;
    ToolAndSize toolAndSize = commandToolMap.get(name);
    this.tool = toolAndSize.tool;
    this.strokeW = toolAndSize.strokeW;
  }
  
  /*
  Copies the points in oldPts to this.pts but changes them so that the offset from copyCoords in oldPts
  is the same as the offset from pasteCoords in pts
  Input: oldPts is the stroke to copy from
         copyCoords is the old offset
         pasteCoords is the new offset
  */
  void copyAndOffsetPoints(ArrayList<PVector> oldPts, PVector copyCoords, PVector pasteCoords){
    // how much to move each point
    float xOffset = pasteCoords.x - copyCoords.x;
    float yOffset = pasteCoords.y - copyCoords.y;
    
    for(int i = 0; i < oldPts.size(); i++){
      PVector oldPt = oldPts.get(i);
      float newX = oldPt.x + xOffset;
      float newY = oldPt.y + yOffset;
      pts.add(new PVector(newX, newY));
    }
  }
  
  /*---------- UPDATE ----------*/
  
  /*
  Updates the stroke with new points
  Input: pts is an array of incoming points
         id is the id number of the touch point this came from
  */
  void update(PVector[] pts, long id){
    // we only include the first point if this is the first time we're adding to pts
    // since the first point from one is the same as the last point from the one before
    int start; // starting index
    if(this.pts.size() == 0){
      start = 0;
    } else{
      start = 1;
    }
    for(int i = start; i < pts.length; i++){  
      // add to length
      // first point to add and there are existing points
      if(i == start && start > 0){
        PVector lastExisting = this.pts.get(this.pts.size() - 1);
        float currDist = dist(pts[i].x, pts[i].y, lastExisting.x, lastExisting.y);
        currLen += currDist;
      } 
      // not first point
      else if(i > start){
        float currDist = dist(pts[i].x, pts[i].y, pts[i-1].x, pts[i-1].y);
        currLen += currDist;
      }
      
      this.pts.add(pts[i]);
 
    }
    logStrokeUpdate(pts, start);
  }
 
 /*
 Used for multi-point contact points to update stroke
 They only update with one point at a time
 Input: pt is the new point
        id is the id of the point this came from - actually not used for now
 */
 void update(PVector pt, long id){
   // update len
   if(pts.size() > 0){
     PVector lastPt = pts.get(pts.size() - 1);
     float currDist = dist(pt.x, pt.y, lastPt.x, lastPt.y);
     currLen += currDist; 
   }
   // update pts
   this.pts.add(pt);
   PVector[] pts = {pt};
   logStrokeUpdate(pts, 0);
 } 
  
  /*---------- DRAW ----------*/
  
  /* 
  Draws the path in pts. If app.pg is true, draws it to app.pg, otherwise just draws it to screen
  Input: onPg is true when drawing to app.pg, false otherwise
  */
  void draw(boolean onPg){
    switch(tool){
      case PEN:
        drawPenWrapper(onPg);
        break;
      case PAINT:
        drawPaintWrapper(onPg);
        break;
      case ERASER:
        drawEraserWrapper(onPg);
        break;
      case CLEAR:
        drawClearWrapper(onPg);
        break;
    }
  } // draw
  
  /*
  Wraps draw pen command - draws to app.pg if app.pg is true, draws to canvas is app.pg is false
  Input: onPg is true if should draw to app.pg, false otherwise
  */
  void drawPenWrapper(boolean onPg){
    if(onPg){
      drawPenPg();
    } else {
      drawPen();
    }
  }
  
  /*
  Draws pen to app.pg
  */
  void drawPenPg(){
    app.pg.beginDraw();
    
    // settings
    app.pg.stroke(r, g, b);
    app.pg.strokeWeight(strokeW);
    app.pg.noFill();
    app.pg.strokeCap(ROUND);
    app.pg.strokeJoin(ROUND);
    app.pg.beginShape();
    
    // draw lines between consecutive points
    for(int i = 0; i < pts.size(); i++){
      PVector first = pts.get(i);
      app.pg.vertex(first.x,first.y);
    } // loop
    app.pg.endShape();    
    app.pg.endDraw();
  }
  
  /*
  Draw command for a pen tool
  */
  void drawPen(){    
    // settings
    stroke(r, g, b);
    strokeWeight(strokeW);
    noFill();
    strokeCap(ROUND);
    strokeJoin(ROUND);    
    beginShape();

    // draw lines between consecutive points
    for(int i = 0; i < pts.size(); i++){      
      PVector first = pts.get(i);
      vertex(first.x, first.y);      
    } // loop
    endShape();
  }
 
  /*
  Wraps draw paint command - draws to app.pg if app.pg is true, draws to canvas is app.pg is false
  Input: onPg is true if should draw to app.pg, false otherwise
  */
  void drawPaintWrapper(boolean onPg){
    if(onPg){
      drawPaintPg();
    } else {
      drawPaint();
    }
  }
  
  /*
  Draws paint to app.pg
  */
  void drawPaintPg(){
    app.pg.beginDraw();
    app.pg.fill(r,g,b);
    app.pg.noStroke();
    int d = strokeW;
    
    for(int i = 0; i < pts.size(); i++){
      PVector point = pts.get(i);
      app.pg.ellipse(point.x, point.y, d, d);
    }    
    app.pg.endDraw();
  }
  
  /*
  Draws paint to canvas
  */
  void drawPaint(){
    fill(r,g,b);
    noStroke();
    int d = strokeW; // diameter of circle
    
    // draw dots at points
    for(int i = 0; i < pts.size(); i++){
      PVector point = pts.get(i);
      ellipse(point.x, point.y, d, d);
    }
  }
  
    /*
  Wraps draw eraser command - draws to app.pg if app.pg is true, draws to canvas is app.pg is false
  Input: onPg is true if should draw to app.pg, false otherwise
  */
  void drawEraserWrapper(boolean onPg){
    if(onPg){
      drawEraserPg();
    } else {
      drawEraser();
    }
  }
  
  /*
  Draws eraser to app.pg
  */
  void drawEraserPg(){
    app.pg.beginDraw();
    
    // settings
    int bgd = app.getBackground();
    app.pg.strokeWeight(strokeW);
    app.pg.stroke(bgd, bgd, bgd);
    app.pg.noFill();
    app.pg.strokeCap(ROUND);
    app.pg.strokeJoin(ROUND);
    app.pg.beginShape();

    
    // draw lines between consecutive points in pts
    for(int i = 0; i < pts.size(); i++){
      PVector first = pts.get(i);
      app.pg.vertex(first.x, first.y);
    } // loop
    app.pg.endShape();
    app.pg.endDraw();
  }
  
  /*
  Draws eraser
  */
  void drawEraser(){
    // settings
    int bgd = app.getBackground();
    strokeWeight(strokeW);
    stroke(bgd, bgd, bgd);
    noFill();
    strokeCap(ROUND);
    strokeJoin(ROUND);
    beginShape();
    
    // draw lines between consecutive points in pts
    for(int i = 0; i < pts.size(); i++){
      PVector first = pts.get(i);
      vertex(first.x, first.y);
    } // loop
    endShape();
  }
    
  /*
  Wraps draw clear command - draws to app.pg if app.pg is true, draws to canvas is app.pg is false
  Input: onPg is true if should draw to app.pg, false otherwise
  */
  void drawClearWrapper(boolean onPg){
    if(onPg){
      drawClearPg();
    } else {
      drawClear();
    }
  }
  
  /*
  Draws clear to app.pg
  */
  void drawClearPg(){
    app.pg.beginDraw();
    int bgd = app.getBackground();
    app.pg.background(bgd);
    app.pg.endDraw();
  }
  
  /*
  Draws the clear command
  */
  void drawClear(){
    int bgd = app.getBackground();
    background(bgd);
  }
  
  /*----------- LOG ----------*/
  
  /*
  Logs the start of the stroke
  */
  void logStrokeStart(){
    String JSONStr = logger.buildJSON("\"type\"", "\"create\"",
                                      "\"cmd\"", "\"" + cmd.name + "\"",
                                      "\"tool\"", "\"" + tool.name() + "\"",
                                      "\"weight\"", str(strokeW),
                                      "\"r\"", str(r),
                                      "\"g\"", str(g),
                                      "\"b\"", str(b));
    logger.doLog(new JSONEvent("K", "s", false, JSONStr));
  }
  
  /*
  Logs stroke update
  Input: pts is the array of new points added to stroke
         start is the indext to start copying from pts
  */
  void logStrokeUpdate(PVector[] pts, int start){
    // put all new points in array
    StringBuilder ptsBuilder = new StringBuilder();
    ptsBuilder.append("[");
    for(int i = start; i < pts.length; i++){
      PVector pt = pts[i];
      ptsBuilder.append(String.format("{\"x\":%s, \"y\":%s},", int(pt.x), int(pt.y)));
    }
    if(pts.length > start){
      ptsBuilder.deleteCharAt(ptsBuilder.length() - 1); // remove comma at end
    }
    ptsBuilder.append("]");
    String ptsJSONArr = ptsBuilder.toString();
    String JSONStr = logger.buildJSON("\"type\"", "\"update\"",
                                      "\"pts\"", ptsJSONArr);
    logger.doLog(new JSONEvent("K", "s", false, JSONStr));
  }
  
  /*
  Logs the end of the stroke
  */
  void logStrokeEnd(){
    String JSONStr = logger.buildJSON("\"type\"", "\"end\"");
    logger.doLog(new JSONEvent("K", "s", false, JSONStr));
  }
  
  /*---------- OTHER ----------*/
  
  /*
  Checks if coords is within copyThresh of any of the line segments in stroke and returns true if it is, false otherwise
  Input: coords are the point we're copying from
  Output: true if coords is within copyThresh of any of the line segments in stroke, false otherwise
  */
  boolean hitTest(PVector coords){
    for(int i = 0; i < pts.size() - 1; i++){
      PVector firstPt = pts.get(i);
      PVector secondPt = pts.get(i+1);
      
      float pointLineDist = 0; // distnace from coords to line from firstPt to secondPt
      float lineLen = firstPt.dist(secondPt);
      
      // firstPt and secondPt are the same point
      if(lineLen == 0){
        pointLineDist = firstPt.dist(coords);
      }
      
      /* firstPt and secondPt are  different
      find the line between firstPt and coords (line2) and find the scalar projection of it onto 
      the line from firstPt to secondPt (line1). Then divide by the length of the length of line1 to get ther percent
      of line1 that this projection takes
      cap that percentage to be between 0 and 1 then use the parameterized form of a line to find the actual
      location of this percentage on line1 if we start at firstPt. This is the point on line1 that is closest to coords.
      find the distance from coords to this point
      */
      else {
        PVector line1 = PVector.sub(coords, firstPt); // line segment from firstPt to coords
        PVector line2 = PVector.sub(secondPt, firstPt); // line segment from firstPt to secondPt
        float dotProd = line1.dot(line2); // take the dot product of the two
        float percent = dotProd/lineLen; // divide the dot product by the length of line 1
        float percentCapped = min(0, max(1, percent));
        float projectedX = firstPt.x + percentCapped*(secondPt.x - firstPt.x);
        float projectedY = firstPt.y + percentCapped*(secondPt.y - firstPt.y);
        PVector projectedPoint = new PVector(projectedX, projectedY);
        pointLineDist = coords.dist(projectedPoint);
      }
      
      if(pointLineDist <= copyThresh){
        return true;
      } // end if
    } // end loop
    return false; // never saw something close enough   
  }
  
  /*
  returns point array
  */
  ArrayList<PVector> getPts(){
    return pts;
  }
  
  /*
  return length of path as measured by distance between all consec points on it
  */
  float getLen(){
    return currLen;
  }
  
} // class