COMPONENT=ParkingLotAppC
BUILD_EXTRA_DEPS = ParkingLot.py
CLEAN_EXTRA = ParkingLot.py

ParkingLot.py: ParkingLot.h
	mig python -target=$(PLATFORM) $(CFLAGS) -python-classname=ParkingLot ParkingLot.h lots_msg -o $@

include $(MAKERULES)

