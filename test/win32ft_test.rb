# encoding: GBK
require 'test_helper'

describe "GetLastError" do
  it "get last erro " do
    # FIXME
    #Win32ft.GetFileType -100
    #Win32ft.GetLastError.should == 6
  end
end

describe "FileTime LocalFileTime" do
  it "test swap filetime localfiletime" do
    ft1 = FileTime.new
    ft1[:dwHighDateTime], ft1[:dwLowDateTime] = 0x1CCF838, 0x1F2B7320
    ft2 = Win32ft.ft2lft(ft1)
    ft3 = Win32ft.lft2ft(ft2)
    
    assert_equal(ft1[:dwHighDateTime], ft3[:dwHighDateTime])
    assert_equal(ft1[:dwLowDateTime], ft3[:dwLowDateTime])
  end
end

describe "FileTime SystemTime" do
  it "test swap filetime systemtime" do
    ft1 = FileTime.new
    ft1[:dwHighDateTime], ft1[:dwLowDateTime] = 0x01CCF838, 0x1F2B7320
    st1 = Win32ft.ft2st(ft1)
    ft3 = Win32ft.st2ft(st1)
    assert_equal(ft1[:dwHighDateTime], ft3[:dwHighDateTime])
    assert_equal(ft1[:dwLowDateTime], ft3[:dwLowDateTime])
  end
end

describe "GetSystemTime" do
  it "getsystemtime is_a? SystemTime" do
    t1 = Win32ft.getsystemtime
    assert_instance_of(SystemTime, t1)
  end
  it "getsystemtime [:wYear] == current year" do
    t1 = Win32ft.getsystemtime
    assert_equal(t1[:wYear], Time.now.year)
  end
end

describe "GetLocalTime" do
  it "getlocaltime is_a? SystemTime" do
    t1 = Win32ft.getlocaltime
    assert_instance_of(SystemTime, t1)
  end
  it "getlocaltime [:wYear] == current year" do
    t1 = Win32ft.getlocaltime
    assert_equal(t1[:wYear], Time.now.year)
  end
end

describe "GetLocalTime GetSystemTime" do
  it "diff localtime systemtime" do
    st1 = Win32ft.getsystemtime
    lt1 = Win32ft.getlocaltime
    t1 = Time.utc st1[:wYear], st1[:wMonth], st1[:wDay], st1[:wHour], 
                  st1[:wMinute], st1[:wSecond]
    t2 = Time.local lt1[:wYear], lt1[:wMonth], lt1[:wDay], lt1[:wHour], 
                  lt1[:wMinute], lt1[:wSecond]
    assert_equal(t1, t2)
  end
end


describe "File Create Read Write Flush Close GetFileSizeEx" do
  before do
    Dir.mkdir "c:\\tmp" unless File.directory?('c:\\tmp')
    Dir.chdir "c:\\tmp"
    @fn1 = "c:\\tmp\\f1.txt"
    @msg = Time.now.to_s + " asfas f;asjf;lasdfj;s af;alsj f"
  end
  
  after do
    Win32ft.DeleteFile(@fn1)
    Dir.chdir "c:\\"
    Dir.rmdir "c:\\tmp"
  end
    
  it "CreateFile WriteFile CloseHandle GetFileSizeEx  ReadFile" do
    fn = "c:\\tmp\\noexist.txt"
    hf = Win32ft.CreateFile(fn, CFflag::GENERIC_READ,
       CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
       nil, CFflag::OPEN_EXISTING, 0, 0)
    assert_equal(hf, CFflag::INVALID_HANDLE_VALUE)
    
    
    hf = Win32ft.CreateFile(@fn1, CFflag::GENERIC_WRITE,
       CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
       nil, CFflag::OPEN_ALWAYS, 0, 0)
    refute_equal(hf, CFflag::INVALID_HANDLE_VALUE)
       
    wded = FFI::MemoryPointer.new(:uint32, 1)
    buffer = FFI::MemoryPointer.new(:char, @msg.bytesize)
    buffer.write_string @msg
    wfres = Win32ft.WriteFile(hf, buffer, @msg.bytesize, wded, nil)
    assert_equal(wfres, true)
    assert_equal(wded.read_uint32, @msg.bytesize)
    
    res = Win32ft.CloseHandle(hf)
    assert(res)


    buffer = FFI::MemoryPointer.new :char, @msg.bytesize*2
    rded = FFI::MemoryPointer.new :uint32, 1
    hf = Win32ft.CreateFile(@fn1, CFflag::GENERIC_READ,
       CFflag::FILE_SHARE_READ | CFflag::FILE_SHARE_WRITE,
       nil, CFflag::OPEN_EXISTING, 0, 0)
    assert(hf != CFflag::INVALID_HANDLE_VALUE)
    rfres = Win32ft.ReadFile(hf, buffer, @msg.bytesize*2, rded, nil)

    assert(rfres)
    assert_equal(rded.read_uint32, @msg.bytesize)
    assert_equal(buffer.read_string, @msg)
    res = Win32ft.CloseHandle(hf)
    assert(res)

    size = Win32ft.getfilesize(@fn1)
    assert_equal(size, @msg.bytesize)
  end
