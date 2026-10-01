# macos_compat.rb
# Loaded by mkxp-z before Scripts.rxdata (see "preloadScript" in mkxp.json).
# Lets the unmodified Windows scripts run on macOS by faking the handful of
# Win32API calls whose results the game actually uses. Everything else
# returns 0. Does nothing on Windows. Ruby 1.8 syntax on purpose.

unless RUBY_PLATFORM =~ /mingw|mswin/

ENV["TEMP"] ||= (ENV["TMPDIR"] || "/tmp").sub(/\/+$/, "")

# mkxp-z exposes MiniFFI as Win32API, which would try to dlopen user32 & co.
Object.send(:remove_const, :Win32API) if Object.const_defined?(:Win32API)

class Win32API
  # Size of the game window in window pixels.
  def self.compat_size
    f = $ResizeFactor || 1
    [(Graphics.width * f).to_i, (Graphics.height * f).to_i]
  end

  # Copies +data+ into a caller-supplied buffer, like the real API would.
  def self.compat_fill(buf, data)
    buf[0, data.size] = data if buf.is_a?(String)
  end

  def self.compat_ini(section, key, file)
    current = nil
    File.open(file.tr("\\", "/"), "rb") { |f|
      f.each_line { |line|
        line = line.strip
        if line =~ /^\[(.*)\]$/
          current = $1
        elsif current && current.downcase == section.downcase &&
              line =~ /^([^=]+)=(.*)$/ && $1.strip.downcase == key.downcase
          return $2.strip
        end
      }
    }
    return nil
  rescue SystemCallError
    return nil
  end

  one  = proc { 1 }
  rect = proc { |hwnd, buf|
    w, h = Win32API.compat_size
    Win32API.compat_fill(buf, [0, 0, w, h].pack("l4"))
    1
  }

  CALLS = {
    # Win32API.pbFindRgssWindow raises unless it finds "its" window
    "findwindow"               => one,
    "findwindowex"             => one,
    "getcurrentthreadid"       => one,
    "getwindowthreadprocessid" => one,
    "getforegroundwindow"      => one,
    "screentoclient"           => one,
    "getclientrect"            => rect,
    "getwindowrect"            => rect,
    "getsystemmetrics"         => proc { |i| i < 2 ? Win32API.compat_size[i] : 0 },
    "getcursorpos"             => proc { |buf|
      f = $ResizeFactor || 1
      Win32API.compat_fill(buf, [(Input.mouse_x * f).to_i, (Input.mouse_y * f).to_i].pack("ll"))
      1
    },
    "getprivateprofilestring"  => proc { |section, key, default, buf, size, file|
      val = (Win32API.compat_ini(section, key, file) || default.to_s)[0, size - 1]
      Win32API.compat_fill(buf, val)
      val.size
    },
    "getusername"              => proc { |buf, size|
      Win32API.compat_fill(buf, ENV["USER"].to_s)
      1
    },
    # non-zero = "key not found", so MiniRegistry falls back to its defaults
    "regopenkeyexa"            => proc { 2 }
  }

  def initialize(dll, func, *rest)
    @impl = CALLS[func.to_s.downcase]
  end

  def call(*args)
    @impl ? @impl.call(*args) : 0
  end
  alias Call call
end

# The "Map - Klein" script replaces Graphics.snap_to_bitmap with a GDI
# screen grab. Keep the engine's own implementation whenever that happens.
module Graphics
  class << self
    alias mkxp_snap_to_bitmap snap_to_bitmap
    def singleton_method_added(name)
      return if name != :snap_to_bitmap || @compat_restoring
      @compat_restoring = true
      class << self
        alias snap_to_bitmap mkxp_snap_to_bitmap
      end
      @compat_restoring = false
    end
  end
end

# The VSync option restarts the game with system("Game"). Windows looks in
# the current folder for it, sh does not.
module Kernel
  alias compat_system system
  def system(*args)
    args[0] = "./Game" if args[0] == "Game"
    compat_system(*args)
  end
end

# The engine this game shipped with always delivered typed characters to
# Input.gets. Current mkxp-z only does so while text input is switched on, and
# leaving it on all the time makes macOS pop up its accent picker on held
# keys. So: switch it on while a script is polling Input.gets, off afterwards.
module Input
  class << self
    alias compat_gets gets
    def gets
      self.text_input = true unless @compat_typing
      @compat_typing = 0
      compat_gets
    end

    alias compat_update update
    def update
      compat_update
      return unless @compat_typing
      @compat_typing += 1
      if @compat_typing > 10 # frames without anyone asking for text
        self.text_input = false
        @compat_typing = nil
      end
    end
  end
end

end
