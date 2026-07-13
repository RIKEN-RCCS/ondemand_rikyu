require 'open3'
require 'timeout'

# Wraps `squeue` to list the caller's own Slurm jobs.
module SlurmJobs
  COMMAND_TIMEOUT = 5 # seconds

  class Error < StandardError; end

  Job = Struct.new(:id, :name, :state, :time, keyword_init: true) do
    def running?
      state == 'RUNNING'
    end
  end

  def self.fetch
    stdout, status = run('bash', '-lc', %(squeue -u "$USER" -h -o "%i|%j|%T|%M"))
    raise Error, "squeue exited with #{status.exitstatus}" unless status.success?

    stdout.each_line.filter_map do |line|
      id, name, state, time = line.strip.split('|')
      next if id.nil? || id.empty?
      Job.new(id: id, name: name, state: state, time: time)
    end
  end

  def self.run(*cmd)
    Timeout.timeout(COMMAND_TIMEOUT) { Open3.capture2(*cmd) }
  rescue Timeout::Error
    raise Error, "command timed out: #{cmd.join(' ')}"
  rescue Errno::ENOENT => e
    raise Error, e.message
  end
  private_class_method :run
end
