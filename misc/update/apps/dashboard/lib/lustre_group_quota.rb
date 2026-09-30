require 'etc'

# Wraps LustreQuota for the caller's Lustre-backed group directories under /data1.
# A group directory exists for each of the caller's supplementary groups named
# "rkp" followed by digits (RIKEN project group naming convention, e.g. rkp00010).
# Users may belong to several projects, so every matching group is returned.
module LustreGroupQuota
  MOUNT_POINT = '/data1'
  # "rkp" immediately followed by digits only.
  GROUP_PATTERN = /\Arkp\d+\z/

  def self.fetch(group_name)
    LustreQuota.fetch(target_dir: group_dir(group_name), mount_point: MOUNT_POINT)
  end

  def self.group_dir(group_name)
    "#{MOUNT_POINT}/#{group_name}"
  end

  # The caller's project group names (rkp + digits), sorted for a stable display
  # order; empty if they belong to none.
  def self.group_names
    Process.groups.map { |gid| safe_group_name(gid) }.compact
           .select { |g| g.match?(GROUP_PATTERN) }.uniq.sort
  end

  def self.safe_group_name(gid)
    Etc.getgrgid(gid).name
  rescue ArgumentError
    nil
  end
  private_class_method :safe_group_name
end
