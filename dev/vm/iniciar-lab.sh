if [ $# -eq 0 ]
then
  echo "$0 : Introduce la cantidad de máquinas que quieres iniciar"
  exit 1
fi

for ((  i = 1 ;  i <= $1;  i++  ))
do
  virsh -c qemu:///system start karmic-6GB-$i-lab
done
