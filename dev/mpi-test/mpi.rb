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


neptune (
  :type => "mpi",
  :code => "/tmp/mpi-test",
  :nodes_to_use => 2,
  :output => "/tmp/mpi-test-output"
)
