require 'open3'
require 'timeout'

# Wraps `sinfo` to summarize cluster-wide Slurm node availability.
module SlurmStatus
  COMMAND_TIMEOUT = 5 # seconds

  class Error < StandardError; end

  Result = Struct.new(:total, :used, :idle, :unavailable, keyword_init: true) do
    def available
      total.to_i - unavailable.to_i
    end

    def used_percent
      return 0.0 if available.zero?
      (used.to_f / available * 100).round(1)
    end
  end

  USED_STATES = %w[alloc allocated mix mixed comp completing].freeze
  IDLE_STATES = %w[idle].freeze

  def self.fetch
    stdout, status = run('bash', '-lc', %(sinfo -N -h -o "%t"))
    raise Error, "sinfo exited with #{status.exitstatus}" unless status.success?

    states = stdout.each_line.map { |line| line.strip.downcase.gsub(/[^a-z]/, '') }.reject(&:empty?)
    total = states.size
    used = states.count { |s| USED_STATES.include?(s) }
    idle = states.count { |s| IDLE_STATES.include?(s) }
    unavailable = total - used - idle

    Result.new(total: total, used: used, idle: idle, unavailable: unavailable)
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
