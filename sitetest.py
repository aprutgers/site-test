import sys
import subprocess
import argparse

g_debug = 0

def get_domains():
    df="/home/ec2-user/site-test/domains"
    f = open(df, "r")
    domains=''
    for line in f:
       domains = domains + line.split(':')[0] + "\n"
    f.close()
    return domains

def split_list(a_list):
    half = len(a_list)//2
    return a_list[:half], a_list[half:]

# create stats card
def get_stats_card(part):
   keyvals=[]
   df="/home/ec2-user/site-test/collect_stats.txt"
   f = open(df, "r")
   for line in f:
      if ('LATEST ADVERT_CLICK RESULTS' in line):
         break
      try:
         if (":" in line):
             line=line.strip()
             key=line.split(':')[0]
             val=line.split(':')[1]
             #json = json + (' "%s" : "%s" '%(key,val))+",\n"
             keyvals.append(' "%s" : "%s" '%(key,val))
      except Exception as err:
         print(err)
   f.close()

   p1,p2=split_list(keyvals)
   if (part == '1'): return '{\n' + ',\n'.join(p1) + '\n}'
   if (part == '2'): return '{\n' + ',\n'.join(p2) + '\n}'
   return part

# create domain card and print as json
def get_domain_card(domain):
   json = '{\n'
   df="/home/ec2-user/site-test/"+domain+"/delay"
   f = open(df, "r")
   mindelay=f.readline().strip()
   maxdelay=f.readline().strip()
   f.close()
   df="/home/ec2-user/site-test/"+domain+"/ctr"
   f = open(df, "r")
   ctr=f.readline().strip()
   f.close()
   pageviews=0
   pacepct=0
   df="/home/ec2-user/site-test/collect_stats.txt"
   f = open(df, "r")
   for line in f:
      if (domain in line): 
         # example return data infonu.nl: 3175 (39.45%)
         line=line.strip()
         pageviews=line.split(":")[1].split(' ')[1]
         pagepct=line.split(":")[1].split(' ')[2]
         pagepct=pagepct.replace('(','')
         pagepct=pagepct.replace(')','')
         break;
   f.close()

   json = json + (' "%s" : "%s..%ss" '%('min/max-delay',mindelay,maxdelay))+",\n"
   #json = json + (' "%s" : "%s" '%('max-delay',maxdelay))+",\n"
   json = json + (' "%s" : "%s" '%('site-ctr',ctr))# +",\n"
   #json = json + (' "%s" : "%s" '%('pageviews',pageviews))+",\n"
   #json = json + (' "%s" : "%s" '%('page%',pagepct))
   json = json + '\n}'

   return json

def main():
   d_domain=''
   d_debug=0
   d_part='1'
   parser = argparse.ArgumentParser(description='provide home power measurements at P1 port - KWh production, KWh usage and gas m3')
   parser.add_argument('--domain',dest='domain',action='store',default=d_domain,help='site test domain')
   parser.add_argument('--part',dest='part',action='store',default=d_part,help='part of stats 1 or 2')
   parser.add_argument('--debug', dest='debug', action='store',default=d_debug, help='for debug provide 1 or 2')
   args=vars(parser.parse_args())
   domain = args['domain']
   part   = args['part']
   g_debug= int(args['debug'])

   if (domain==''):
      if (g_debug): print("return domains")
      print(get_domains())
   else:
      if (g_debug): print("print_domain_card domain="+domain)
      if (domain=='stats'):
         print(get_stats_card(part))
      else: 
         print(get_domain_card(domain))

main()
