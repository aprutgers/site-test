import datetime

DEBUG=1

#
# basic logging
#
def logerror(data):
   dt = str(datetime.datetime.now())
   print(dt + " ERROR: " + str(data))

def loginfo(data):
   dt = str(datetime.datetime.now())
   print(dt + " INFO: " + str(data))

def logdebug(data):
   if (DEBUG == 1):
      dt = str(datetime.datetime.now())
      print(dt + " DEBUG: " + str(data))

