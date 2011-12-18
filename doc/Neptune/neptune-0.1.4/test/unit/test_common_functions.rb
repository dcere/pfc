# Programmer: Chris Bunch (cgb@cs.ucsb.edu)

$:.unshift File.join(File.dirname(__FILE__), "..", "..", "lib")
require 'common_functions'

require 'test/unit'

SECRET = "hey-its-a-secret"

module FakeCommonFunctions
  def self.get_from_yaml(a, b, c)
  end

  def self.scp_file(a, b, c, d, e)
  end
end

class FakeFile
  @@exists_checks_done = 0

  def self.expand_path(path)
    return path
  end

  def self.exists?(name)
    if name.include?("OK") or name.include?("BAD-TAG") or name.include?("FAIL")
      return true
    elsif name.include?("retval")
      # The first time around, tell the caller that the file didn't exist so
      # that it sleeps. The next time around, tell it that the file does exist.
      if @@exists_checks_done.zero?
        @@exists_checks_done += 1
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def self.open(name, mode=nil)
    if name.include?("retval")
      return "0\n"
    else
      return "1\n"
    end
  end
end

module FakeFileUtils
  def self.rm_f(name)
    # Do nothing - faking out File means we don't have extra files to clean up
  end
end

module FakeKernel
  def `(command)
    # Do nothing - we don't need the side-effects from exec'ing a command
  end

  #def sleep(time)
    # Do nothing - we don't actually need to sleep the current thread
  #end
end

module FakeYAML
  def self.load_file(filename)
    if filename.include?("OK")
      return { :secret => SECRET, :shadow => SECRET }
    elsif filename.include?("BAD-TAG")
      return {}
    else
      raise ArgumentError
    end
  end
end

class TestCommonFunctions < Test::Unit::TestCase
  def test_scp_to_shadow
    assert_nothing_raised(Exception) {
      CommonFunctions.scp_to_shadow("OK", "OK", "OK", "OK",
        file=FakeFile,
        get_from_yaml=FakeCommonFunctions.method(:get_from_yaml),
        scp_file=FakeCommonFunctions.method(:scp_file))
    }
  end

  def test_get_secret_key
    assert_equal(SECRET, CommonFunctions.get_secret_key("OK", required=true,
      FakeFile, FakeYAML))

    assert_raise(SystemExit) { CommonFunctions.get_secret_key("BAD-TAG",
      required=true, FakeFile, FakeYAML) }

    assert_raise(SystemExit) { CommonFunctions.get_secret_key("FAIL",
      required=true, FakeFile, FakeYAML) }
    assert_nil(CommonFunctions.get_secret_key("FAIL", required=false, FakeFile,
      FakeYAML))

    assert_raise(SystemExit) {
      CommonFunctions.get_secret_key("NOT-EXISTANT", required=true, FakeFile,
        FakeYAML)
    }
  end
end
