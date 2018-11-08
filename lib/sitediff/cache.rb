# frozen_string_literal: true

require 'set'
require 'fileutils'

class SiteDiff
  class Cache
    attr_accessor :read_tags, :write_tags

    def initialize(opts = {})
      @dir = opts[:dir] || '.'
      @create = opts[:create]
      @read_tags = Set.new
      @write_tags = Set.new
    end

    # Is a tag cached?
    def tag?(tag)
      File.directory?(File.join(@dir, "snapshot", tag.to_s))
    end

    def get(tag, path)
      return nil unless @read_tags.include? tag

      filename = File.join(@dir, "snapshot", tag.to_s, *path.split(File::SEPARATOR))
      if path.end_with?("/") || File.directory?(filename)
        filename = File.join(filename, "index.html")
      end
      Marshal.load(File.read(filename))
    end

    def set(tag, path, result)
      return unless @write_tags.include? tag

      filename = File.join(@dir, "snapshot", tag.to_s, *path.split(File::SEPARATOR))
      if path.end_with?("/") || File.directory?(filename)
        filename = File.join(filename, "index.html")
      end
      dirname = File.dirname(filename)
      # May cause problems if action is not atomic!
      # Move existing file to dir/index.html first
      if File.file?(dirname)
        # Not robust! Should generate an UUID or something.
        FileUtils.mv(dirname, dirname + '.temporary')
        FileUtils.makedirs dirname
        FileUtils.mv(dirname + '.temporary', File.join(dirname, 'index.html'))
      end
      if not File.directory?(dirname)
        FileUtils.makedirs File.dirname(filename)
      end
      File.open(filename, 'w') { |file| file.write(Marshal.dump(result)) }
    end

    def key(tag, path)
      # Ensure encoding stays the same!
      Marshal.dump([tag, path.encode('UTF-8')])
    end
  end
end
