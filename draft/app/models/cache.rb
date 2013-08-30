class Cache
  def self.location
    dir = "#{Rails.root}/cache"
    Dir.mkdir(dir) unless Dir.exists?(dir)
    dir
  end
end
