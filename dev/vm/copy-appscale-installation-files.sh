if [ $# -eq 0 ]
then
  echo "You must supply a valid IP:"
  echo "  $0 <@IP> [<appscale path> <appscale-tools path>]"
  exit 1
fi

if [ $# -eq 1 ]
then
  APPSCALE_PATH="./"
  APPSCALE_TOOLS_PATH="./"
fi

if [ $# -eq 2 ]
then
  echo "You must supply a valid IP and both or neither paths:"
  echo "  $0 <@IP> [<appscale path> <appscale-tools path>]"
  exit 1
fi

if [ $# -eq 3 ]
then
  APPSCALE_PATH=$2
  APPSCALE_TOOLS_PATH=$3
fi

APPSCALE=appscale-1.5.1
APPSCALE_TOOLS=appscale-tools

DESTINATION_PATH="root@$1:/root/."

scp -r $APPSCALE_PATH/$APPSCALE                $DESTINATION_PATH
scp -r $APPSCALE_TOOLS_PATH/$APPSCALE_TOOLS    $DESTINATION_PATH
