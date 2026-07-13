require 'etc'

# Wraps LustreQuota for the caller's Lustre-backed group directory under /data1.
# The group is the caller's supplementary group named "rkp" followed by digits
# (RIKEN project group naming convention, e.g. rkp00010).
module LustreGroupQuota
  MOUNT_POINT = '/data1'
  # "rkp" immediately followed by digits only.
  GROUP_PATTERN = /\Arkp\d+\z/

  def self.fetch
    LustreQuota.fetch(target_dir: "#{MOUNT_POINT}/#{group_name}", mount_point: MOUNT_POINT)
  end

  # The caller's project group name (rkp + digits), or nil if they belong to none.
  def self.group_name
    Process.groups.map { |gid| safe_group_name(gid) }.compact.find { |g| g.match?(GROUP_PATTERN) }
  end

  def self.safe_group_name(gid)
    Etc.getgrgid(gid).name
  rescue ArgumentError
    nil
  end
  private_class_method :safe_group_name
end
