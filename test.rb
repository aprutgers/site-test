$free_mem=128
$used_mem=800

# memory trashing protection
$instance=0

def mem_check()
   cmd="free -m|grep Mem|awk '{ print $4 }'"
   f = IO.popen(cmd)
   free = f.readlines[0].strip().to_i
   f.close()
   print "free memory: #{free} MB"

   # container memory usage
   cid = "run50" + sprintf("%02d",$instance)
   cmd = "docker stats #{cid} --no-stream|grep -v CONTAINER | awk '{ print $4 }'|cut -d. -f1"
   print "cid: #{cid}"
   f = IO.popen(cmd)
   data = f.readlines[0]
   if (data) 
      used = data.strip().to_i
      print "container used memory: #{used} MB"
      if (free < $free_mem && used > $used_mem)
         log "MEMORY BAIL due to low memory mark free mem: #{free} < mark: #{$free_mem}"
         exit(1)
      end
   end
end

mem_check()
