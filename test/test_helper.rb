$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "win32_filetime"
include Win32Filetime

require "minitest/autorun"
