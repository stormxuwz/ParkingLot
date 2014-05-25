#ifndef PARKINGLOT_H
#define PARKINGLOT_H

typedef nx_struct lots_msg {
  nx_uint8_t nodeid; 
  nx_int16_t counter;
  //nx_uint16_t counterUp;
  //nx_uint16_t counterDown;
  nx_uint8_t type;
  //nx_uint8_t counterForward;
} lots_msg_t;

enum {
   AM_MY_MSG=10,
   NROW=9,
   NCOL=10,
   A=5,
};

#endif