require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

namespace :parallel do
  desc 'run `parallel_rspec spec at this directory`'
  task :spec, :count do |_, args|
    cmd = "parallel_rspec spec"
    if n = args[:count]
      cmd << " -n #{n}"
    end
    exit(1) unless system(cmd)
  end
end
