# encoding: UTF-8

#
# Dir::walk , like python os.walk
#

require_relative './cfg'

unless Dir.respond_to?(:walk)
  #
  # @param top [String] dir name
  # @param topdown [bool=true] sub dir first
  # @param onerror [Callback=nil] on error then call, @param err [Exception] @param canRetry [Boolean=false], @return true/false
  # @param followlinks [bool=false]
  # @param block [Callback=nil]  yield 3-tuple (sub_dirpath, [dirnames], [filenames])
  #
  def Dir.walk(top, topdown = true, onerror = nil, followlinks = false, &block)
    return if CFG.checkSkipDir(top)
    dirs = []
    nondirs = []

    begin
      Dir.chdir(top) do
        begin
          # has exception?
          names = Dir.glob('*', File::FNM_DOTMATCH)
        rescue Exception => e2
          if onerror
            e = StandardError.new %(error #{e2.message}, on Dir.glob "#{top}" at "#{Time.now.to_f}")
            e.set_backtrace e2.backtrace
            onerror.call(e)
            return
          end
        end
        names.delete('.')
        names.delete('..') # use shift remove '.' has BUG

        names.sort.each do |name|
          if File.directory?(name)
            dirs << name
          else
            nondirs << name unless CFG.checkSkipFile(name)
          end
        end
      end
    rescue StandardError => e2
      if onerror
        e = StandardError.new %(error #{e2.message}, on Dir.chdir "#{top}" at "#{Time.now.to_f}")
        e.set_backtrace e2.backtrace
        onerror.call(e)
        return
      end
    end

    block.call(top, dirs, nondirs) if topdown

    dirs.each do |name|
      next if CFG.checkSkipDir(name)
      new_path = File.join(top, name)
      next unless followlinks || !File.symlink?(new_path) # may dirs have infinite loop BUG

      begin
        walk(new_path, topdown, onerror, followlinks, &block)
      rescue Exception => e2
        if onerror
          e = StandardError.new %(error #{e2.message}, on walk "#{new_path}" at "#{Time.now.to_f}")
          e.set_backtrace e2.backtrace
          onerror.call(e, true)
        end
      end
    end

    block.call(top, dirs, nondirs) unless topdown
  rescue Exception => e2
    if onerror
      e = StandardError.new %(error #{e2.message}, on Dir.walk "#{top}" at "#{Time.now.to_f}")
      e.set_backtrace e2.backtrace
      onerror.call(e)
    end
  end
end
