#!/usr/bin/env ruby -w
# encoding: UTF-8

require "win32_filetime/version"
require "ffi"

class Win32Filetime::FileTime < FFI::Struct
  layout :dwLowDateTime, :uint,
         :dwHighDateTime, :uint

  include Comparable

  def initialize(ival = nil)
    super()
    if ival
      ival = ival.to_i if String === ival
      self[:dwLowDateTime] = ival & 0xFFFFFFFF
      self[:dwHighDateTime] = (ival >> 32) & 0xFFFFFFFF
    end
  end

  def <=>(other)
    s1 = self[:dwHighDateTime] << 32 | self[:dwLowDateTime]
    o1 = other[:dwHighDateTime] << 32 | other[:dwLowDateTime]
    if s1 < o1
      -1
    elsif s1 == o1
      0
    else
      1
    end
  end

  def ==(other)
    if other.is_a? self.class
      self[:dwLowDateTime] == other[:dwLowDateTime] && self[:dwHighDateTime] == other[:dwHighDateTime]
    elsif other.is_a? Numeric
      self[:dwHighDateTime] << 32 | self[:dwLowDateTime] == other
    else
      false
    end
  end

  def equal?(other)
    self == other
  end

  def eql?(other)
    self == other
  end

  def to_s
    "0x%08X%08X" % [self[:dwHighDateTime], self[:dwLowDateTime]]
  end

  def to_s2
    Win32Filetime.ft2st(Win32Filetime.ft2lft(self)).to_s
  end

  def minus(year: nil, month: nil, day: nil, hour: nil, minute: nil, second: nil, millisecond: nil)
    st = Win32Filetime.ft2st(self)
    st[:wYear] -= year if year
    st[:wMonth] -= month if month
    st[:wDay] -= day if day
    st[:wHour] -= hour if hour
    st[:wMinute] -= minute if minute
    st[:wSecond] -= second if second
    st[:wMilliseconds] -= millisecond if millisecond
    Win32Filetime.st2ft(st)
  end

  def inspect
    to_s
  end

  def to_i
    ((self[:dwHighDateTime] << 32 | self[:dwLowDateTime]) - 116444736000000000) / 10 ** 7.0
  end

  def to_st
    Win32Filetime.ft2st(self)
  end
end

class Win32Filetime::SystemTime < FFI::Struct
  layout :wYear, :ushort,
         :wMonth, :ushort,
         :wDayOfWeek, :ushort,
         :wDay, :ushort,
         :wHour, :ushort,
         :wMinute, :ushort,
         :wSecond, :ushort,
         :wMilliseconds, :ushort

  def ==(other)
    if other.is_a? self.class
      self[:wYear] == other[:wYear] &&
      self[:wMonth] == other[:wMonth] &&
      self[:wDay] == other[:wDay] &&
      self[:wHour] == other[:wHour] &&
      self[:wMinute] == other[:wMinute] &&
      self[:wSecond] == other[:wSecond] &&
      self[:wMilliseconds] == other[:wMilliseconds]
    elsif other.is_a? String
      self.to_s == other
    else
      false
    end
  end

  def equal?(other)
    self == other
  end

  def eql?(other)
    self == other
  end

  def to_s
    "%04d-%02d-%02d %02d:%02d:%02d.%d" % [
      self[:wYear], self[:wMonth], self[:wDay], self[:wHour], self[:wMinute], self[:wSecond], self[:wMilliseconds],
    ]
  end

  def inspect
    to_s
  end

  def to_ft
    Win32Filetime.st2ft(self)
  end
end

class Win32Filetime::Large_Integer < FFI::Struct
  layout :LowPart, :uint,
         :HighPart, :uint

  def ==(other)
    if other.is_a? self.class
      self[:HighPart] == other[:HighPart] && self[:LowPart] == other[:LowPart]
    elsif other.is_a? Numeric
      self[:HighPart] << 32 | self[:LowPart] == other
    else
      false
    end
  end

  def equal?(other)
    self == other
  end

  def eql?(other)
    self == other
  end

  def to_i
    self[:HighPart] << 32 | self[:LowPart]
  end

  def to_s
    to_i.to_s
  end

  def inspect
    to_i.to_s
  end
end

class Win32Filetime::HANDLE < FFI::Struct
  layout :handle, :uint
end

