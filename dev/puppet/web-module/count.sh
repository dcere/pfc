echo "Lines of code (ruby, shell and puppet):"
find . -path './grammar' -prune -o -print | egrep '\.rb|\.sh|\.pp' | grep -v '\.git' | xargs cat | sed '/^\s*$/d' | wc -l
echo -e "\nRuby"
find . -path './grammar' -prune -o -print | egrep '\.rb' | grep -v '\.git' | xargs cat | sed '/^\s*$/d' | wc -l
echo -e "\nPuppet"
find . -path './grammar' -prune -o -print | egrep '\.pp' | grep -v '\.git' | xargs cat | sed '/^\s*$/d' | wc -l
echo -e "\nShell"
find . -path './grammar' -prune -o -print | egrep '\.sh' | grep -v '\.git' | xargs cat | sed '/^\s*$/d' | wc -l