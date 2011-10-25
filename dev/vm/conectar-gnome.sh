#gnome-terminal --tab -e 'ssh root@192.168.1.101'\
#               --tab -e 'ssh root@192.168.1.102'\
#               --tab -e 'ssh root@192.168.1.103'\
#               --tab -e 'ssh root@192.168.1.104'

COMMAND="gnome-terminal"
LIST=" "

if [ $# -eq 0 ]
then
  echo "$0 : Introduce la cantidad de máquinas a las que te quieres conectar"
  exit 1
fi

for ((  i = 1 ;  i <= $1;  i++  ))
do
  LIST="$LIST"" --tab -e ""'""ssh root@192.168.1.10$i""'"
done

COMMAND="$COMMAND""$LIST"
echo $COMMAND
