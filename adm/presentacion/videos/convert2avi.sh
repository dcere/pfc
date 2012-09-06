echo "converting" $1
filename=${1%.*}
mencoder "$1" -ovc xvid -oac mp3lame -xvidencopts pass=1 -o $filename.avi