module Win32Filetime::CFflag
  GENERIC_READ      = 0x80000000
  GENERIC_WRITE     = 0x40000000
  GENERIC_EXECUTE   = 0x20000000
  GENERIC_ALL       = 0x10000000

  FILE_SHARE_READ   = 0x00000001
  FILE_SHARE_WRITE  = 0x00000002
  FILE_SHARE_DELETE = 0x00000004

  CREATE_NEW        = 1
  CREATE_ALWAYS     = 2
  OPEN_EXISTING     = 3
  OPEN_ALWAYS       = 4
  TRUNCATE_EXISTING = 5

  FILE_FLAG_WRITE_THROUGH         =0x80000000
  FILE_FLAG_OVERLAPPED            =0x40000000
  FILE_FLAG_NO_BUFFERING          =0x20000000
  FILE_FLAG_RANDOM_ACCESS         =0x10000000
  FILE_FLAG_SEQUENTIAL_SCAN       =0x08000000
  FILE_FLAG_DELETE_ON_CLOSE       =0x04000000
  FILE_FLAG_BACKUP_SEMANTICS      =0x02000000
  FILE_FLAG_POSIX_SEMANTICS       =0x01000000
  FILE_FLAG_OPEN_REPARSE_POINT    =0x00200000
  FILE_FLAG_OPEN_NO_RECALL        =0x00100000
  FILE_FLAG_FIRST_PIPE_INSTANCE   =0x00080000

  INVALID_HANDLE_VALUE            =0xFFFFFFFF
end

module Win32Filetime::FA
  FILE_ATTRIBUTE_READONLY                 =0x00000001
  FILE_ATTRIBUTE_HIDDEN                   =0x00000002
  FILE_ATTRIBUTE_SYSTEM                   =0x00000004
  FILE_ATTRIBUTE_DIRECTORY                =0x00000010
  FILE_ATTRIBUTE_ARCHIVE                  =0x00000020
  FILE_ATTRIBUTE_DEVICE                   =0x00000040
  FILE_ATTRIBUTE_NORMAL                   =0x00000080
  FILE_ATTRIBUTE_TEMPORARY                =0x00000100
  FILE_ATTRIBUTE_SPARSE_FILE              =0x00000200
  FILE_ATTRIBUTE_REPARSE_POINT            =0x00000400
  FILE_ATTRIBUTE_COMPRESSED               =0x00000800
  FILE_ATTRIBUTE_OFFLINE                  =0x00001000
  FILE_ATTRIBUTE_NOT_CONTENT_INDEXED      =0x00002000
  FILE_ATTRIBUTE_ENCRYPTED                =0x00004000
  FILE_ATTRIBUTE_VIRTUAL                  =0x00010000
end

