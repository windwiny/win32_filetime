# Win32Filetime

using FFI export win32 filetime api

## Ver

0.0.9 2025 fixup permiss problem

## Installation

Add this line to your application's Gemfile:

    gem 'win32_filetime'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install win32_filetime

## Usage

    require 'win32ft'
    create_time, access_time, modify_time = Win32ft.getfiletime(filename)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
