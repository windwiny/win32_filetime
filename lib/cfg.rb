# user config class and helper

class BASIC_Cfg
  def initialize
    @SKIP_NTFS_DIRS = Set.new(['SYSTEM VOLUME INFORMATION', '$RECYCLE.BIN'])
    @SKIP_DIRS = Set.new(['NODE_MODULES'])
    @SKIP_FILES = Set.new([])
  end

  def checkSkipDir(name)
    name = File.basename(name).upcase
    @SKIP_NTFS_DIRS.include?(name) || @SKIP_DIRS.include?(name)
  end

  def checkSkipFile(name)
    name = File.basename(name).upcase
    @SKIP_FILES.include?(name)
  end

  def addSkipDirs(*name)
    name.map { |fn| @SKIP_DIRS.add fn.upcase }
  end

  def addSkipFiles(*name)
    name.map { |fn| @SKIP_FILES.add fn.upcase }
  end
end

class BASIC_ConfigStatus
  def to_s
    print_status
  end

  def inspect
    print_status
  end
end

# @param block [Callback]
def create_show_progress_thread(&block)
  return if block.nil?
  warn %{# Show Progress thread Starting..}
  Thread.new do
    while true
      block.call
    end
  end
end

# @param gg [BASIC_ConfigStatus] instance
# @param chk_block [Callback]
def create_cfg_thread(gg, &chk_block)
  _gg = gg
  warn %{# Reconfig thread Startin_gg..}
  Thread.new do
    while true
      ll = STDIN.readline.strip
      na, va = ll.split('=')
      if !na.nil? && !va.nil? && na.start_with?(cfg_) && !va.empty? # skip
        na = '@' + na
        if _gg.instance_variable_defined?('@')
          v = _gg.instance_variable_get(na)
          if String === v
            nv = v
          elsif Numeric === v
            nv = va.to_f
          else
            # TODO skip
          end
          if !nv.nil? && (chk_block.nil? || chk_block.call(na, nv))
            _gg.instance_variable_set(na, va)
            warn %{Set Config #{na} = ori:#{v} to new:#{nv}}
          end
        end
      end
    end
  end
end

CFG = BASIC_Cfg.new
