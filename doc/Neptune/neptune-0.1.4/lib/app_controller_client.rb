#!/usr/bin/ruby -w
# Programmer: Chris Bunch (cgb@cs.ucsb.edu)

require 'openssl'
require 'soap/rpc/driver'
require 'timeout'

# Sometimes SOAP calls take a long time if large amounts of data are being
# sent over the network: for this first version we don't want these calls to
# endlessly timeout and retry, so as a hack, just don't let them timeout.
# The next version should replace this and properly timeout and not use
# long calls unless necessary.
NO_TIMEOUT = -1

# A client that uses SOAP messages to communicate with the underlying cloud
# platform (here, AppScale). This client is similar to that used in the AppScale
# Tools, but with non-Neptune SOAP calls removed.
class AppControllerClient
  attr_accessor :conn, :ip, :secret
  
  # A constructor that requires both the IP address of the machine to communicate
  # with as well as the secret (string) needed to perform communication.
  # AppControllers will reject SOAP calls if this secret (basically a password)
  # is not present - it can be found in the user's .appscale directory, and a
  # helper method is usually present to fetch this for us.
  def initialize(ip, secret)
    @ip = ip
    @secret = secret
    
    @conn = SOAP::RPC::Driver.new("https://#{@ip}:17443")
    @conn.add_method("neptune_start_job", "job_data", "secret")
    @conn.add_method("neptune_put_input", "job_data", "secret")
    @conn.add_method("neptune_get_output", "job_data", "secret")
    @conn.add_method("neptune_get_acl", "job_data", "secret")
    @conn.add_method("neptune_set_acl", "job_data", "secret")
    @conn.add_method("neptune_compile_code", "job_data", "secret")
  end

  # A helper method to make SOAP calls for us. This method is mainly here to
  # reduce code duplication: all SOAP calls expect a certain timeout and can
  # tolerate certain exceptions, so we consolidate this code into this method.
  # Here, the caller specifies the timeout for the SOAP call (or NO_TIMEOUT
  # if an infinite timeout is required) as well as whether the call should
  # be retried in the face of exceptions. Exceptions can occur if the machine
  # is not yet running or is too busy to handle the request, so these exceptions
  # are automatically retried regardless of the retry value. Typically
  # callers set this to false to catch 'Connection Refused' exceptions or
  # the like. Finally, the caller must provide a block of
  # code that indicates the SOAP call to make: this is really all that differs
  # between the calling methods. The result of the block is returned to the
  # caller. 
  def make_call(time, retry_on_except)
    begin
      Timeout::timeout(time) {
        yield if block_given?
      }
    rescue Errno::ECONNREFUSED
      if retry_on_except
        retry
      else
        abort("Connection was refused. Is the AppController running?")
      end
    rescue OpenSSL::SSL::SSLError, NotImplementedError, Timeout::Error
      retry
    rescue Exception => except
      if retry_on_except
        retry
      else
        abort("We saw an unexpected error of the type #{except.class} with the following message:\n#{except}.")
      end
    end
  end

  # Initiates the start of a Neptune job, whether it be a HPC job (MPI, X10,
  # or MapReduce), or a scaling job (e.g., for AppScale itself). This method
  # should not be used for retrieving the output of a job or getting / setting
  # output ACLs, but just for starting new HPC / scaling jobs. This method
  # takes a hash containing the parameters of the job to run, and can abort if
  # the AppController it calls returns an error (e.g., if a bad secret is used
  # or the machine isn't running). Otherwise, the return value of this method
  # is the result returned from the AppController.
  def start_neptune_job(job_data)
    result = ""
    make_call(NO_TIMEOUT, false) { 
      result = conn.neptune_start_job(job_data, @secret)
    }  
    abort(result) if result =~ /Error:/
    return result
  end

  # Stores a file stored on the user's local file system in the underlying
  # database. The user can specify to use either the underlying database
  # that AppScale is using, or alternative storage mechanisms (as of writing,
  # Google Storage, Amazon S3, and Eucalyptus Walrus are supported) via the
  # storage parameter.
  def put_input(job_data)
    result = ""
    make_call(NO_TIMEOUT, false) {
      result = conn.neptune_put_input(job_data, @secret)
    }  
    abort(result) if result =~ /Error:/
    return result
  end

  # Retrieves the output of a Neptune job, stored in an underlying
  # database. Within AppScale, a special application runs, referred to as the
  # Repository, which provides a key-value interface to Neptune job data.
  # Data is stored as though it were on a file system, therefore output
  # be of the usual form /folder/filename . Currently the contents of the
  # file is returned as a string to the caller, but as this may be inefficient
  # for non-trivial output jobs, the next version of Neptune will add an
  # additional call to directly copy the output to a file on the local
  # filesystem. See start_neptune_job for conditions by which this method
  # can abort as well as the input format used for job_data.
  def get_output(job_data)
    result = ""
    make_call(NO_TIMEOUT, false) { 
      result = conn.neptune_get_output(job_data, @secret)
    }  
    abort(result) if result =~ /Error:/
    return result
  end

  # Returns the ACL associated with the named piece of data stored
  # in the underlying cloud platform. Right now, data can only be
  # public or private, but future versions will add individual user
  # support. Input, output, and exceptions mirror that of
  # start_neptune_job.
  def get_acl(job_data)
    result = ""
    make_call(NO_TIMEOUT, false) { 
      result = conn.neptune_get_acl(job_data, @secret)
    }  
    abort(result) if result =~ /Error:/
    return result
  end

  # Sets the ACL of a specified pieces of data stored in the underlying
  # cloud platform. As is the case with get_acl, ACLs can be either
  # public or private right now, but this will be expanded upon in
  # the future. As with the other SOAP calls, input, output, and exceptions
  # mirror that of start_neptune_job.
  def set_acl(job_data)
    result = ""
    make_call(NO_TIMEOUT, false) { 
      result = conn.neptune_set_acl(job_data, @secret)
    }  
    abort(result) if result =~ /Error:/
    return result
  end

  def compile_code(job_data)
    result = ""
    make_call(NO_TIMEOUT, false) { 
      result = conn.neptune_compile_code(job_data, @secret)
    }  
    abort(result) if result =~ /Error:/
    return result
  end
end
