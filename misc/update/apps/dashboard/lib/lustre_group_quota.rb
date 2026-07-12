require 'etc'

# Wraps LustreQuota for the caller's Lustre-backed group directory under /data1.
# The group is the caller's supplementary group whose name starts with "rkp"
# (RIKEN project group naming convention).
module LustreGroupQuota
  MOUNT_POINT = '/data1'
  GROUP_PREFIX = 'rkp'

  class Error < StandardError; end

  def self.fetch
    LustreQuota.fetch(target_dir: "#{MOUNT_POINT}/#{group_name}", mount_point: MOUNT_POINT)
  end

  def self.group_name
    name = Process.groups.map { |gid| safe_group_name(gid) }.compact.find { |g| g.start_with?(GROUP_PREFIX) }
    raise Error, "no group starting with '#{GROUP_PREFIX}' found" if name.nil?

    name
  end

  def self.safe_group_name(gid)
    Etc.getgrgid(gid).name
  rescue ArgumentError
    nil
  end
  private_class_method :safe_group_name
end