module Win32Filetime
  extend FFI::Library

  ffi_lib 'msvcrt', 'kernel32'

  ffi_convention :stdcall

  attach_function :GetFileType, [:ulong], :int
  attach_function :GetLastError, [], :uint
  attach_function :FormatMessageA, :FormatMessageA, [:uint, :pointer, :uint, :uint, :string, :uint, :pointer], :int
  attach_function :FormatMessageW, :FormatMessageW, [:uint, :pointer, :uint, :uint, :string, :uint, :pointer], :int

  attach_function :FileTimeToLocalFileTime, [FileTime.by_ref, FileTime.by_ref], :bool
  attach_function :LocalFileTimeToFileTime, [FileTime.by_ref, FileTime.by_ref], :bool

  def self.ft2lft(ft)
    lft = FileTime.new
    FileTimeToLocalFileTime(ft, lft)
    lft
  end

  def self.lft2ft(lft)
    ft = FileTime.new
    LocalFileTimeToFileTime(lft, ft)
    ft
  end

  attach_function :FileTimeToSystemTime, [FileTime.by_ref, SystemTime.by_ref], :bool
  attach_function :SystemTimeToFileTime, [SystemTime.by_ref, FileTime.by_ref], :bool

  def self.ft2st(ft, convft2lft: false)
    ft = ft2lft(ft) if convft2lft
    st = SystemTime.new
    FileTimeToSystemTime(ft, st)
    st
  end

  def self.st2ft(st, convlft2ft: false)
    ft = FileTime.new
    SystemTimeToFileTime(st, ft)
    ft = lft2ft(ft) if convlft2ft
    ft
  end

  def self.str2ft(str, convlft2ft: false)
    str.strip!
    if str =~ /^0[xX]/
      str = str[2..-1]
      h1 = str[0...8].to_i(16)
      l1 = str[8..-1].to_i(16)
      ft = FileTime.new
      ft[:dwHighDateTime] = h1
      ft[:dwLowDateTime] = l1
    elsif str =~ /(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})\.(\d+)/
      st = SystemTime.new
      wYear, wMonth, wDay, wHour, wMinute, wSecond, wMilliseconds = $1, $2, $3, $4, $5, $6, $7
      st[:wYear] = wYear.to_i
      st[:wMonth] = wMonth.to_i
      st[:wDay] = wDay.to_i
      st[:wHour] = wHour.to_i
      st[:wMinute] = wMinute.to_i
      st[:wSecond] = wSecond.to_i
      st[:wMilliseconds] = wMilliseconds.to_i
      ft = Win32Filetime.st2ft(st)
      convlft2ft = true
    end
    ft = lft2ft(ft) if convlft2ft
    ft
  end

  def self.int2ft(ival, convlft2ft: false)
    ft = FileTime.new
    ft[:dwLowDateTime] = ival & 0xFFFFFFFF
    ft[:dwHighDateTime] = (ival >> 32) & 0xFFFFFFFF
    ft = lft2ft(ft) if convlft2ft
    ft
  end

  attach_function :GetSystemTime, [SystemTime.by_ref], :void

  def self.getsystemtime
    st = SystemTime.new
    GetSystemTime(st)
    st
  end

  attach_function :GetLocalTime, [SystemTime.by_ref], :void

  def self.getlocaltime
    lt = SystemTime.new
    GetLocalTime(lt)
    lt
  end

  attach_function :GetFileAttributesA, :GetFileAttributesA, [:string], :uint
  attach_function :GetFileAttributesW, :GetFileAttributesW, [:string], :uint
  attach_function :SetFileAttributesA, :SetFileAttributesA, [:string, :uint], :bool
  attach_function :SetFileAttributesW, :SetFileAttributesW, [:string, :uint], :bool

=begin
CreateFile("", GENERIC_READ,  FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0)
CreateFile("", GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, 0, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, 0)

   LPCSTR  lpFileName,             # "filename"
   DWORD   dwDesiredAccess,        # GENERIC_READ / GENERIC_WRITE / GENERIC_EXECUTE / GENERIC_ALL
   DWORD   dwShareMode,            # FILE_SHARE_READ /| FILE_SHARE_WRITE / FILE_SHARE_DELETE
   LPSECURITY_ATTRIBUTES   lp,     # 0
   DWORD   dwCreationDisposition,  # CREATE_NEW / CREATE_ALWAYS / OPEN_EXISTING / OPEN_ALWAYS / TRUNCATE_EXISTING
   DWORD   dwFlagsAndAttributes,   # 0 | FILE_FLAG_BACKUP_SEMANTICS if dir
   HANDLE  hTemplateFile           # 0

ReadFile(
    HANDLE,
    buf,      # FFI::MemoryPointer.new(:char, 100)
    100,      # max read len
    rded,     # FFI::MemoryPointer.new(:uint,1). # [output] read bytes
    0)

WriteFile(
    HANDLE,
    buf,      # FFI::MemoryPointer.new(:char, 100)
    5,        # write string len
    wded,     # FFI::MemoryPointer.new(:uint,1). # [output] write bytes
    0)

DeleteFile(
    LPCSTR  lpFileName,             # "filename"
    )

FlushFileBuffers(HANDLE)

