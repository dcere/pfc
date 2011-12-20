# run mpi-version
#job "mpi" do
#@code = "MpiQueen"
#@nodes_to_use = 4
#@output = "/mpi/nqueens"
#end

# MPI test for Neptune
#
# Syntax follows the one used on http://www.neptune-lang.org/
#
#                neptune (
#                  :type => "mpi",
#                  :output => "/mpi-output.txt",
#                  :code => "powermethod",
#                  :nodes_to_use => 16
#                )


# Input job
neptune (
  :type => "input"
  :local => "/home/dceresuela/PFC/pfc/dev/mpi-test/mpi"
  :remote => "/mpi"
)


# MPI job
neptune (
  :type => "mpi",
  :code => "/mpi",
  :nodes_to_use => 2,
  :output => "/mpi-output.txt"
)


# Output job
output = neptune (
  :type => "output"
  :output => "/mpi-output.txt"
)
puts "Output message: #{output[:msg]}"
puts "Output result: #{output[:res]}"
