# Loads a `KEY=value` file into ENV. The file is authoritative: its values
# override anything already in the environment, so local config stays a single
# source of truth regardless of leftover shell vars.
module EnvFile
  def self.load(path)
    return false unless File.exist?(path)

    File.foreach(path) do |line|
      line = line.strip
      next if line.empty? || line.start_with?("#")

      key, value = line.split("=", 2)
      ENV[key] = value if key && value
    end

    true
  end
end
