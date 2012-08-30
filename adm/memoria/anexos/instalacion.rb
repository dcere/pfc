def get_chapters(file, path)
   Dir.foreach(path) do |name|
      if !File.directory?(path + name)
         puts "Añadiendo #{name}"
         file_aux = File.open(path + name, 'r')
         file.puts(file_aux.read())
         file_aux.close()
      end
   end
end

file = File.open("instalacion.tex", 'w')

# Encabezamiento
file.puts "\\chapter{Instalación}"
file.puts "\\label{anx:instalacion}"
file.puts "\n\n"

# Read all the files
get_chapters(file, "./instalacion/")

# Close file
file.close()