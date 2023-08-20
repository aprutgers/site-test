$free_mem=128
 # memory trashing protection
   f = IO.popen("free -m|grep Mem|awk '{ print $4 }'")
   free = f.readlines[0].strip().to_i
   f.close()
   print "free memory: #{free} MB"
 
   if (free < $free_mem)
      log "MEMORY BAIL due to low memory mark free mem: #{free} < mark: #{$free_mem}"
      exit(1)
   end

