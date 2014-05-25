#! /usr/bin/python
import sys
sys.path.append('/Users/XuWenzhao/w/rh/tinyos-main/support/sdk/python')

from TOSSIM import *
from ParkingLot import *
from random import *
from tinyos.tossim.TossimApp import *

def injection(node=3,Msgtype=0,data=10):
  # Inject a packet with data to node, by Msgtype AM message
  msg = ParkingLot()
  msg.set_counter(data)
  msg.set_type(Msgtype)
  pkt = t.newPacket()
  pkt.setData(msg.data)
  pkt.setType(msg.get_amType())
  pkt.setDestination(node); 
  pkt.deliver(node, t.time()+2)

 

def injectionList(NodeList,dataList):
  for i,node in enumerate(NodeList):
      injection(node=node,data=dataList[i])
      for i in range(20000):
        t.runNextEvent()

def MoniCommNode():
  # Initialize the nodes that might be monitorred often
  for i in [37,40,54,77,80]:
    m = t.getNode(i)
    v_Counterup = m.getVariable("ParkingLotC.counterUp")
    v_Counterdown = m.getVariable("ParkingLotC.counterDown")
    v_forward = m.getVariable("ParkingLotC.NodeForward")
    v_Nodeup=m.getVariable("ParkingLotC.NodeUp")
    v_Nodedown=m.getVariable("ParkingLotC.NodeDown")


def getInfo(i):
  # Get the node information
  m = t.getNode(i)
  v_Counterup = m.getVariable("ParkingLotC.counterUp")
  v_Counterdown = m.getVariable("ParkingLotC.counterDown")
  v_forward = m.getVariable("ParkingLotC.NodeForward")
  v_Nodeup=m.getVariable("ParkingLotC.NodeUp")
  v_Nodedown=m.getVariable("ParkingLotC.NodeDown")
  
  counter=[v_Counterup.getData()+v_Nodeup.getData(),v_Counterdown.getData()+v_Nodedown.getData(),v_forward.getData()]
  print "Node",i,"UP,DOWN,FORWARD",counter;

def Initialize():  ## Initialize node configurations through injection
  injection(node=20,Msgtype=3)
  injection(node=40,Msgtype=3)
  injection(node=60,Msgtype=3)
  injection(node=80,Msgtype=3)

  for i in range(10000):
    # Wait entil boundary nodes initial up;
    t.runNextEvent()
  
  # Initialize all node config
  injection(node=3,data=0)
  injection(node=5,data=0)
  injection(node=6,data=0)
  injection(node=8,data=0)
  injection(node=9,data=0)

  # Doule initialize to make sure the packet is reveived
  injection(node=3,data=0)
  injection(node=5,data=0)
  injection(node=6,data=0)
  injection(node=8,data=0)
  injection(node=9,data=0)

  for i in range(30000):
    # Wait entil all nodes initial up;
    t.runNextEvent()

  injection(node=83,data=0)
  injection(node=85,data=0)
  injection(node=86,data=0)
  injection(node=88,data=0)
  injection(node=89,data=0)
  injection(node=83,data=0)
  injection(node=85,data=0)
  injection(node=86,data=0)
  injection(node=88,data=0)
  injection(node=89,data=0)

  for i in range(10000):
    t.runNextEvent()


### Initialize the system
n = NescApp()
vars = n.variables.variables()
# t = Tossim([])
t = Tossim(vars);
r = t.radio()

t.addChannel("ParkingLotC", sys.stdout)
N=100;
for i in range(1, N):
  m = t.getNode(i)
  m.bootAtTime(i + 100)
  # m.turnOn()

f = open("text.txt", "r")
for line in f:
  s = line.split()
  if s:
    r.add(int(s[0]), int(s[1]), float(s[2]))

noise = open("meyer-heavy.txt", "r")
for line in noise:
  s = line.strip()
  if s:
    val = int(s)+25;
    for i in range(1,N):
      t.getNode(i).addNoiseTraceReading(val)

for i in range(1,N):
   t.getNode(i).createNoiseModel()



for i in range(10000):
  # Wait entil all nodes start up;
  t.runNextEvent()





# All Initialized 
Initialize()
Initialize() # Double initialize to ensure all nodes are correctly set up
for i in range(40000):
  t.runNextEvent()
MoniCommNode()


# getInfo(54);
raw_input("All Set Up")
getInfo(37);


raw_input("A car parked at 48")
injection(node=48,data=-1)
for i in range(50000):
  t.runNextEvent()



raw_input("A car parked at 6")
injection(node=6,data=-1)
for i in range(50000):
  t.runNextEvent()



raw_input("A car parked at 26")
injection(node=26,data=-1)
for i in range(50000):
  t.runNextEvent()



raw_input("A car left at 6")
injection(node=6,data=1)
for i in range(50000):
  t.runNextEvent()


raw_input("A car parked at 86")
injection(node=86,data=-1)
for i in range(80000):
  t.runNextEvent()




raw_input("cars parked at 9,29,49,69,89")

injection(node=9,data=-5)
for i in range(40000):
  t.runNextEvent()

injection(node=29,data=-5)
for i in range(40000):
  t.runNextEvent()

injection(node=49,data=-5)
for i in range(40000):
  t.runNextEvent()

injection(node=69,data=-5)
for i in range(40000):
  t.runNextEvent()

injection(node=89,data=-5)
for i in range(80000):
  t.runNextEvent()



