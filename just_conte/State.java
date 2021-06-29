/*
Valid states for StateManager and Menu3D are AIR and SELECTED

Valid transitions:
AIR->SELECTED
SELECTED->AIR

Menu is not a state and is turned on/off by a key
*/

/* 
CHANGED UP TO AIR LATER SO IF WANT TO USE THIS CODE WILL HAVE TO CHANGE ALL UPS TO AIR
TO BE COMPATIBLE WITH BASE CODE
these are the types of states we can be in for StateManagerRoll and MenuRoll
Valid transitions:

UP -> WAITINGFORROLL // if valid roll point is down
UP -> SELECTED // if non-roll point down

MENU -> UP // have to lift after menu

SELECTED -> UP // have to lift after selection

WAITINGFORROLL -> MENU // roll to menu point
WAITINGFORROLL -> SELECTED // wait long enough that we're selected
WAITINGFORROLL -> UP // lift up
*/
  enum StateType {
    AIR, // nothing touching the screen 
    MENU, // menu is currently on
    SELECTED, // a non-menu point is currently "on"
    WAITINGFORROLL // touched screen with valid roll point, waiting to see if user rolls to menu
  }