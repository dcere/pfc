# Description:
#   Pings lab machines to see if they are available. If a machine is using its
#   IP it means it is not available for us to use said IP.
#
# Synopsis:
#   available-machines.sh
#
# Arguments:
#   - None
#
# Examples:
#   _$: available-machines.sh
#
#
# Author:
#   David Ceresuela

#155.210.155.66  dom2
#155.210.155.67  rdp13
#155.210.155.69  mercurio2
#155.210.155.70  venus2
#155.210.155.73  urbion
#155.210.155.74  duero
#155.210.155.75  astazu
#155.210.155.76  numancia
#155.210.155.77  artigas
#155.210.155.78  amboto
#155.210.155.170 luna1
#155.210.155.171 luna2
#155.210.155.172 luna3
#155.210.155.173 luna4
#155.210.155.174 sol1
#155.210.155.175 sol2
#155.210.155.176 beta1
#155.210.155.177 beta2
#155.210.155.178 moloc
#155.210.155.179 ephaistos
#155.210.155.180 io


#for i in 66 67 69 70 73 74 75 76 77 78 170 171 172 173 174 175 176 177 178 179 180
for ((  i = 66 ;  i <= 78;  i++  ))
do
  IP=155.210.155.$i
  ping -c 1 -W 1 $IP > /dev/null; test $? -eq 0 && echo -e "$IP\tUP: NOT AVAILABLE" || echo -e "$IP\tDOWN: AVAILABLE"
done

for ((  i = 170 ;  i <= 180;  i++  ))
do
  IP=155.210.155.$i
  ping -c 1 -W 1 $IP > /dev/null; test $? -eq 0 && echo -e "$IP\tUP: NOT AVAILABLE" || echo -e "$IP\tDOWN: AVAILABLE"
done
