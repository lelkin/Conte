enum Contact {
  // white end 
  W(2, "W"),
  // white end corners
  WC1(1, "W"), WC2(1, "W"), WC3(1, "W"), WC4(1, "W"),
  // white end small edges
  WSE1(1, "W"), WSE2(1, "W"),
  // white end med edges
  WME1(2, "W"), WME2(2, "W"),
  
  // long edges
  LE1(2, "M"), LE2(2, "M"), LE3(2, "M"), LE4(2, "M"),
  
  // medium sides
  MS1(2, "M"), MS2(2, "M"),
  
  // large sides
  LS1(4, "M"), LS2(4, "M"),
  
  // black end 
  B(2, "B"),
  // white end corners
  BC1(1, "B"), BC2(1, "B"), BC3(1, "B"), BC4(1, "B"),
  // white end small edges
  BSE1(1, "B"), BSE2(1, "B"),
  // white end med edges
  BME1(2, "B"), BME2(2, "B");
  
  public int numPts;
  public final String end; // W for white end, B for black end, M for middle
  
  Contact(int numPts, String end){
    this.numPts = numPts;
    this.end = end;
  }
}