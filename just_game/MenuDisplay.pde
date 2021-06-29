 /*
 MenuDisplay is the original unfolded one
 MenuDisplay3D is the new one
 NOTE: right now MenuDisplay3D just ignores the coorinates it's given and uses new ones
 will fix later when fix menu class mess
 */
 
 //<>// //<>// //<>// //<>// //<>// //<>// //<>//
import java.util.Map;

// fake typedef
// for roll up menu
public class MenuIconMap extends HashMap<Contact, PVector> {
}
// for 3d menu
public class Menu3DMap extends HashMap<Contact, PVector[]>{}

// - - - - - - - - - - - - - - - - - - - - - - - - - 

/*---------- Fast Tap Menu ----------*/

class MenuDisplayFastTap{
    // 2d array of contacts, elem 0 is for outer grid, elem 1 for second level, elem 2 for third
    // each grid is a 2d array of rows
    Contact[][][] gridArr = {
      {{Contact.WC1, Contact.WME1, Contact.WC2}, {Contact.WSE1, null, Contact.WSE2}, {Contact.WC4, Contact.WME2, Contact.WC3}},
      {{Contact.LE1, Contact.LS1, Contact.LE2}, {Contact.MS1, null, Contact.MS2}, {Contact.LE4, Contact.LS2, Contact.LE3}},
      {{Contact.BC2, Contact.BME1, Contact.BC1}, {Contact.BSE2, null, Contact.BSE1}, {Contact.BC3, Contact.BME2, Contact.BC4}},
    };    
    
    int levels; // number of levels in grid
    // cellW and cellH are for "single cell" long and tall ones are multiples
    int marginW = 0;
    int marginH = 0;
    float cellW = (width - 2*marginW)/8;
    float cellH = (height - 2*marginH)/8;
    
    // last selected level, row, and col
    int selectedLevel = -1;
    int selectedRow = -1;
    int selectedCol = -1;
  
  MenuDisplayFastTap(){
    // find number of levels
    if(numCommands == bigCommands){
      levels = 3;
      Contact[] whiteAndBlack = {Contact.BSE2, Contact.W, Contact.B, Contact.BSE1};
      gridArr[2][1] = whiteAndBlack;
    } else {
      levels = 1;
      Contact[] justWhite = {Contact.WSE1, Contact.W, Contact.WSE2};
      gridArr[0][1] = justWhite;
    }
  }
  
  /*
  draws faint grid
  */
  void drawBackgroundGrid(){
    // outer rect
    stroke(200,200,200);
    strokeWeight(2);
    noFill();
    int z = -1; // grid depth (need - so behind game stuff)
    
    // outer border
    line(marginW, marginH, z, marginW, height - marginH, z); // left
    line(marginW, marginH, z, width - marginW, marginH, z); // top border
    line(width-marginW, marginH, z, width-marginH, height - marginH, z); // right border
    line(marginW, height - marginH, z, width - marginW, height - marginH, z);// bottom border
    
    
    // inner liens
    for(int i = 0; i < levels; i++){
      drawGrid(marginW + i*cellW, marginH + i*cellH, i, z);
    }
  }
  
  void drawFeedback(){
    for(int i = 0; i < levels; i++){
      drawContents(marginW + i*cellW, marginH + i*cellH, i, false);
    }
  }
  
  /*
  Draw the menu
  */
  void draw(){    
    // outer square of menu
    noFill();
    strokeWeight(4);
    stroke(0);
    rect(marginW, marginH, width-2*marginW, height-2*marginH);
    
    // draw levels
    int i;
    for(i = 0; i < levels; i++){
      drawLevel(marginW + i*cellW, marginH + i*cellH, i, true);
    }
  }
  
  /*
  Draws grid lines and icons for single level
  Input: marginW is the outer width margin
         marginH is the outer height margin
         level is which level we're drawing (0 for outer, 1 for middle, 2 for inner)
         drawIcon is whether or not to draw the icons
         NOTE called with different values than the global margins
  */
  void drawLevel(float marginW, float marginH, int level, boolean drawIcon){
    drawGrid(marginW, marginH, level, 0);
    drawContents(marginW, marginH, level, drawIcon);
  }
  
  /*
  Draws gridlines marginW and marginH from screen edges at height z
  Input: marginW, left and right margin
         marginH top and bottom margin
         level is level drawing
         z depth
  */
  void drawGrid(float marginW, float marginH, int level, int z){
    // grid lines
    line(marginW + cellW, marginH, z, marginW + cellW, height - marginH, z); // left
    line(marginW, marginH + cellH, z, width-marginW, marginH + cellH, z); // top
    line(width - marginW - cellW, marginH, z, width - marginW - cellW, height - marginH, z); // right
    line(marginW, height - marginH - cellH, z, width - marginW, height - marginH - cellH, z); // bottom
    
    // for level 2 need another line down middle
    if(level == 2){
      line(width/2, marginH + cellH, width/2, height-marginH-cellH);
    }
  }
  
  /*
  Draws stuff inside the grid for single level. 
  Draws blue rect around selected rect and when drawIcon is true draws icons.
  Input: marginW and margin H are grid margins
         level is level of grid
         drawIcon, when true draw icons when false just draw blue rect
  */
  void drawContents(float marginW, float marginH, int level, boolean drawIcon){     
    float top = marginH; // start at top
    for(int row = 0; row < 3; row++){
      float left = marginW; // start at left
      float actualH = (row == 1) ? (6-level*2)*cellH : cellH; // row 1 has bigger height
      float cY = top + actualH/2;
      Contact[] currRow = gridArr[level][row]; 
      for(int col = 0; col < currRow.length; col++){
        float actualW = (col == 1) ? (6-level*2)*cellW : cellW; // col 1 is wider
        
        // special case for 4 column row
        if(level == 2 && row == 1 && (col == 1 || col == 2)){
          actualW = (6-level*2)*cellW/2;
        }
        
        if(row == selectedRow && col == selectedCol){
          // middle one is different because selectedLevel can't be set but is always drawn as inner most level
          
          // march 17
          //if(row == 1 && col == 1){
          //  if(level == levels - 1){
          //    drawBlue(left, top, actualW, actualH);
          //  } // level == levels - 1        
          //} // row and col == 1
          // end march 17
        
          // normal selected command
          if(level == selectedLevel){
            drawBlue(left, top, actualW, actualH);
          } // else if
        } // row == selectedRow col == selectedCol
        
        if(drawIcon){
          // draw icon
          float cX = left + actualW/2;
          drawIcon(cX, cY, gridArr[level][row][col]);
        }
        left += actualW; // move over for next col
      }
      top += actualH; // move down for next row
    }
  }
  
  /*
  Just draws the blue rectangle
  Input: left, top are the top left coords to draw
         actualW, actualH are the width and height to draw
  */
  void drawBlue(float left, float top, float actualW, float actualH){
    stroke(0,0,255);
    strokeWeight(4);
    noFill();
    rect(left, top, actualW, actualH);
    stroke(0);
  }
  
  /*
  Draws the icon associated with contact at (cX, cY)
  Input: cX is the center x coordinate to draw at
         cY is the center y coordinate to draw at
         contact is the contact whose command's icon we're drawing
  */
  void drawIcon(float cX, float cY, Contact contact){
    imageMode(CENTER);
    if(contact != null){
      Command cmd = commands.get(contact); // lookup command associated with contact
      image(cmd.img, cX, cY); // draw image
    }
  }
  
