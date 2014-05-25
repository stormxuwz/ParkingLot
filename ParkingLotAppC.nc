#include "ParkingLot.h"


configuration ParkingLotAppC {}
implementation{
	components MainC, ParkingLotC as App;
	components new AMSenderC(AM_MY_MSG);
  	components new AMReceiverC(AM_MY_MSG);
	components ActiveMessageC;
	components new TimerMilliC();

	App.Boot -> MainC.Boot;
	App.Receive -> AMReceiverC;
  	App.AMSend -> AMSenderC;
  	App.AMControl -> ActiveMessageC;
  	App.Packet -> AMSenderC;
  	App.MilliTimer -> TimerMilliC;
}