end

describe "GetFileTime SetFileTime" do
  before do
    Dir.mkdir "c:\\tmp" unless File.directory?('c:\\tmp')
    Dir.chdir "c:\\tmp"
    @fn1 = "c:\\tmp\\f1.txt"
    @msg = Time.now.to_s * 2
    File.write(@fn1, @msg)
    sleep 0.1
  end

  after do
    Win32ft.DeleteFile(@fn1)
    Dir.chdir "c:\\"
    Dir.rmdir "c:\\tmp"
  end

  it "getfiletime" do
    tc1, ta1, tm1 = Win32ft.getfiletime(@fn1)
    refute_equal(tc1, FileTime.new)
    refute_equal(ta1, FileTime.new)
    refute_equal(tm1, FileTime.new)
  end
  
  it "setfiletime getfiletime getfilesize" do
    require 'tempfile'
    tc1, ta1, tm1 = Win32ft.getfiletime(@fn1)
    fnt = Tempfile.new 'test'
    fnt.print @msg
    fnt.close

    tc2, ta2, tm2 = Win32ft.getfiletime(fnt.path)
    refute_equal(tc2, tc1)
    refute_equal(ta2, ta1)
    refute_equal(tm2, tm1)
    
    res = Win32ft.setfiletime(fnt.path, tc1, ta1, tm1)
    assert(res)
    tc3, ta3, tm3, sz = Win32ft.getfiletime(fnt.path, getsize: true)
    assert_equal(tc3, tc1)
    assert_equal(ta3, ta1)
    assert_equal(tm3, tm1)
    assert_equal(sz.to_i, @msg.bytesize)
  end
  
  it "ft2double double2ft" do
    tc1, ta1, tm1 = Win32ft.getfiletime(@fn1)
    ftc1 = Win32ft.ft2double(tc1)
    fta1 = Win32ft.ft2double(ta1)
    ftm1 = Win32ft.ft2double(tm1)
    tc2 = Win32ft.double2ft(ftc1)
    ta2 = Win32ft.double2ft(fta1)
    tm2 = Win32ft.double2ft(ftm1)
    assert((tc2[:dwLowDateTime] - tc1[:dwLowDateTime]) <= 10)
    assert((ta2[:dwLowDateTime] - ta1[:dwLowDateTime]) <= 10)
    assert((tm2[:dwLowDateTime] - tm1[:dwLowDateTime]) <= 10)
  end
  
  it "copy file time" do
    f1 = Tempfile.new 't1'
    f1.print '111'
    f1.close
    sleep 0.1
    f2 = Tempfile.new 't2'
    f2.print '222222'
    f2.close
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    refute_equal(tc2, tc1)
    refute_equal(ta2, ta1)
    refute_equal(tm2, tm1)
    refute_equal(sz1, sz2)
    
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    Win32ft.copyfiletime(f1.path, f2.path)
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    assert_equal(tc2, tc1)
    assert_equal(ta2, ta1)
    assert_equal(tm2, tm1)
  end

  it "copy file time on some directory" do
    t=Time.now.to_f.to_s
    f1 = open("a_a1#{t}", 'wb')
    f1.print '111'
    f1.close
    sleep 0.1
    f2 = open("a_a2#{t}", 'wb')
    f2.print '222222'
    f2.close
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    refute_equal(tc2, tc1)
    refute_equal(ta2, ta1)
    refute_equal(tm2, tm1)
    refute_equal(sz1, sz2)
    
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    Win32ft.copyfiletime(f1.path, f2.path)
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    assert_equal(tc2, tc1)
    assert_equal(ta2, ta1)
    assert_equal(tm2, tm1)
    assert_equal(Win32ft.DeleteFile(f1.path), true)
    assert_equal(Win32ft.DeleteFile(f2.path), true)
  end

  it "copy file time on diff directory" do
    t=Time.now.to_f.to_s
    f1 = open("a_a#{t}", 'wb')
    f1.print '111'
    f1.close
    sleep 0.1
    f2 = open("b_a#{t}", 'wb')
    f2.print '222222'
    f2.close
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    refute_equal(tc2, tc1)
    refute_equal(ta2, ta1)
    refute_equal(tm2, tm1)
    refute_equal(sz1, sz2)
    
    tc1, ta1, tm1, sz1 = Win32ft.getfiletime f1.path, getsize: true
    Win32ft.copyfiletime(f1.path, f2.path)
    tc2, ta2, tm2, sz2 = Win32ft.getfiletime f2.path, getsize: true
    assert_equal(tc2, tc1)
    assert_equal(ta2, ta1)
    assert_equal(tm2, tm1)
    assert_equal(Win32ft.DeleteFile(f1.path), true)
    assert_equal(Win32ft.DeleteFile(f2.path), true)
  end

  it "SetFileAttributes" do
    fn = "1.txt"
    File.write(fn, "asdfadsf")
    tc, ta, tm = Win32ft.getfiletime(fn)
    assert_instance_of(FileTime, tc)
    FileUtils.chmod(0000, fn)
    assert_equal(Win32ft.setfiletime(fn, tc, ta, tm), true)
    FileUtils.rm(fn)
  end
end

