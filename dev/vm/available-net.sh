for ((  i = 1 ;  i <= 254;  i++  ))
do
  IP=155.210.155.$i
  ping -c 1 -W 1 $IP > /dev/null; test $? -eq 0 && echo -e "$IP\tUP: NOT AVAILABLE" || echo -e "$IP\tDOWN: AVAILABLE"
done
