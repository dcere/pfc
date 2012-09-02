CLOUD_PATH = "../../../../dev/puppet/generic-module/provider/"

APPSCALE_TYPE_PATH  = "../../../../dev/puppet/appscale-module/lib/puppet/type/"
APPSCALE_PROV1_PATH = "../../../../dev/puppet/appscale-module/lib/puppet/provider/appscale/"
APPSCALE_PROV2_PATH = "../../../../dev/puppet/appscale-module/lib/puppet/provider/appscale/appscale/"

TORQUE_TYPE_PATH  = "../../../../dev/puppet/torque-module/lib/puppet/type/"
TORQUE_PROV1_PATH = "../../../../dev/puppet/torque-module/lib/puppet/provider/torque/"
TORQUE_PROV2_PATH = "../../../../dev/puppet/torque-module/lib/puppet/provider/torque/torque/"

WEB_TYPE_PATH  = "../../../../dev/puppet/web-module/lib/puppet/type/"
WEB_PROV1_PATH = "../../../../dev/puppet/web-module/lib/puppet/provider/web/"
WEB_PROV2_PATH = "../../../../dev/puppet/web-module/lib/puppet/provider/web/web/"

def get_section(file, path)
   Dir.foreach(path) do |name|
      if !File.directory?(path + name)
         puts "Añadiendo #{name}"
         latex_name = name.gsub(/\_/,"\\_")     # Cambia a_b por a\_b para latex
         file.puts "\\subsection{#{latex_name}}\n\n\n"
         file.puts "\\begin{lstlisting}"
         file_aux = File.open(path + name, 'r')
         file.puts(file_aux.read())
         file.puts "\\end{lstlisting}\n\n\n"
         file_aux.close()
      end
   end
end

file = File.open("codigo.tex", 'w')

# Encabezamiento
file.puts "\\chapter{Código fuente}"
file.puts "\\label{anx:codigo}"
file.puts "\n\n"

# Sección cloud
file.puts "\\section{generic-module}"
get_section(file, CLOUD_PATH)
puts

# Sección appscale
file.puts "\\section{appscale}"
get_section(file, APPSCALE_TYPE_PATH)
get_section(file, APPSCALE_PROV1_PATH)
get_section(file, APPSCALE_PROV2_PATH)
file.puts File.open("appscale-manifests.tex", 'r').read
puts

# Sección torque
file.puts "\\section{torque}"
get_section(file, TORQUE_TYPE_PATH)
get_section(file, TORQUE_PROV1_PATH)
get_section(file, TORQUE_PROV2_PATH)
file.puts File.open("torque-manifests.tex", 'r').read
puts

# Sección web
file.puts "\\section{web}"
get_section(file, WEB_TYPE_PATH)
get_section(file, WEB_PROV1_PATH)
get_section(file, WEB_PROV2_PATH)
file.puts File.open("web-manifests.tex", 'r').read
puts

file.close()