import urllib2;
import numpy as np;
import json;
from pyproj import Geod;
import sys;

# def targetLocation(availableLot):
#     #Find the available parking places
#     parkingLotIndex=[]
#     for i,lot in enumerate(availableLot):
#         if lot>0:
#             parkingLotIndex.append(i);
#     return parkingLotIndex;

def GSV_json(origin='Kirby,Champaign,IL',destination='Newmark,Urbana,IL'):
    api_key='AIzaSyD_JJNuZDUanL0ZKuOzGVSt1FQgDQYNnPM';
    url_json='https://maps.googleapis.com/maps/api/directions/json?origin='+origin+'&destination='+destination+'&sensor=false&key='+api_key+'&mode=driving';
    # print url_json;

    req = urllib2.Request(url_json)
    f = urllib2.urlopen(req);
    content = f.read();
    response = json.loads(content)
    #print response;
    
    steps=response['routes'][0]['legs'][0]['steps']
    distance=response['routes'][0]['legs'][0]['distance']['value']

    allstepPoints=[];
    allDistance=[];
    for step in steps:
        ### parse the points from polyline
        step_distance=step['distance'];
        step_start=step['start_location'];
        step_end=step['end_location'];
        poly_encode=step['polyline']['points'];
        # coord_points=decode_line(poly_encode);

        allstepPoints.append(poly_encode);
        allDistance.append(step_distance);

    return distance,allstepPoints; ### Return points along the polyline of path


if __name__ == '__main__':

    print "Available Parking Lot will be, Grainger, ISSS, iHotel"
    argc = len(sys.argv)

    # origin='Illini+Hall,Urbana,IL';
    origin=sys.argv[1]
    availableLot=[['Grainger','40.11,-88.22'],['ISSS','40.11,-88.23'],['iHotel','40.09,-88.24']];# This is the data base containing all available parking lotss
    distanceList=[];
    stepList=[]
    for dest in availableLot:
        destination=dest[1];
        distance,steps=GSV_json(origin,destination);
        distanceList.append(distance)
        stepList.append(steps)

    distanceList=np.array(distanceList)
    minIndex=np.argmin(distanceList)

    # print "Distance between to destinations",distanceList
    print "Your nearest parking lot is ",availableLot[minIndex][0],",",distanceList[minIndex],"m from here"



