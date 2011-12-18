# Programmer: Chris Bunch (cgb@cs.ucsb.edu)

$:.unshift File.join(File.dirname(__FILE__), "..", "..", "lib")
require 'neptune'

require 'test/unit'

class FakeAppControllerClient
  def initialize(a, b)
  end

  # Since all the methods we're faking take the same arguments and have
  # the same semantics (return true or abort), just cover it all in one place.
  def method_missing(id, *args, &block)
    method_names = ["get_output", "get_acl", "put_input", "set_acl"] +
      ["start_neptune_job"]
    if method_names.include?(id.to_s)
      return true
    else
      super
    end
  end
end

class FakeFileNeptuneTest
  def self.expand_path(path)
    return path
  end

  def self.exists?(file)
    if file.include?("EXISTS")
      return true
    else
      return false
    end
  end
end

module FakeKernel
  def `(command)
  end
end

module FakeCommonFunctions
  def self.scp_to_shadow(a, b, c, d=nil)
  end
end

class TestNeptune < Test::Unit::TestCase
  def test_do_preprocessing
    # Try a job that needs preprocessing
    job_data_1 = {"@type" => "ssa", "@trajectories" => 10}
    assert_nothing_raised(SystemExit) { do_preprocessing(job_data_1) }

    # Now try a job that doesn't need it
    job_data_2 = {"@type" => "input"}
    assert_nothing_raised(SystemExit) { do_preprocessing(job_data_2) }
  end

  def test_preprocess_compile
  end

  def test_preprocess_erlang
    # Try a job where we didn't specify the code
    job_data_1 = {}
    assert_raise(SystemExit) {
      preprocess_erlang(job_data_1, FakeFileNeptuneTest, FakeCommonFunctions)
    }

    # Try a job where the source doesn't exist
    job_data_2 = {"@code" => "NOT-EXISTANT"}
    assert_raise(SystemExit) {
      preprocess_erlang(job_data_2, FakeFileNeptuneTest, FakeCommonFunctions)
    }

    # Now try a job where the source does exist
    job_data_3 = {"@code" => "EXISTS"}
    assert_nothing_raised(SystemExit) {
      preprocess_erlang(job_data_3, FakeFileNeptuneTest, FakeCommonFunctions)
    }
  end

  def test_preprocess_mpi
    # not specifying nodes to use or procs to use should throw an error
    job_data_1 = {}
    assert_raise(SystemExit) { preprocess_mpi(job_data_1) }

    # not specifying procs to use should throw an error
    job_data_2 = {"@nodes_to_use" => 4}
    assert_raise(SystemExit) { preprocess_mpi(job_data_2) }

    # specifying procs to use == nodes to use should not throw an error
    job_data_3 = {"@nodes_to_use" => 4, "@procs_to_use" => 4}
    assert_equal(job_data_3, preprocess_mpi(job_data_3))

    # specifying procs to use < nodes to use should throw an error
    job_data_4 = {"@nodes_to_use" => 4, "@procs_to_use" => 1}
    assert_raise(SystemExit) { preprocess_mpi(job_data_4) }
 
    # specifying an empty string for argv should be ok
    job_data_5 = {"@nodes_to_use" => 4, "@procs_to_use" => 4, "@argv" => ""}
    assert_equal(job_data_5, preprocess_mpi(job_data_5))

    # specifying an empty array for argv should be ok
    job_data_6 = {"@nodes_to_use" => 4, "@procs_to_use" => 4, "@argv" => []}
    expected_job_data_6 = job_data_6.dup
    expected_job_data_6["@argv"] = ""
    assert_equal(expected_job_data_6, preprocess_mpi(job_data_6))

    # specifying something that's not a string or array for argv should throw
    # an error
    job_data_7 = {"@nodes_to_use" => 4, "@procs_to_use" => 4, "@argv" => 2}
    assert_raise(SystemExit) { preprocess_mpi(job_data_7) }

    # specifying a non-empty string for argv should be ok
    job_data_8 = {"@nodes_to_use" => 4, "@procs_to_use" => 4, "@argv" => "--file coo"}
    assert_equal(job_data_8, preprocess_mpi(job_data_8))

    # specifying a non-empty array for argv should be ok
    job_data_9 = {"@nodes_to_use" => 4, "@procs_to_use" => 4, "@argv" => ["--file", "coo"]}
    expected_job_data_9 = job_data_9.dup
    expected_job_data_9["@argv"] = "--file coo"
    assert_equal(expected_job_data_9, preprocess_mpi(job_data_9))
  end

  def test_preprocess_ssa
    job_data_1 = {}
    assert_raise(SystemExit) { preprocess_ssa(job_data_1) }

    job_data_2 = {"@trajectories" => 10}
    assert_equal(job_data_2, preprocess_ssa(job_data_2))

    job_data_3 = {"@simulations" => 10}
    expected_job_data_3 = {"@trajectories" => 10}
    assert_equal(expected_job_data_3, preprocess_ssa(job_data_3))

    job_data_4 = {"@trajectories" => 10, "@simulations" => 10}
    assert_raise(SystemExit) { preprocess_ssa(job_data_4) }
  end

  def test_get_job_data
    params_1 = {:type => :mpi}
    assert_raise(SystemExit) { get_job_data(params_1) }

    params_2 = {:type => :mpi, :output => "boo"}
    assert_raise(SystemExit) { get_job_data(params_2) }

    [:mpi, :upc, :x10].each { |type|
      params_3 = {:type => type, :output => "/boo"}
      expected_job_data_3 = {"@type" => "mpi", "@output" => "/boo",
        "@keyname" => "appscale"}
      assert_equal(expected_job_data_3, get_job_data(params_3))
    }

    params_4 = {:type => "input"}
    expected_job_data_4 = {"@type" => "input", "@keyname" => "appscale"}
    assert_equal(expected_job_data_4, get_job_data(params_4))

    params_5 = {:type => "input", :keyname => "boo"}
    expected_job_data_5 = {"@type" => "input", "@keyname" => "boo"}
    assert_equal(expected_job_data_5, get_job_data(params_5))

    params_6 = {:type => :mpi, :output => "/boo",
      :nodes_to_use => {"cloud1" => 1, "cloud2" => 1}}
    expected_job_data_6 = {"@type" => "mpi", "@output" => "/boo",
      "@keyname" => "appscale", "@nodes_to_use" => ["cloud1", 1, "cloud2", 1]}
    assert_equal(expected_job_data_6, get_job_data(params_6))
  end

  def test_validate_storage_params
    job_data_1 = {}
    expected_job_data_1 = {"@storage" => "appdb"}
    assert_equal(expected_job_data_1, validate_storage_params(job_data_1))

    job_data_2 = {"@storage" => "a bad value goes here"}
    assert_raise(SystemExit) { validate_storage_params(job_data_2) }

    job_data_3 = {"@storage" => "s3"}
    assert_raise(SystemExit) { validate_storage_params(job_data_3) }

    job_data_4 = {"@storage" => "s3", "@EC2_ACCESS_KEY" => "a",
      "@EC2_SECRET_KEY" => "b", "@S3_URL" => "c"}
    assert_equal(job_data_4, validate_storage_params(job_data_4))

    ENV['EC2_ACCESS_KEY'] = "a"
    ENV['EC2_SECRET_KEY'] = "b"
    ENV['S3_URL'] = "c"

    ["s3", "gstorage", "walrus"].each { |storage|
      job_data_5 = {"@storage" => storage}
      expected_job_data_5 = {"@storage" => "s3", "@EC2_ACCESS_KEY" => "a",
        "@EC2_SECRET_KEY" => "b", "@S3_URL" => "c"}
      assert_equal(expected_job_data_5, validate_storage_params(job_data_5))
    }
  end

  def test_get_input
  end

  def test_wait_for_compilation_to_finish
  end

  def test_compile_code
  end

  def test_run_job
    ssh_args = "boo!"
    shadow_ip = "localhost?"
    secret = "abcdefg"

    job_data_1 = {"@type" => "input"}
    assert_raises (SystemExit) { 
      run_job(job_data_1, ssh_args, shadow_ip, secret,
        FakeAppControllerClient, FakeFileNeptuneTest)
    }

    job_data_1 = {"@type" => "input", "@local" => "NON-EXISTANT"}
    actual_1 = run_job(job_data_1, ssh_args, shadow_ip, secret,
      FakeAppControllerClient, FakeFileNeptuneTest)
    assert_equal(:failure, actual_1[:result])

    job_data_2 = {"@type" => "input", "@local" => "EXISTS"}
    actual_2 = run_job(job_data_2, ssh_args, shadow_ip, secret,
      FakeAppControllerClient, FakeFileNeptuneTest)
    assert_equal(:success, actual_2[:result])

    # try an output job

    # try a get-acl job

    # try a set-acl job

    # try a compile job

    # try a compute job
  end
end
