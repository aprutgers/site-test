import sys
import argparse
import log

g_debug = 0

def get_domains():
    df="/home/ec2-user/site-test/domains"
    f = open(df, "r")
    domains=''
    for line in f:
       domain = line.split(':')[0]
       if not domain in domains: #unique
          domains = domains + domain + "\n"
    f.close()
    return domains

def get_runner_count(domain):
    df="/home/ec2-user/site-test/domains"
    f = open(df, "r")
    count=0
    for line in f:
       if (line.split(':')[0] == domain):
          count=line.split(':')[1].count(',')-1
          f.close()
          return count

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
             cols = line.split(':')
             key=cols.pop(0)
             key=key.replace('"','')
             val=':'.join(cols)
             val=val.replace('"','')
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
   df="/home/ec2-user/site-test/"+domain+"/delay"
   f = open(df, "r")
   mindelay=f.readline().strip()
   maxdelay=f.readline().strip()
   f.close()
   df="/home/ec2-user/site-test/"+domain+"/minmax"
   f = open(df, "r")
   minwait=f.readline().strip()
   maxwait=f.readline().strip()
   stepsz=f.readline().strip()
   chance=f.readline().strip()
   f.close()
   df="/home/ec2-user/site-test/"+domain+"/ctr"
   f = open(df, "r")
   ctr=f.readline().strip()
   f.close()
   runners = get_runner_count(domain)
   json = '{\n'
   json = json + (' "%s" : "%s..%ss" '%('minmax',minwait,maxwait))+",\n"
   json = json + (' "%s" : "%s..%ss" '%('runval',mindelay,maxdelay))+",\n"
   json = json + (' "%s" : "%s" '%('runners',runners))+",\n"
   json = json + (' "%s" : "%s%s" '%('site-ctr',int(ctr)/10,'%')) # no comma for last line
   json = json + '\n}'
   return json

def update_ctr(domain,ctr):
   if (not ctr.isnumeric()):
      print("ERROR: ctr value '%s' is not numeric"%(ctr))
      return 'ERROR not numeric'
   if (int(ctr)>100): # >10% CTR is too high
      print("ERROR: ctr value '%s' is too high!!"%(ctr))
      return 'ERROR value too high'
   try:
      df="/home/ec2-user/site-test/"+domain+"/ctr"
      f = open(df, "w")
      f.write(ctr+"\n")
      f.close()
      log.logdebug('updated ctr value for domain='+domain+' to value=' + ctr)
      return 'UPDATED OK'
   except Exception as err:
      log.logerror(err)
      return err

def main():
   d_domain='all'
   d_action='get'
   d_debug=0
   d_part='1'
   d_ctr='5'
   parser = argparse.ArgumentParser(description='provide home power measurements at P1 port - KWh production, KWh usage and gas m3')
   parser.add_argument('--action',dest='action',action='store',default=d_action,help='action get or put')
   parser.add_argument('--domain',dest='domain',action='store',default=d_domain,help='site test domain')
   parser.add_argument('--part',dest='part',action='store',default=d_part,help='part of stats 1 or 2')
   parser.add_argument('--ctr',dest='ctr',action='store',default=d_ctr,help='ctr value in case of put')
   parser.add_argument('--debug', dest='debug', action='store',default=d_debug, help='for debug provide 1 or 2')
   args=vars(parser.parse_args())
   action = args['action']
   domain = args['domain']
   part   = args['part']
   ctr    = args['ctr']
   g_debug= int(args['debug'])

   if (action=='get'):
      if (domain=='all'):
         if (g_debug): print("return domains")
         print(get_domains())
      else:
         if (g_debug): print("print_domain_card domain="+domain)
         if (domain=='stats'):
            print(get_stats_card(part))
         else: 
            print(get_domain_card(domain))
   if (action=='put'):
      update_ctr(domain,ctr)

def webmain(p_action,p_domain,p_part,p_ctr,p_debug):
   d_domain='all'
   d_action='get'
   d_debug=0
   d_part='1'
   d_ctr='5'

   action = d_action if p_action is None else p_action
   domain = d_domain if p_domain is None else p_domain
   part   = d_part   if p_part   is None else p_part
   ctr    = d_ctr    if p_ctr    is None else p_ctr
   g_debug= p_debug

   if (action=='get'):
      if (domain=='all'):
         log.logdebug("return domains")
         return get_domains()
      else:
         log.logdebug("print_domain_card domain="+domain)
         if (domain=='stats'):
            return get_stats_card(part)
         else: 
            return get_domain_card(domain)
   if (action=='put'):
      return update_ctr(domain,ctr)
   return('unknown action')

if __name__ == "__main__":
    main()
