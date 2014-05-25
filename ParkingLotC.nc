#include "ParkingLot.h"

module ParkingLotC @safe() {
	uses {
		interface Boot;
		interface Receive;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Packet;
		interface Timer<TMilli> as MilliTimer;
	}
}

implementation{
	message_t packet;
	bool locked;
	int16_t counter=0; //The Delta counter inside
	uint16_t NodeDown=0;        // The lower node's down direction counter E.g. For node 37, this is the node 57's downward direction number
    uint16_t NodeUp=0;	        // The upper node's up direction counter E.g. For node 37, this is the node 17's upward direction number
	uint8_t NodeForward=1;		// Whether the forward node is available, i.e. the forward direction is available. 
	uint8_t available=1;	  // whether the node is available to backward node
	uint8_t msgType=0;         //message type
	uint16_t counterUp=A*2;	   //  The available spots in the lower blocks. E.g. for node 37, this summarizes the total available spots in node 46 and 48
	uint16_t counterDown=A*2;   // The available spots in the upper blocks. E.g. for node 37, this summarizes the total available spots in node 26 and 28
	bool changed = 0;          // Indicate whether it is need to send information to othe nodes
	bool isSpot = 0;       //Whether this node is a spot nodes
	uint8_t DestNode=0;    // Destination node the message need to send to 

	/*This is the node boot part*/
	event void Boot.booted(){
		call AMControl.start();
	}

	event void AMControl.startDone(error_t err){
		if(err==SUCCESS){
			call MilliTimer.startPeriodic(5000);
			//dbg("ParkingLotC","Node %hhu Boot Successful . \n",TOS_NODE_ID);
		}
		else{
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err){
		//Do Nothing
	}

	/*Receiving Information*/
	event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
		//dbg("ParkingLotC","receive a message \n");
		
		if (len != sizeof(lots_msg_t)) {
		 	// If the packet is bad:
		 	dbg("ParkingLotC","Wrong Length");
      		return bufPtr;
    	}
    	else{
    		//If the packet if good, then parse the packet
    		lots_msg_t * msg=(lots_msg_t *) payload;
			// Type=0, This is inject information
    		if(msg->type==0){
                // If this messsage is a injection message
    			//dbg("ParkingLotC","%hhu receive a message from %hhu,type is 0.\n",TOS_NODE_ID,msg->nodeid);
    			//dbg("ParkingLotC","original counter %hhu.\n",counter);
    			//dbg("ParkingLotC","msg counter %hhu.\n",msg->counter);
    			counter=counter+msg->counter;
    			isSpot=1; // Only spot node can receive type=0 message
    			changed=1;
    			//dbg("ParkingLotC","post counter %hhu.\n",counter);
    		}

    		else if(msg->type==3){
    			// This is the message for set up;
				NodeForward=0;

				counterUp=A;
				counterDown=A;
    		}

    		// Type>0, the packet is inside the network
    		else{
    			//If the packet is send from child node;
    			if(msg->type==1){
    				//dbg("ParkingLotC","%hhu receive a message from %hhu,type is 1, counter=%hhu,\n",TOS_NODE_ID,msg->nodeid,msg->counter);	
    				if(msg->nodeid<TOS_NODE_ID){
    					// This is the message from upper spot node;
    					counterUp += msg->counter;
    					DestNode=TOS_NODE_ID+2*NCOL; // propagate to lower node
    					counter=NodeUp+counterUp;
    				}
    				else{
                        // This is the message from lower spot node
    					counterDown += msg->counter;
    					DestNode=TOS_NODE_ID-2*NCOL;   // propagate to uppwer node
    					counter=NodeDown+counterDown;
    				//	dbg("ParkingLotC","counterDown=%hhu,NodeDown=%hhu,\n",counterDown,NodeDown);
    				}
    				changed=1;
    			}

    			//If the packet is in the central node network
    			else {
    				//dbg("ParkingLotC","%hhu receive a message from %hhu,type is 2, counter=%hhu \n",TOS_NODE_ID,msg->nodeid,msg->counter);
    				
    				if(msg->nodeid>TOS_NODE_ID+3){ // Packet from lower node
    					if(NodeDown != msg->counter){
    						changed = 1; 
    						NodeDown = msg->counter;
    						DestNode=TOS_NODE_ID-2*NCOL; // propagate to upper node
    						counter=NodeDown+counterDown;
    				//		dbg("ParkingLotC","counter=%hhu,NodeDown=%hhu,\n",counter,NodeDown);
    					}

    				}
    				else if (msg->nodeid==TOS_NODE_ID+3){
							NodeForward=msg->counter;
    				}

    				else if (NodeUp != msg->counter){ // Packet from upper node
    					changed = 1;
    					//NodeUp = counterUp+msg->counter;
    					NodeUp=msg->counter;
    					DestNode=TOS_NODE_ID+2*NCOL; // propagate to lower node
    					counter=NodeUp+counterUp;
    				}
    			}
			}			

    		return bufPtr;
    	}
    }


	event void MilliTimer.fired() {
		//dbg("ParkingLotC","Changed? %hhu \n",changed);
    	if (!locked && changed==0) {
    		//Change from available to unavailable
    		if (available==1 && NodeForward+NodeUp+counterUp+counterDown+NodeDown==0){
				lots_msg_t* msg_send=(lots_msg_t*) call Packet.getPayload(&packet, sizeof(lots_msg_t));
				if(msg_send==NULL)
					return;
				
				msg_send->counter=0;
				msg_send->nodeid=TOS_NODE_ID;
				msg_send->type=2;
				available=0;

				if (call AMSend.send(TOS_NODE_ID-3, &packet, sizeof(lots_msg_t)) == SUCCESS) {
	   				//dbg("ParkingLotC", "1 to 0 packet sent from %hhu to %hhu. \n", TOS_NODE_ID,TOS_NODE_ID-3);	
	   				locked = TRUE;
	   				changed=0;
	   				counter=0;
				}
			}
            //Change from unavailable to available
			else if(available==0 && NodeForward+counterUp+counterDown+NodeUp+NodeDown>0){
				
				lots_msg_t* msg_send=(lots_msg_t*) call Packet.getPayload(&packet, sizeof(lots_msg_t));
				if(msg_send==NULL)
					return;
				
				msg_send->counter=1;
				msg_send->nodeid=TOS_NODE_ID;
				msg_send->type=2;
				available=1;

				if (call AMSend.send(TOS_NODE_ID-3, &packet, sizeof(lots_msg_t)) == SUCCESS) {
	   				//dbg("ParkingLotC", "0 to 1 packet sent from %hhu to %hhu. \n", TOS_NODE_ID,TOS_NODE_ID-3);	
	   				locked = TRUE;
	   				changed=0;
	   				counter=0;
				}
			}
			else{
				if(TOS_NODE_ID==37){ //This is for printing the information of node 37 dynamically
    				dbg("ParkingLotC","Up,Down,Forward, %hhu,%hhu,%hhu.\n",NodeUp+counterUp,NodeDown+counterDown,NodeForward);
    			}
			}	

    	}
    	else if(locked){
    		return;
    	}

    	else{
    		// dbg("ParkingLotC","Up,Down,Forward, %hhu,%hhu,%hhu.\n",counterUp+NodeUp,counterDown+NodeDown,NodeForward);
    		if(isSpot){
                // This is a spot node
    			lots_msg_t* msg_send=(lots_msg_t*) call Packet.getPayload(&packet, sizeof(lots_msg_t));
    			// dbg("ParkingLotC",)

    			if(msg_send==NULL)
    				return;
    			msg_send->counter=counter;
    			msg_send->nodeid=TOS_NODE_ID;
    			msg_send->type=1;

    			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(lots_msg_t)) == SUCCESS){
	       			//dbg("ParkingLotC", "Type 1 packet sent from %hhu.\n", TOS_NODE_ID);	
	       			locked = TRUE;
	       			changed=0;
	       			counter=0;
     			}
    		}
    		
    		else {
    			if(changed==1){
    				lots_msg_t* msg_send=(lots_msg_t*) call Packet.getPayload(&packet, sizeof(lots_msg_t));
    				//dbg("ParkingLotC", "Due to Change");
    				if(msg_send==NULL)
    					return;
    				
    				msg_send->counter=counter;
    				msg_send->nodeid=TOS_NODE_ID;
    				msg_send->type=2;

    				if (call AMSend.send(DestNode, &packet, sizeof(lots_msg_t)) == SUCCESS) {
	       				//dbg("ParkingLotC", "Type 2 packet sent from %hhu to %hhu, counter= %hhu \n", TOS_NODE_ID,DestNode,counter);	
	       				locked = TRUE;
	       				changed=0;
	       				counter=0;
     				}
    			}   
    		}
    	}
    }

    event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    	if (&packet == bufPtr) {
    	//	dbg("ParkingLotC","Send Done\n");
      		locked = FALSE;
    	}
  	}
}