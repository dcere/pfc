echo "Lines of code (ruby, shell and puppet):"
find . -path './grammar' -prune -o -print | egrep '\.rb|\.sh|\.pp' | grep -v '\.git' | xargs cat | sed '/^\s*$/d' | wc -l
