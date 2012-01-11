# Description:
#   Parses the face ruby file.
#
# Synopsis:
#   parse-face.sh <face>
#
# Arguments:
#   - Face The face to be parsed.
#
# Examples:
#   _$: parse-face.sh myface
#
#
# Author:
#   David Ceresuela

# Check arguments
if [ $# -eq 0 ]
then
  echo "You must supply a face:"
  echo "  $0 <face>"
  exit 1
fi

# Parse the file
ruby ./face/$1.rb