  /*
  Contact on grid that pt falls into
  Input: pt is the location that was touched
  Output: Contact is the Contact at that location
          null if no item at location
  */
  Contact getContact(PVector pt){
    
    // find number of levels
    int levels; // num levels of grid to draw, starting from the outside
    // draw the other 16
    if(numCommands == bigCommands){
      levels = 3;
    } else {
      levels = 1;
    }
    
    // draw levels
    for(int i = 0; i < levels; i++){
      int factor = 6-2*i; // size of "big" cell
      Contact result = hitTestLevel(i, marginW + (i*cellW), marginH + (i*cellH), cellW, cellH, factor, gridArr[i], pt);
      if(result != null){
        selectedLevel = i; // result is not null so found something in this level
        return result;
      }
    }
    return null; // didn't hit anything
  }
  
  /*
  Checks if pt is in the grid for particular level.
  Input: same as draw level plus
         pt is the location to check
  Returns: Contact at location if hit
           null if none hit
  */
  Contact hitTestLevel(int level, float marginW, float marginH, float cellW, float cellH, int factor, Contact[][] contacts, PVector pt){
    
    //check each row individually
    for(int i = 0; i < 3; i++){
      Contact result = checkRow(level, i, marginW, marginH, cellW, cellH, factor, contacts, pt);
      if(result != null){
        return result;
      }
    }
    
    return null;
  }
  
  /*
  checks if pt is in row, if it is returns contact in that cell
  Input: same as hitTestLevel
  Output: contact in cell if there
          null if not
  */
  Contact checkRow(int level, int row, float marginW, float marginH, float cellW, float cellH, int factor, Contact[][] contacts, PVector pt){
    // set top and bottom for particular row
    float top;
    float bottom;
    if(row == 0){
      top = marginH;
      bottom = marginH + cellH;
    } else if(row == 1){
      top = marginH + cellH;
      bottom = top + factor*cellH;
    } else {
      top = height - marginH - cellH;
      bottom = top + cellH;
    }
    
    // check if in this row
    if(top <= pt.y && pt.y <= bottom){
      Contact[] currRow = contacts[row];
      for(int i = 0; i < currRow.length; i++){
        Contact result = checkCol(level, row, i, marginW, cellW, factor, contacts, pt);
        if(result != null){
          return result;
        }
      }
    }
    return null; // not in this row
  }
  
  /*
  Checks if pt is in this column
  We already know it's in row row but need that number because middle row has missing col in middle
  Output: Contact if found
          null otherwise
  */
  Contact checkCol(int level, int row, int col, float marginW, float cellW, int factor, Contact[][] contacts, PVector pt){
    // set left and right
    float left;
    float right;
    if(col == 0){
      left = marginW;
      right = marginW + cellW;
    } else if(col == 1){
      left = marginW + cellW;
      right = left + factor*cellW;
    } else {
      left = marginW + (factor + 1)*cellW;
      right = left + cellW;
    }
    
    // sepcial case for inner level
    if(level == 2 && row == 1){
      if(col == 1){
        left = marginW + cellW;
        right = left + factor*cellW/2;
      } else if(col ==2){
        left = marginW + cellW + factor*cellW/2;
        right = left + factor*cellW/2;
      }
    }
    
    // actually look up
    if(left <= pt.x && pt.x <= right){
      Contact result = contacts[row][col];
      selectedRow = row;
      selectedCol = col;
      return result;
    }
    
    return null;
  }
  
  /*
  Output: {levels, marginW, marginH, cellW, cellH}
  */
  float[] gridParams(){
    float[] result = {levels, marginW, marginH, cellW, cellH};
    return result;
  }
  
  /*
  */
  void resetSelection(){
      selectedRow = -1;
      selectedCol = -1;
  }
}

// -------------------------------------------------
/*---------- 3D WIRE MENU ----------*/
class WireMenu extends MenuDisplay3D{
  // need these here so can add them and remove them
  PShape whiteEnd;
  PShape blackEnd;
  PShape midBox;
  
  float scale = 4; // others are 3
  
  WireMenu(){
    // redo these so use proper scale
    midLen = 53 * scale;
    midWid = 27 * scale;
    //midHeight = 12 * scale;
    midHeight = 16 * scale;
    
    endLen = 16 * scale;
    endWid = 31 * scale;
    endHeight = 16 * scale;
    totalLen = midLen + 2*endLen;
    
    
    
    generateMap();
    initModel();
    
    menuAngleMap = new MenuAngleMap();
    setupMenuAngleMap();
  }
  
