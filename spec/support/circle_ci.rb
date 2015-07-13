# In CircleCI, when Dir.mktmpdir clear the directory
# after given block is executed, this error is raised:
#
# 1) Mcrain::Mysql.start with db_dir should eq [{"NAME"=>"FOO"}]
#    Failure/Error: Dir.mktmpdir do |dir|
#    Errno::ENOTEMPTY:
#      Directory not empty @ dir_s_rmdir - /tmp/d20150713-12900-1kks3qe
#    # ./spec/mcrain/mysql_spec.rb:17:in `block (4 levels) in <top (required)>'
#
# So, skip clearing the directory on CircleCI

if ENV['CIRCLECI'] =~ /yes|true/i

  require 'tmpdir'
  Dir.instance_eval do

    alias :mktmpdir_original :mktmpdir

    def mktmpdir(*args) # (*args, &block)
      r = mktmpdir_original(*args)
      yield(r) if block_given?
      # clear the directory
      return r
    end
  end

end
