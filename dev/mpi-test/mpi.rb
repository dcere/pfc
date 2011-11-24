# run mpi-version
#job "mpi" do
#@code = "MpiQueen"
#@nodes_to_use = 4
#@output = "/mpi/nqueens"
#end

# MPI test for Neptune

neptune (
  :type => "mpi",
  :code => "/tmp/mpi-test",
  :nodes_to_use => 2,
  :output => "/tmp/mpi-test-output"
)
