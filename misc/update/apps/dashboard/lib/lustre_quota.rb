require 'open3'
require 'timeout'

# Wraps `lfs quota` / `lfs project` for a Lustre-backed directory quota check.
module LustreQuota
  COMMAND_TIMEOUT = 5 # seconds

  class Error < StandardError; end

  Result = Struct.new(:used_kb, :limit_kb, :used_files, :limit_files, keyword_init: true) do
    def block_percent
      return nil if limit_kb.to_i.zero?
      (used_kb.to_f / limit_kb * 100).round(1)
    end

    def inode_percent
      return nil if limit_files.to_i.zero?
      (used_files.to_f / limit_files * 100).round(1)
    end

    def used_bytes
      used_kb.to_i * 1024
    end

    def limit_bytes
      limit_kb.to_i * 1024
    end
  end

  def self.fetch(target_dir:, mount_point:)
    project_id = project_id_for(target_dir)
    stdout, status = run('lfs', 'quota', '-q', '-p', project_id,
                          '--blocks', '--block-hardlimit', '--inodes', '--inode-hardlimit',
                          mount_point)
    raise Error, "lfs quota exited with #{status.exitstatus}" unless status.success?

    used_kb, limit_kb, used_files, limit_files = stdout.split.map { |v| Integer(v) rescue nil }
    if [used_kb, limit_kb, used_files, limit_files].any?(&:nil?)
      raise Error, "unexpected lfs quota output: #{stdout.inspect}"
    end

    Result.new(used_kb: used_kb, limit_kb: limit_kb, used_files: used_files, limit_files: limit_files)
  end

  def self.project_id_for(target_dir)
    stdout, status = run('lfs', 'project', '-d', target_dir)
    raise Error, "lfs project exited with #{status.exitstatus}" unless status.success?

    project_id = stdout.split.first
    raise Error, "could not determine project id for #{target_dir}" if project_id.nil?

    project_id
  end
  private_class_method :project_id_for

  def self.run(*cmd)
    Timeout.timeout(COMMAND_TIMEOUT) { Open3.capture2(*cmd) }
  rescue Timeout::Error
    raise Error, "command timed out: #{cmd.join(' ')}"
  rescue Errno::ENOENT => e
    raise Error, e.message
  end
  private_class_method :run
end
