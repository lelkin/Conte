enum Contact {
  // white end 
  W(2),
  // white end corners
  WC1(1), WC2(1), WC3(1), WC4(1),
  // white end small edges
  WSE1(1), WSE2(1),
  // white end med edges
  WME1(2), WME2(2),
  
  // long edges
  LE1(2), LE2(2), LE3(2), LE4(2),
  
  // medium sides
  MS1(2), MS2(2),
  
  // large sides
  LS1(4), LS2(4),
  
  // black end 
  B(2),
  // white end corners
  BC1(1), BC2(1), BC3(1), BC4(1),
  // white end small edges
  BSE1(1), BSE2(1),
  // white end med edges
  BME1(2), BME2(2);
  
  public final int numPts;
  
  Contact(int numPts){
    this.numPts = numPts;
  }
}