CloseHandle(HANDLE)
=end

  @@enc_os = Encoding.find('locale')  # TODO, when use CreateFileA then convert to this.
  @@enc_utf16 = Encoding.find("\x00\x01".unpack('S')[0] == 256 ? 'utf-16le' : 'utf-16be') # CreateFileW

  attach_function :CreateFileA, :CreateFileA, [:string, :uint, :uint, :pointer, :uint, :uint, :int], :ulong
  attach_function :CreateFileW, :CreateFileW, [:string, :uint, :uint, :pointer, :uint, :uint, :int], :ulong
  attach_function :ReadFile, [:ulong, :pointer, :uint, :pointer, :pointer], :bool
  attach_function :WriteFile, [:ulong, :pointer, :uint, :pointer, :pointer], :bool
  attach_function :DeleteFileA, :DeleteFileA, [:string], :bool
  attach_function :DeleteFileW, :DeleteFileW, [:string], :bool
  attach_function :FlushFileBuffers, [:ulong], :bool
  attach_function :CloseHandle, [:ulong], :bool

  attach_function :GetFileTime, [:ulong, FileTime.by_ref, FileTime.by_ref, FileTime.by_ref], :bool
  attach_function :SetFileTime, [:ulong, FileTime.by_ref, FileTime.by_ref, FileTime.by_ref], :bool

  def self.getfiletime(fn, getsize: false)
    size = Large_Integer.new if getsize
    tc, ta, tm = FileTime.new, FileTime.new, FileTime.new
    ttts = [tc, ta, tm]
    if fn.encoding != @@enc_utf16
      fn = begin fn.encode @@enc_utf16 rescue return ttts end
    end
    hf = CreateFileW(fn, CFflag::GENERIC_READ, CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
                     nil, CFflag::OPEN_EXISTING, CFflag::FILE_FLAG_BACKUP_SEMANTICS, 0)
    raise "getfiletime: Can not open file \"#{fn}\"" if hf == CFflag::INVALID_HANDLE_VALUE
    res = GetFileTime(hf, tc, ta, tm)
    raise "getfiletime: GetFileTime error." if !res
    if getsize
      res = GetFileSizeEx(hf, size)
      raise "getfiletime: GetFileSizeEx error." if !res
      ttts << size.to_i
    end
    CloseHandle(hf)
    ttts
  end

  # filename
  # tc,ta,tm  FileTime/ 16x String / Integer
  def self.setfiletime(fn, tc, ta, tm)
    if fn.encoding != @@enc_utf16
      fn = begin fn.encode @@enc_utf16 rescue return false end
    end
    fattr = GetFileAttributesW(fn)
    SetFileAttributesW(fn, fattr & ~FA::FILE_ATTRIBUTE_READONLY) if fattr & FA::FILE_ATTRIBUTE_READONLY
    hf = CreateFileW(fn, CFflag::GENERIC_WRITE, CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
                     nil, CFflag::OPEN_EXISTING, CFflag::FILE_FLAG_BACKUP_SEMANTICS, 0)
    raise "setfiletime: Can not open file \"#{fn}\"" if hf == CFflag::INVALID_HANDLE_VALUE
    tc = str2ft(tc) if String === tc
    ta = str2ft(ta) if String === ta
    tm = str2ft(tm) if String === tm
    tc = int2ft(tc) if Integer === tc
    ta = int2ft(ta) if Integer === ta
    tm = int2ft(tm) if Integer === tm
    res = SetFileTime(hf, tc, ta, tm)
    raise "setfiletime: SetFileTime error." if !res
    CloseHandle(hf)
    SetFileAttributesW(fn, fattr) if fattr & FA::FILE_ATTRIBUTE_READONLY
    true
  end

  def self.copyfiletime(fn1, fn2)
    begin
      if fn1.encoding != @@enc_utf16
        fn1 = fn1.encode @@enc_utf16
        fn2 = fn2.encode @@enc_utf16
      end
    rescue
      return false
    end
    tc1, ta1, tm1 = getfiletime(fn1)
    setfiletime(fn2, tc1, ta1, tm1)
  end

  def self.double2ft(tt)
    wintt = (tt * 10 ** 7 + 116444736000000000).to_i
    ft = FileTime.new
    ft[:dwHighDateTime] = wintt >> 32 & 0xFFFFFFFF
    ft[:dwLowDateTime] = wintt & 0xFFFFFFFF
    ft
  end

  def self.ft2double(ft)
    wintt = ft[:dwHighDateTime] << 32 | ft[:dwLowDateTime]
    tt = (wintt - 116444736000000000) / 10 ** 7.0
    tt
  end

  attach_function :GetFileSizeEx, [:ulong, Large_Integer.by_ref], :bool

  def self.getfilesize(fn)
    if fn.encoding != @@enc_utf16
      fn = begin fn.encode @@enc_utf16 rescue return 0 end
    end
    hf = CreateFileW(fn, CFflag::GENERIC_READ, CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
                     nil, CFflag::OPEN_EXISTING, CFflag::FILE_FLAG_BACKUP_SEMANTICS, 0)
    raise "getfilesize: Can not open file \"#{fn}\"" if hf == CFflag::INVALID_HANDLE_VALUE
    size = Large_Integer.new
    res = GetFileSizeEx(hf, size)
    raise "getfilesize: GetFileSizeEx error." if !res
    CloseHandle(hf)
    size.to_i
  end
end

Win32ft = Win32Filetime
