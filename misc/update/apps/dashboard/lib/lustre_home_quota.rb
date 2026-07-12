# Wraps LustreQuota for the current user's /home directory.
module LustreHomeQuota
  MOUNT_POINT = '/home'

  def self.fetch(home_dir = Dir.home)
    LustreQuota.fetch(target_dir: home_dir, mount_point: MOUNT_POINT)
  end
end
