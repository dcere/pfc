if [ $# -eq 0 ]
then
  echo "$0 : Introduce la cantidad de máquinas que quieres terminar"
  exit 1
fi

for ((  i = 1 ;  i <= $1;  i++  ))
do
  sudo virsh shutdown karmic-6GB-$i
done