  /*
  generates map from each contact to PVector array
  first elem is PVector with translate offsets
  second elem is PVector with one end of line, other end is always 0,0,0
  */
  void generateMap(){
    m = new Menu3DMap();
    
    int margin = -5; // length of line
    int sideMargin  = 5;
    PVector[] LS1Arr = {new PVector(0, - midHeight/2 - sideMargin, 0), new PVector(0,0,0)};
    m.put(Contact.LS1, LS1Arr);
    
    PVector[] LE1Arr = {new PVector(-midWid/2 - margin, - midHeight/2 - margin, 0), new PVector(margin,margin,0)};
    m.put(Contact.LE1, LE1Arr);
    
    PVector[] LE2Arr = {new PVector(midWid/2 + margin, - midHeight/2 - margin, 0), new PVector(-margin, margin, 0)};
    m.put(Contact.LE2, LE2Arr);
    
    PVector[] WME1Arr = {new PVector(0, -endHeight/2 - margin, totalLen/2 + margin), new PVector(0,margin,-margin)};
    m.put(Contact.WME1, WME1Arr);
    
    PVector[] BME1Arr = {new PVector(0, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(0,margin,margin)};
    m.put(Contact.BME1, BME1Arr);
    
    PVector[] WArr = {new PVector(0, 0, totalLen/2 + sideMargin), new PVector(0,0,0)};
    m.put(Contact.W, WArr);
    
    PVector[] WC1Arr = {new PVector(-endWid/2 - margin, -endHeight/2 - margin, totalLen/2 + margin), new PVector(margin, margin, -margin)};
    m.put(Contact.WC1, WC1Arr);
    
    PVector[] WC2Arr = {new PVector(endWid/2 + margin, -endHeight/2 - margin, totalLen/2 + margin), new PVector(-margin, margin, -margin)};
    m.put(Contact.WC2, WC2Arr);
    
    PVector[] BArr = {new PVector(0, 0, -totalLen/2 - sideMargin), new PVector(0, 0, 0)};
    m.put(Contact.B, BArr);
    
    PVector[] BC1Arr = {new PVector(-endWid/2 - margin, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(margin, margin, margin)};
    m.put(Contact.BC1, BC1Arr);
    
    PVector[] BC2Arr = {new PVector(endWid/2 + margin, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(-margin, margin, margin)};
    m.put(Contact.BC2, BC2Arr);
      
    PVector[] LS2Arr = {new PVector(0, midHeight/2 + sideMargin, 0), new PVector(0, 0, 0)};
    m.put(Contact.LS2, LS2Arr);
    
    PVector[] LE4Arr = {new PVector(-midWid/2 - margin, midHeight/2 + margin, 0), new PVector(margin, -margin, 0)};
    m.put(Contact.LE4, LE4Arr);
    
    PVector[] LE3Arr = {new PVector(midWid/2 + margin, midHeight/2 + margin, 0), new PVector(-margin, -margin, 0)};
    m.put(Contact.LE3, LE3Arr);
    
    PVector[] WME2Arr = {new PVector(0, endHeight/2 + margin, totalLen/2 + margin), new PVector(0,-margin,-margin)};
    m.put(Contact.WME2, WME2Arr);
    
    PVector[] BME2Arr = {new PVector(0, endHeight/2 + margin, -totalLen/2 - margin), new PVector(0,-margin,margin)};
    m.put(Contact.BME2, BME2Arr);
    
    PVector[] WC4Arr = {new PVector(-endWid/2 - margin, endHeight/2 + margin, totalLen/2 + margin), new PVector(margin, -margin, -margin)};
    m.put(Contact.WC4, WC4Arr);
    
    PVector[] WC3Arr = {new PVector(endWid/2 + margin, endHeight/2 + margin, totalLen/2 + margin), new PVector(-margin, -margin, -margin)};
    m.put(Contact.WC3, WC3Arr);
    
    PVector[] BC4Arr = {new PVector(-endWid/2 - margin, endHeight/2 + margin, -totalLen/2 - margin), new PVector(margin, -margin, margin)};
    m.put(Contact.BC4, BC4Arr);
    
    PVector[] BC3Arr = {new PVector(endWid/2 + margin, endHeight/2 + margin, -totalLen/2 - margin), new PVector(-margin, -margin, margin)};
    m.put(Contact.BC3, BC3Arr);
    
    PVector[] MS1Arr = {new PVector(-midWid/2 - sideMargin, 0, 0), new PVector(0, 0, 0)};
    m.put(Contact.MS1, MS1Arr);
    
    PVector[] WSE1Arr = {new PVector(-endWid/2 - margin, 0, totalLen/2 + margin), new PVector(margin, 0, -margin)};
    m.put(Contact.WSE1, WSE1Arr);
    
    PVector[] BSE1Arr = {new PVector(-endWid/2 - margin, 0, -totalLen/2 - margin), new PVector(margin, 0, margin)};
    m.put(Contact.BSE1, BSE1Arr);
    
    PVector[] MS2Arr = {new PVector(midWid/2 + sideMargin, 0, 0), new PVector(0, 0, 0)};
    m.put(Contact.MS2, MS2Arr);
    
    PVector[] WSE2Arr = {new PVector(endWid/2 + margin, 0, totalLen/2 + margin), new PVector(-margin, 0, -margin)};
    m.put(Contact.WSE2, WSE2Arr);
    
    PVector[] BSE2Arr = {new PVector(endWid/2 + margin, 0, -totalLen/2 - margin), new PVector(-margin, 0, margin)};    
    m.put(Contact.BSE2, BSE2Arr);
  }
  
  /*
  Sets up the model to be displayed
  Sets up body as wire frame for easier display
  */
  private void initModel(){
    model = createShape(GROUP); // whole thing
    midBox = createShape(GROUP); // just the middle part
    
    // middle 
    // top
    PShape temp = createShape(LINE, -midWid/2, -midHeight/2, -midLen/2, -midWid/2, -midHeight/2, midLen/2); // left
    midBox.addChild(temp);
    temp = createShape(LINE, midWid/2, -midHeight/2, -midLen/2, midWid/2, -midHeight/2, midLen/2); // right
    midBox.addChild(temp);
    
    // bottom
    temp = createShape(LINE, -midWid/2, midHeight/2, -midLen/2, -midWid/2, midHeight/2, midLen/2); // left
    midBox.addChild(temp);
    temp = createShape(LINE, midWid/2, midHeight/2, -midLen/2, midWid/2, midHeight/2, midLen/2); // right
    midBox.addChild(temp);
    
    midBox.setStroke(color(214, 136, 106));
    midBox.setStrokeWeight(3);
    model.addChild(midBox);
    
    //// white identifiers
    // top
    float margin = midWid*0.15; // total together on both sides
    float tWid = midWid - margin; // width of white mark
    float tLen = midWid * 0.25; // length of white mark
    //PShape topWhite = createShape(BOX, tWid, 0, tLen);
    //topWhite.translate(0, -midHeight/2 -1, midLen/2 - tLen/2 - margin/2);
    //topWhite.setFill(color(255, 50));
    PShape topWhite = createShape(GROUP);
    PShape topLine = createShape(LINE, -tWid/2, -midHeight/2 -1, midLen/2 - margin/2, tWid/2, -midHeight/2 -1, midLen/2 - margin/2);
    topWhite.addChild(topLine);
    topLine = createShape(LINE, -tWid/2, -midHeight/2 -1, midLen/2 -tLen - margin/2, tWid/2, -midHeight/2 -1, midLen/2 - tLen - margin/2);
    topWhite.addChild(topLine);
    topLine = createShape(LINE, -tWid/2, -midHeight/2 -1, midLen/2 - margin/2, -tWid/2, -midHeight/2 -1, midLen/2 - tLen - margin/2);
    topWhite.addChild(topLine);
    topLine = createShape(LINE, tWid/2, -midHeight/2 -1, midLen/2 - margin/2, tWid/2, -midHeight/2 -1, midLen/2 - tLen - margin/2);
    topWhite.addChild(topLine);
    model.addChild(topWhite);
    
    
    ////// side
    float sLen = tLen;
    float sHeight = midHeight - margin;
    //PShape sideWhite = createShape(BOX, 0, sHeight, sLen);
    //sideWhite.translate(midWid/2 + 1,0, midLen/2 - sLen/2 - margin/2);
    //sideWhite.setFill(color(255, 50));
    PShape sideWhite = createShape(GROUP);
    PShape sideLine = createShape(LINE, midWid/2 + 1, midHeight/2 - margin/2, midLen/2 - margin/2, midWid/2 + 1, -midHeight/2 + margin/2, midLen/2 - margin/2);
    sideWhite.addChild(sideLine);
    sideLine = createShape(LINE, midWid/2 + 1, midHeight/2 - margin/2, midLen/2 - margin/2 - sLen, midWid/2 + 1, -midHeight/2 + margin/2, midLen/2 - margin/2 - sLen);
    sideWhite.addChild(sideLine);
    sideLine = createShape(LINE, midWid/2 + 1, midHeight/2 - margin/2, midLen/2 - margin/2 - sLen, midWid/2 + 1, midHeight/2 - margin/2, midLen/2 - margin/2);
    sideWhite.addChild(sideLine);
   sideLine = createShape(LINE, midWid/2 + 1, -midHeight/2 + margin/2, midLen/2 - margin/2 - sLen, midWid/2 + 1, -midHeight/2 + margin/2, midLen/2 - margin/2);
    sideWhite.addChild(sideLine);
    model.addChild(sideWhite);
    
    // black end
    color blackColor = color(0,0,0);
    blackEnd = makeEnd(-midLen/2.0, -midLen/2.0 - endLen, blackColor);
    model.addChild(blackEnd);
      
    //// whiteEnd
    color whiteColor = color(153, 217, 254);
    whiteEnd = makeEnd(midLen/2.0, midLen/2.0 + endLen, whiteColor);
    model.addChild(whiteEnd);
  }
  
    /*
  make end and return it
  Input: shortDist is either going to be -midLen/2 or midLen/2, it's the dist from origin to closer end of endpoint
         longDist is the dist from origin to far end of endpoint
         c is the the stroke color
  */
  PShape makeEnd(float shortDist, float longDist, color c){
    PShape result = createShape(GROUP);
    
    //// left
    PShape temp = createShape(LINE, -midWid/2.0, -midHeight/2.0, shortDist, -midWid/2.0, -midHeight/2.0, longDist);
    result.addChild(temp);
    temp = createShape(LINE, -midWid/2.0, midHeight/2.0, longDist, -midWid/2.0, midHeight/2.0, shortDist);
    result.addChild(temp);
  
    
    //// far
    temp = createShape(LINE, -midWid/2.0, midHeight/2.0, longDist, midWid/2.0, midHeight/2.0, longDist);
    result.addChild(temp);
    temp = createShape(LINE, midWid/2.0, -midHeight/2.0, longDist, -midWid/2.0, -midHeight/2.0, longDist);
    result.addChild(temp);
    temp = createShape(LINE, -midWid/2.0, midHeight/2.0, longDist, -midWid/2.0, -midHeight/2.0, longDist);
    result.addChild(temp);
    temp = createShape(LINE, midWid/2.0, -midHeight/2.0, longDist, midWid/2.0, midHeight/2.0, longDist);
    result.addChild(temp); 
    
    // right
    temp = createShape(LINE, midWid/2.0, -midHeight/2.0, shortDist, midWid/2.0, -midHeight/2.0, longDist);
    result.addChild(temp);
    temp = createShape(LINE, midWid/2.0, midHeight/2.0, longDist, midWid/2.0, midHeight/2.0, shortDist);
    result.addChild(temp);
    
    result.setStrokeWeight(3);
    result.setStroke(c);
    
    return result;
  }
  
  /*
  Draws menu on screen
  */
  void draw(){
    updateAngles(); // get last seen angles from oscApp
    pushMatrix();
    drawBox();
    drawIcons();
    popMatrix();    
  }
  
  /*
  Does this with 3d box -- option 2
  */
  void drawBox(){  
    translate(width/2, height/2, 0);
    doRotations();
    setTransparency();
    shape(model);
  }
  
  /*
  Sets black and white end points to transparent if they're closer to the user than the middle of the screen
  */
  void setTransparency(){
    // check white end
    int idx = model.getChildIndex(whiteEnd); // will be -1 if not there
    // if it's above the z threshold, find index again and remove it.
    if(modelZ(0,0,midLen/2.0 + endLen/2.0) > centerZ + 10){
      if(idx >= 0){
        model.removeChild(idx);
      }
    } else {
      if(idx < 0){
        model.addChild(whiteEnd);
      }
    }
    
    // check black end  
    // check white end
    idx = model.getChildIndex(blackEnd); // will be -1 if not there
    // if it's above the z threshold, find index again and remove it.
    if(modelZ(0,0,-midLen/2.0 - endLen/2.0) > centerZ + 10){
      if(idx >= 0){
        model.removeChild(idx);
      }
    } else {
      if(idx < 0){
        model.addChild(blackEnd);
      }
    }
    
  }
  
  /*
  Add icons for commands
  This is just to get coordinates
  ALL DIRECTIONS ARE WHEN LOOKING BIRD'S EYE VIEW FROM "STARTING POSITION"
  */
  void drawIcons(){
    strokeWeight(2);
    stroke(0);
    
    for(Contact contact : m.keySet()){
      
      // draw command if drawing all OR it's one of the small ones
      if(numCommands == bigCommands ||
        (numCommands == smallCommands && contact.end.equals("W"))){
        
        // lookup values for contact
        PVector[] arr = m.get(contact);
        PVector trans = arr[0];
        PVector line = arr[1];
        
        // draw
        pushMatrix();
        translate(trans.x, trans.y, trans.z);
        if(modelZ(0,0,0) < centerZ){
          line(line.x, line.y, line.z, 0, 0, 0);
        }
        drawOneIcon(contact);
        popMatrix();
      }
    }
  }
  
  void drawOneIcon(Contact contact){
    // lookup command
    Command cmd = commands.get(contact);
    
    int correctYaw = ((yaw - rawYawZero) + 360) % 360;
    // undoing conte rotations
    rotateZ(-radians(roll)); // roll
    rotateX(-radians(pitch)); // pitch
    rotateY(-radians(correctYaw)); // yaw
    // unrotate image (undo original conte flip)
    rotateX(-PI/2);
    imageMode(CENTER);
    if(modelZ(0,0,0) < centerZ - 20){
      pushMatrix();
      scale(0.5,0.5);
      image(cmd.img, 0, 0);
      popMatrix();
    }
  }
  
}

class MenuDisplayMirror3D extends MenuDisplay3D{
  
  MenuDisplayMirror3D(){
    generateMap();
    initModel();
  }
  
  /*
  generates map from each contact to PVector array
  first elem is PVector with translate offsets
  second elem is PVector with one end of line, other end is always 0,0,0
  */
  void generateMap(){
    m = new Menu3DMap();
    
    int margin = 30; // length of line
    PVector[] LS1Arr = {new PVector(0, - midHeight/2 - margin, 0), new PVector(0,margin,0)};
    m.put(Contact.LS1, LS1Arr);
    
    PVector[] LE1Arr = {new PVector(-midWid/2 - margin, - midHeight/2 - margin, 0), new PVector(margin,margin,0)};
    m.put(Contact.LE1, LE1Arr);
    
    PVector[] LE2Arr = {new PVector(midWid/2 + margin, - midHeight/2 - margin, 0), new PVector(-margin, margin, 0)};
    m.put(Contact.LE2, LE2Arr);
    
    PVector[] WME1Arr = {new PVector(0, -endHeight/2 - margin, totalLen/2 + margin), new PVector(0,margin,-margin)};
    m.put(Contact.WME1, WME1Arr);
    
    PVector[] BME1Arr = {new PVector(0, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(0,margin,margin)};
    m.put(Contact.BME1, BME1Arr);
    
    PVector[] WArr = {new PVector(0, 0, totalLen/2 + margin), new PVector(0,0,-margin)};
    m.put(Contact.W, WArr);
    
    PVector[] WC1Arr = {new PVector(-endWid/2 - margin, -endHeight/2 - margin, totalLen/2 + margin), new PVector(margin, margin, -margin)};
    m.put(Contact.WC1, WC1Arr);
    
    PVector[] WC2Arr = {new PVector(endWid/2 + margin, -endHeight/2 - margin, totalLen/2 + margin), new PVector(-margin, margin, -margin)};
    m.put(Contact.WC2, WC2Arr);
    
    PVector[] BArr = {new PVector(0, 0, -totalLen/2 - margin), new PVector(0, 0, margin)};
    m.put(Contact.B, BArr);
    
    PVector[] BC1Arr = {new PVector(-endWid/2 - margin, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(margin, margin, margin)};
    m.put(Contact.BC1, BC1Arr);
    
    PVector[] BC2Arr = {new PVector(endWid/2 + margin, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(-margin, margin, margin)};
    m.put(Contact.BC2, BC2Arr);
      
    PVector[] LS2Arr = {new PVector(0, midHeight/2 + margin, 0), new PVector(0, -margin, 0)};
    m.put(Contact.LS2, LS2Arr);
    
    PVector[] LE4Arr = {new PVector(-midWid/2 - margin, midHeight/2 + margin, 0), new PVector(margin, -margin, 0)};
    m.put(Contact.LE4, LE4Arr);
    
    PVector[] LE3Arr = {new PVector(midWid/2 + margin, midHeight/2 + margin, 0), new PVector(-margin, -margin, 0)};
    m.put(Contact.LE3, LE3Arr);
    
    PVector[] WME2Arr = {new PVector(0, endHeight/2 + margin, totalLen/2 + margin), new PVector(0,-margin,-margin)};
    m.put(Contact.WME2, WME2Arr);
    
    PVector[] BME2Arr = {new PVector(0, endHeight/2 + margin, -totalLen/2 - margin), new PVector(0,-margin,margin)};
    m.put(Contact.BME2, BME2Arr);
    
    PVector[] WC4Arr = {new PVector(-endWid/2 - margin, endHeight/2 + margin, totalLen/2 + margin), new PVector(margin, -margin, -margin)};
    m.put(Contact.WC4, WC4Arr);
    
    PVector[] WC3Arr = {new PVector(endWid/2 + margin, endHeight/2 + margin, totalLen/2 + margin), new PVector(-margin, -margin, -margin)};
    m.put(Contact.WC3, WC3Arr);
    
    PVector[] BC4Arr = {new PVector(-endWid/2 - margin, endHeight/2 + margin, -totalLen/2 - margin), new PVector(margin, -margin, margin)};
    m.put(Contact.BC4, BC4Arr);
    
    PVector[] BC3Arr = {new PVector(endWid/2 + margin, endHeight/2 + margin, -totalLen/2 - margin), new PVector(-margin, -margin, margin)};
    m.put(Contact.BC3, BC3Arr);
    
    PVector[] MS1Arr = {new PVector(-midWid/2 - margin, 0, 0), new PVector(margin, 0, 0)};
    m.put(Contact.MS1, MS1Arr);
    
    PVector[] WSE1Arr = {new PVector(-endWid/2 - margin, 0, totalLen/2 + margin), new PVector(margin, 0, -margin)};
    m.put(Contact.WSE1, WSE1Arr);
    
    PVector[] BSE1Arr = {new PVector(-endWid/2 - margin, 0, -totalLen/2 - margin), new PVector(margin, 0, margin)};
    m.put(Contact.BSE1, BSE1Arr);
    
    PVector[] MS2Arr = {new PVector(midWid/2 + margin, 0, 0), new PVector(-margin, 0, 0)};
    m.put(Contact.MS2, MS2Arr);
    
    PVector[] WSE2Arr = {new PVector(endWid/2 + margin, 0, totalLen/2 + margin), new PVector(-margin, 0, -margin)};
    m.put(Contact.WSE2, WSE2Arr);
    
    PVector[] BSE2Arr = {new PVector(endWid/2 + margin, 0, -totalLen/2 - margin), new PVector(-margin, 0, margin)};    
    m.put(Contact.BSE2, BSE2Arr);
  }
  
    /*
  Sets up the model to be displayed
  */
  private void initModel(){ 
    model = createShape(GROUP);
    
    PShape middle = createShape(BOX, midWid, midHeight, midLen); // x, y, z
    middle.setFill(color(214, 136, 106));
    model.addChild(middle);
    
    // white identifiers
    // top
    float margin = midWid*0.15; // total together on both sides
    float tWid = midWid - margin; // width of white mark
    float tLen = midWid * 0.25; // length of white mark
    PShape topWhite = createShape(BOX, tWid, 0, tLen);
    topWhite.translate(0, -midHeight/2 -1, midLen/2 - tLen/2 - margin/2);
    topWhite.setFill(color(255));
    model.addChild(topWhite);
    
    // side
    float sLen = tLen;
    float sHeight = midHeight - margin;
    PShape sideWhite = createShape(BOX, 0, sHeight, sLen);
    sideWhite.translate(midWid/2 + 1,0, midLen/2 - sLen/2 - margin/2);
    sideWhite.setFill(color(255));
    model.addChild(sideWhite);
    
    PShape blackEnd = createShape(BOX, endWid, endHeight, endLen);
    blackEnd.setFill(color(0));
    blackEnd.translate(0,0,-1*((midLen/2.0) + (endLen/2.0)));
    model.addChild(blackEnd);
    
    PShape whiteEnd = createShape(BOX, endWid, endHeight, endLen);
    whiteEnd.translate(0,0,midLen/2.0 + endLen/2.0);
    model.addChild(whiteEnd);
  }
  
  /*
  Draws menu on screen
  */
  void draw(){
    updateAngles(); // get last seen angles from oscApp
    pushMatrix();
    drawBox();
    drawIcons();
    popMatrix();    
  }
  
  /*
  Does this with 3d box -- option 2
  */
  void drawBox(){  
    translate(width/2, height/2, 0);
    doRotations();
    shape(model);
  }
  
  void doRotations(){
    initialRotations();
    specificRealRotations();
  }
  
  /*
  Rotations done to get model in starting position that agrees with IMU 0
  */
  void initialRotations(){
    scale(1,1,-1);
    translate(0,0,-400); //
    scale(1,1,-1);
    rotateX(PI/2);
  }
  
  /*
  Add icons for commands
  This is just to get coordinates
  ALL DIRECTIONS ARE WHEN LOOKING BIRD'S EYE VIEW FROM "STARTING POSITION"
  */
  void drawIcons(){
    strokeWeight(2);
    stroke(0);
    
    for(Contact contact : m.keySet()){
      
      // draw command if drawing all OR it's one of the small ones
      if(numCommands == bigCommands ||
        (numCommands == smallCommands && contact.end.equals("W"))){
        
        // lookup values for contact
        PVector[] arr = m.get(contact);
        PVector trans = arr[0];
        PVector line = arr[1];
        
        // draw
        pushMatrix();
        translate(trans.x, trans.y, trans.z);
        if(modelZ(0,0,0) >= centerZ){
          line(line.x, line.y, line.z, 0, 0, 0);
        }
        drawOneIcon(contact);
        popMatrix();
      }
    }
  }
  
  void drawOneIcon(Contact contact){
    // lookup command
    Command cmd = commands.get(contact);
    
    int correctYaw = ((yaw - rawYawZero) + 360) % 360;
    // undoing conte rotations
    rotateZ(-radians(roll)); // roll
    rotateX(-radians(pitch)); // pitch
    rotateY(-radians(correctYaw)); // yaw
    // unrotate image (undo original conte flip)
    rotateX(-PI/2);
    imageMode(CENTER);
    if(modelZ(0,0,0) >= centerZ){
      pushMatrix();
      scale(0.5,0.5);
      image(cmd.img, 0, 0);
      popMatrix();
    }
  }
  
}

class MenuDisplayOrig3D extends MenuDisplay3D{
  
  MenuDisplayOrig3D(){
    generateMap();
    initModel();
  }
  
  /*
  generates map from each contact to PVector array
  first elem is PVector with translate offsets
  second elem is PVector with one end of line, other end is always 0,0,0
  */
  void generateMap(){
    m = new Menu3DMap();
    
    int margin = 30; // length of line
    PVector[] LS1Arr = {new PVector(0, - midHeight/2 - margin, 0), new PVector(0,margin,0)};
    m.put(Contact.LS1, LS1Arr);
    
    PVector[] LE1Arr = {new PVector(-midWid/2 - margin, - midHeight/2 - margin, 0), new PVector(margin,margin,0)};
    m.put(Contact.LE1, LE1Arr);
    
    PVector[] LE2Arr = {new PVector(midWid/2 + margin, - midHeight/2 - margin, 0), new PVector(-margin, margin, 0)};
    m.put(Contact.LE2, LE2Arr);
    
    PVector[] WME1Arr = {new PVector(0, -endHeight/2 - margin, totalLen/2 + margin), new PVector(0,margin,-margin)};
    m.put(Contact.WME1, WME1Arr);
    
    PVector[] BME1Arr = {new PVector(0, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(0,margin,margin)};
    m.put(Contact.BME1, BME1Arr);
    
    PVector[] WArr = {new PVector(0, 0, totalLen/2 + margin), new PVector(0,0,-margin)};
    m.put(Contact.W, WArr);
    
    PVector[] WC1Arr = {new PVector(-endWid/2 - margin, -endHeight/2 - margin, totalLen/2 + margin), new PVector(margin, margin, -margin)};
    m.put(Contact.WC1, WC1Arr);
    
    PVector[] WC2Arr = {new PVector(endWid/2 + margin, -endHeight/2 - margin, totalLen/2 + margin), new PVector(-margin, margin, -margin)};
    m.put(Contact.WC2, WC2Arr);
    
    PVector[] BArr = {new PVector(0, 0, -totalLen/2 - margin), new PVector(0, 0, margin)};
    m.put(Contact.B, BArr);
    
    PVector[] BC1Arr = {new PVector(-endWid/2 - margin, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(margin, margin, margin)};
    m.put(Contact.BC1, BC1Arr);
    
    PVector[] BC2Arr = {new PVector(endWid/2 + margin, -endHeight/2 - margin, -totalLen/2 - margin), new PVector(-margin, margin, margin)};
    m.put(Contact.BC2, BC2Arr);
      
    PVector[] LS2Arr = {new PVector(0, midHeight/2 + margin, 0), new PVector(0, -margin, 0)};
    m.put(Contact.LS2, LS2Arr);
    
    PVector[] LE4Arr = {new PVector(-midWid/2 - margin, midHeight/2 + margin, 0), new PVector(margin, -margin, 0)};
    m.put(Contact.LE4, LE4Arr);
    
    PVector[] LE3Arr = {new PVector(midWid/2 + margin, midHeight/2 + margin, 0), new PVector(-margin, -margin, 0)};
    m.put(Contact.LE3, LE3Arr);
    
    PVector[] WME2Arr = {new PVector(0, endHeight/2 + margin, totalLen/2 + margin), new PVector(0,-margin,-margin)};
    m.put(Contact.WME2, WME2Arr);
    
    PVector[] BME2Arr = {new PVector(0, endHeight/2 + margin, -totalLen/2 - margin), new PVector(0,-margin,margin)};
    m.put(Contact.BME2, BME2Arr);
    
    PVector[] WC4Arr = {new PVector(-endWid/2 - margin, endHeight/2 + margin, totalLen/2 + margin), new PVector(margin, -margin, -margin)};
    m.put(Contact.WC4, WC4Arr);
    
    PVector[] WC3Arr = {new PVector(endWid/2 + margin, endHeight/2 + margin, totalLen/2 + margin), new PVector(-margin, -margin, -margin)};
    m.put(Contact.WC3, WC3Arr);
    
    PVector[] BC4Arr = {new PVector(-endWid/2 - margin, endHeight/2 + margin, -totalLen/2 - margin), new PVector(margin, -margin, margin)};
    m.put(Contact.BC4, BC4Arr);
    
    PVector[] BC3Arr = {new PVector(endWid/2 + margin, endHeight/2 + margin, -totalLen/2 - margin), new PVector(-margin, -margin, margin)};
    m.put(Contact.BC3, BC3Arr);
    
    PVector[] MS1Arr = {new PVector(-midWid/2 - margin, 0, 0), new PVector(margin, 0, 0)};
    m.put(Contact.MS1, MS1Arr);
    
    PVector[] WSE1Arr = {new PVector(-endWid/2 - margin, 0, totalLen/2 + margin), new PVector(margin, 0, -margin)};
    m.put(Contact.WSE1, WSE1Arr);
    
    PVector[] BSE1Arr = {new PVector(-endWid/2 - margin, 0, -totalLen/2 - margin), new PVector(margin, 0, margin)};
    m.put(Contact.BSE1, BSE1Arr);
    
    PVector[] MS2Arr = {new PVector(midWid/2 + margin, 0, 0), new PVector(-margin, 0, 0)};
    m.put(Contact.MS2, MS2Arr);
    
    PVector[] WSE2Arr = {new PVector(endWid/2 + margin, 0, totalLen/2 + margin), new PVector(-margin, 0, -margin)};
    m.put(Contact.WSE2, WSE2Arr);
    
    PVector[] BSE2Arr = {new PVector(endWid/2 + margin, 0, -totalLen/2 - margin), new PVector(-margin, 0, margin)};    
    m.put(Contact.BSE2, BSE2Arr);
  }
  
    /*
  Sets up the model to be displayed
  */
  private void initModel(){ 
    model = createShape(GROUP);
    
    PShape middle = createShape(BOX, midWid, midHeight, midLen); // x, y, z
    middle.setFill(color(214, 136, 106));
    model.addChild(middle);
    
    // white identifiers
    // top
    float margin = midWid*0.15; // total together on both sides
    float tWid = midWid - margin; // width of white mark
    float tLen = midWid * 0.25; // length of white mark
    PShape topWhite = createShape(BOX, tWid, 0, tLen);
    topWhite.translate(0, -midHeight/2 -1, midLen/2 - tLen/2 - margin/2);
    topWhite.setFill(color(255));
    model.addChild(topWhite);
    
    // side
    float sLen = tLen;
    float sHeight = midHeight - margin;
    PShape sideWhite = createShape(BOX, 0, sHeight, sLen);
    sideWhite.translate(midWid/2 + 1,0, midLen/2 - sLen/2 - margin/2);
    sideWhite.setFill(color(255));
    model.addChild(sideWhite);
    
    PShape blackEnd = createShape(BOX, endWid, endHeight, endLen);
    blackEnd.setFill(color(0));
    blackEnd.translate(0,0,-1*((midLen/2.0) + (endLen/2.0)));
    model.addChild(blackEnd);
    
    PShape whiteEnd = createShape(BOX, endWid, endHeight, endLen);
    whiteEnd.translate(0,0,midLen/2.0 + endLen/2.0);
    model.addChild(whiteEnd);
  }
  
  /*
  Draws menu on screen
  */
  void draw(){
    updateAngles(); // get last seen angles from oscApp
    pushMatrix();
    drawBox();
    drawIcons();
    popMatrix();    
  }
  
  /*
  Does this with 3d box -- option 2
  */
  void drawBox(){  
    translate(width/2, height/2, 0);
    doRotations();
    shape(model);
  }
  
  /*
  Add icons for commands
  This is just to get coordinates
  ALL DIRECTIONS ARE WHEN LOOKING BIRD'S EYE VIEW FROM "STARTING POSITION"
  */
  void drawIcons(){
    strokeWeight(2);
    stroke(0);
    
    for(Contact contact : m.keySet()){
      
      // draw command if drawing all OR it's one of the small ones
      if(numCommands == bigCommands ||
        (numCommands == smallCommands && contact.end.equals("W"))){
        
        // lookup values for contact
        PVector[] arr = m.get(contact);
        PVector trans = arr[0];
        PVector line = arr[1];
        
        // draw
        pushMatrix();
        translate(trans.x, trans.y, trans.z);
        if(modelZ(0,0,0) >= centerZ){
          line(line.x, line.y, line.z, 0, 0, 0);
        }
        drawOneIcon(contact);
        popMatrix();
      }
    }
  }
  
  void drawOneIcon(Contact contact){
    // lookup command
    Command cmd = commands.get(contact);
    
    int correctYaw = ((yaw - rawYawZero) + 360) % 360;
    // undoing conte rotations
    rotateZ(-radians(roll)); // roll
    rotateX(-radians(pitch)); // pitch
    rotateY(-radians(correctYaw)); // yaw
    // unrotate image (undo original conte flip)
    rotateX(-PI/2);
    imageMode(CENTER);
    if(modelZ(0,0,0) >= centerZ){
      pushMatrix();
      scale(0.5,0.5);
      image(cmd.img, 0, 0);
      popMatrix();
    }
  }
  
}

// - - - - - - - - - - - - - - - - - - - - - - - - - 

/*---------- 3D MENU BASE CLASS ----------*/

class MenuDisplay3D{
  /*
  generates map from each contact to PVector array
  first elem is PVector with translate offsets
  second elem is PVector with one end of line, other end is always 0,0,0
  */
  Menu3DMap m; // map with translate and line drawing locations for all contact
  
  // when true, shows actual real time rotation
  // when false shows locked one
  boolean realRotate = true;
  
  // yaw, pitch, roll for display
  // NOTE using fields so if unclassified can just use values from previous frame
  int yaw = 0;
  int pitch = 0;
  int roll = 0;
  int rawYawZero = 0; // in degrees, raw yaw from IMU that corresponds to on-screen yaw = 0
  boolean calibrated = false; // has rawYawZero been set ie is menu display calibrated
  
  // needed for not real rotate
  int mostRecentClass = Classifier.unclassified; // most recent classification seen. Need to save in case all current are unclassified
  
  // whiteEndYaw is for white end forward, blackEndYaw is for black end forward
  int yawOffset = 35; // rotation counterclockwise of straight forward
  int whiteEndYaw = 360 - yawOffset; // yaw we'll use for perspective
  int blackEndYaw = 180 - yawOffset;
  
  // model
  PShape model; // conte model to display
  // how much to scale each dimension by
  int scale = 3;
  
  // values are actual mm values scaled by scale
  float midLen = 53 * scale;
  float midWid = 27 * scale;
  float midHeight = 12 * scale;
  
  float endLen = 16 * scale;
  float endWid = 31 * scale;
  float endHeight = 16 * scale;
  
  float totalLen = midLen + 2*endLen; // length of whole thing, middle and 2 ends
  
  float centerZ = 400; // actual Z coordinate of center of model
  
  MenuAngleMap menuAngleMap; // map from contact to MenuAngles
  
  MenuDisplay3D(){    
    menuAngleMap = new MenuAngleMap();
    setupMenuAngleMap();
  }
  
  /*---------- DRAW ----------*/
  
  /*
  Draws menu on screen
  */
  void draw(){    
  }
  
  /*
  update roll, pitch, yaw. use oscApp
  */
  void updateAngles(){
    AppMessage mostRecent = oscApp.mostRecentMessage();
    if(mostRecent != null){
      this.yaw = mostRecent.yaw;
      this.roll = mostRecent.roll;
      this.pitch = mostRecent.pitch;
    }
  }
  
  /*---------- ROTATE ----------*/
  void doRotations(){
    initialRotations();
    if(realRotate){
      specificRealRotations();
    } else {
      specificLockedRotations();
    }
  }
  
  /*
  Rotations done to get model in starting position that agrees with IMU 0
  */
  void initialRotations(){
    scale(1,1,-1);
    translate(0,0,-400); //
    rotateX(PI/2);
  }
  
  /*
  Rotations from actual yaw pitch and roll seen
  */
  void specificRealRotations(){
    int correctYaw = ((yaw - rawYawZero) + 360) % 360;
    rotateY(radians(correctYaw)); // yaw
    rotateX(radians(pitch)); // pitch
    rotateZ(radians(roll)); // roll
  }
  
  /*
  Gets most recent classification
  Looks up set angles for this classification and uses those
  Uses classification from last frame if no recent classified reading
  */
  void specificLockedRotations(){
    // get classification and update field
    int classification = oscApp.mostRecentAirClassification();
    if(classification == Classifier.unclassified || classification == Classifier.pending){
      classification = mostRecentClass;
    }
    mostRecentClass = classification;
    
    // look up corresponding angles and do rotations with them
    Contact currContact = classToContact.get(classification);
    MenuAngles angles = menuAngleMap.get(currContact);
    if(angles != null){
    int correctYaw = calculateYaw(yaw); // use real time yaw
    rotateY(radians(correctYaw)); // yaw
    rotateX(radians(angles.pitch)); // pitch
    rotateZ(radians(angles.roll)); // roll
    }
  }
  
  /*
  Tests the yaw found by getMostRecentClassification
  offsets it by rawYawZero which is the raw yaw in degrees sent by IMU when conte is facing in the direction
  of yaw = 0 on screen
  Then tests which region it's in and either sets it to white end yaw or black end yaw
  Input: raw yaw received from IMU
  Returns: Correct on-screen yaw
  */
  int calculateYaw(int rawYaw){
    // must be between black lower and black upper to be black end forward, else white end forward
    int blackLower = 45;
    int blackUpper = 225;
    // update by offset
    int result = ((rawYaw - rawYawZero) + 360) % 360;
    if(blackLower <= result && result <= blackUpper){
      result = blackEndYaw;
    } else {
      result = whiteEndYaw;
    }
    return result;    
  }
  
  /*
  Saves most recent yaw reading as rawYawZero
  Actuated by user pressing key c
  Also when first reading comes in
  */
  void calibrate(){
    AppMessage curr = oscApp.mostRecentMessage();
    if(curr != null){
      rawYawZero = curr.yaw;
      calibrated = true;
      println("calibration successful!");
    }
  }
  
  /*
  Returns "zero yaw" ie yaw reading when conte facing directly forward
  */
  int getYawZero(){
    return rawYawZero;
  }
  
  /*
  Returns true if menuDisplay has been calibrated, false otherwise
  */
  boolean isCalibrated(){
    return calibrated;
  }
  
  /*
  toggles realRotate
  */
  void toggleReal(){
    realRotate = !realRotate;
  }
  
  /*---------- MAP ----------*/
  
  // inner class used to store yaw, pitch, roll in map
  class MenuAngles {
    int yaw;
    int pitch;
    int roll;
    
    MenuAngles(int yaw, int pitch, int roll){
      this.yaw = yaw;
      this.pitch = pitch;
      this.roll = roll;
    }
  }
  
  // fake typedef for mapping from contact to angles
  class MenuAngleMap extends HashMap<Contact, MenuAngles> {};
  
  /*
  Adds all mappings to menuAngleMap
  */
  void setupMenuAngleMap(){
    // large side and edges (menu top)
    menuAngleMap.put(Contact.LE1, new MenuAngles(whiteEndYaw, 0, -135)); // red
    menuAngleMap.put(Contact.LS1, new MenuAngles(whiteEndYaw, 0, -180)); // orange
    menuAngleMap.put(Contact.LE2, new MenuAngles(whiteEndYaw, 0, 135)); // yellow
    
    // large side and edges (menu bottom)
    menuAngleMap.put(Contact.LE3, new MenuAngles(whiteEndYaw, 0, 45)); // violet
    menuAngleMap.put(Contact.LS2, new MenuAngles(whiteEndYaw, 0, 0)); // blue
    menuAngleMap.put(Contact.LE4, new MenuAngles(whiteEndYaw, 0, -45)); // green
    
    // medium sides
    menuAngleMap.put(Contact.MS1, new MenuAngles(whiteEndYaw, 0, -90)); // black
    menuAngleMap.put(Contact.MS2, new MenuAngles(whiteEndYaw, 0, 90)); // white
    
    // white end
    int whiteEndPitch = -45;
    
    // end -- could use this but it's jittery and not really useful
    //menuAngleMap.put(Contact.W, new MenuAngles(whiteEndYaw, -90, -180));
    
    // corners
    menuAngleMap.put(Contact.WC1, new MenuAngles(whiteEndYaw, whiteEndPitch, -135)); // pen1
    menuAngleMap.put(Contact.WC2, new MenuAngles(whiteEndYaw, whiteEndPitch, 135)); // pen2
    menuAngleMap.put(Contact.WC3, new MenuAngles(whiteEndYaw, whiteEndPitch, 45)); // pen3
    menuAngleMap.put(Contact.WC4, new MenuAngles(whiteEndYaw, whiteEndPitch, -45)); // pen4
    
    // short edges
    menuAngleMap.put(Contact.WSE1, new MenuAngles(whiteEndYaw, whiteEndPitch, -90)); // eraser1
    menuAngleMap.put(Contact.WSE2, new MenuAngles(whiteEndYaw, whiteEndPitch, 90)); // eraser2
    
    // medium edges
    menuAngleMap.put(Contact.WME1, new MenuAngles(whiteEndYaw, whiteEndPitch, 180)); // eraser3
    menuAngleMap.put(Contact.WME2, new MenuAngles(whiteEndYaw, whiteEndPitch, 0)); // clear
    
    // black end
    int blackEndPitch = 45;
    
    // corners
    menuAngleMap.put(Contact.BC1, new MenuAngles(blackEndYaw, blackEndPitch, -135)); // brush2
    menuAngleMap.put(Contact.BC2, new MenuAngles(blackEndYaw, blackEndPitch, 135)); // brush1
    menuAngleMap.put(Contact.BC3, new MenuAngles(blackEndYaw, blackEndPitch, 45)); // brush4
    menuAngleMap.put(Contact.BC4, new MenuAngles(blackEndYaw, blackEndPitch, -45)); // brush3
    
    // short edges
    menuAngleMap.put(Contact.BSE1, new MenuAngles(blackEndYaw, blackEndPitch, -90)); // redo
    menuAngleMap.put(Contact.BSE2, new MenuAngles(blackEndYaw, blackEndPitch, 90)); // undo
    
    // medium edges
    menuAngleMap.put(Contact.BME1, new MenuAngles(blackEndYaw, blackEndPitch, 180)); // copy
    menuAngleMap.put(Contact.BME2, new MenuAngles(blackEndYaw, blackEndPitch, 0)); // paste
  }
   
}

/*---------- UNWRAPPED MENU ----------*/

class MenuDisplay{

  PImage img;

  MenuIconMap whiteIconPos;
  MenuIconMap blockIconPos;

  MenuDisplay() {
    println("loading menu image");
    img = loadImage("menu.png");

    generateIconPositions();
  }

  // build command icon to menu position maps
  void generateIconPositions() {
    
    whiteIconPos = new MenuIconMap();

    // large side and edges (menu top)  
    whiteIconPos.put(Contact.LE1, new PVector(-143, -211));
    whiteIconPos.put(Contact.LS1, new PVector(0, -211));
    whiteIconPos.put(Contact.LE2, new PVector(143, -211));
    // large side and edges (menu bottom)
    whiteIconPos.put(Contact.LE4, new PVector(-143, 211));
    whiteIconPos.put(Contact.LS2, new PVector(0, 211));
    whiteIconPos.put(Contact.LE3, new PVector(143, 211));  
    // medium sides
    whiteIconPos.put(Contact.MS1, new PVector(-280, 0));
    whiteIconPos.put(Contact.MS2, new PVector(280, 0));
    // end corners
    whiteIconPos.put(Contact.WC1, new PVector(-168, -100));
    whiteIconPos.put(Contact.WC2, new PVector(168, -100));
    whiteIconPos.put(Contact.WC4, new PVector(-168, 100));
    whiteIconPos.put(Contact.WC3, new PVector(168, 100));
    // end short edges
    whiteIconPos.put(Contact.WSE1, new PVector(-157, 0));
    whiteIconPos.put(Contact.WSE2, new PVector(157, 0));
    // end medium edges
    whiteIconPos.put(Contact.WME1, new PVector(0, -100));
    whiteIconPos.put(Contact.WME2, new PVector(0, 100));

    // black end
    blockIconPos = new MenuIconMap(); 
    // large side and edges (menu top)  
    blockIconPos.put(Contact.LE1, new PVector(143, -211));
    blockIconPos.put(Contact.LS1, new PVector(0, -211));
    blockIconPos.put(Contact.LE2, new PVector(-143, -211));
    // large side and edges (menu bottom)
    blockIconPos.put(Contact.LE4, new PVector(143, 211));
    blockIconPos.put(Contact.LS2, new PVector(0, 211));
    blockIconPos.put(Contact.LE3, new PVector(-143, 211));  
    // medium sides
    blockIconPos.put(Contact.MS1, new PVector(280, 0));
    blockIconPos.put(Contact.MS2, new PVector(-280, 0));
    // end corners
    blockIconPos.put(Contact.BC2, new PVector(-168, -100));
    blockIconPos.put(Contact.BC1, new PVector(168, -100));
    blockIconPos.put(Contact.BC3, new PVector(-168, 100));
    blockIconPos.put(Contact.BC4, new PVector(168, 100));
    // end short edges
    blockIconPos.put(Contact.BSE2, new PVector(-157, 0));
    blockIconPos.put(Contact.BSE1, new PVector(157, 0));
    // end medium edges
    blockIconPos.put(Contact.BME1, new PVector(0, -100));
    blockIconPos.put(Contact.BME2, new PVector(0, 100));
  }



  void draw(float x, float y, float a, boolean whiteEnd) {

    pushMatrix();
    translate(x, y);
    rotate(a);
    translate(-x, -y);

    imageMode(CENTER);
    image(img, x, y);
    imageMode(CORNER);

    pushMatrix();
    translate(x, y);

    MenuIconMap m;

    if (whiteEnd) {
      m = whiteIconPos;
    } else {
      m = blockIconPos;
    }

    for (Contact contact: m.keySet()) {

      Command cmd = commands.get(contact);
      if (cmd != null) {

        PVector pos = m.get(contact);
        pushMatrix();

        translate(pos.x, pos.y);
        rotate(-a);
        cmd.draw(0, 0);
        popMatrix();
      }
    }

    popMatrix();
    popMatrix();
  }


  void drawIcon(Contact c, float a) {
  }
}


// - - - - - - - - - - - - - - - - - - - - - - - - - 


//void setupMenu() {



//  // large side and edges (menu top)  
//  commands[0] = new Command(-143, -211, "red");
//  commands[1] = new Command(0, -211, "orange");
//  commands[2] = new Command(143, -211, "yellow");

//  // large side and edges (menu bottom)
//  commands[3] = new Command(-143, 211, "green");
//  commands[4] = new Command(0, 211, "blue");
//  commands[5] = new Command(143, 211, "violet");

//  // medium sides
//  commands[6] = new Command(-280, 0, "black");
//  commands[7] = new Command(280, 0, "white");

//  // white end

//  // corners
//  commands[8] = new Command(-168, -100, "pen1");
//  commands[9] = new Command(168, -100, "pen2");  
//  commands[10] = new Command(-168, 100, "pen3");
//  commands[11] = new Command(168, 100, "pen4");  

//  // short edges
//  commands[12] = new Command(-157, 0, "eraser1"); 
//  commands[13] = new Command(157, 0, "eraser2");

//  // medium edges
//  commands[14] = new Command(0, -100, "eraser3");
//  commands[15] = new Command(0, 100, "clear");

//  // black end

//  // corners
//  commands[16] = new Command(-168, -100, "brush1");
//  commands[17] = new Command(168, -100, "brush2");  
//  commands[18] = new Command(-168, 100, "brush3");
//  commands[19] = new Command(168, 100, "brush4");  

//  // short edges
//  commands[20] = new Command(-157, 0, "undo"); 
//  commands[21] = new Command(157, 0, "redo");

//  // medium edges
//  commands[22] = new Command(0, -100, "copy");
//  commands[23] = new Command(0, 100, "paste");
//}