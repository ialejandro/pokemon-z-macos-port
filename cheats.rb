# cheats.rb
# Loaded by mkxp-z before the game scripts (see "preloadScript" in mkxp.json).
# Control+Shift+0 switches Pokemon Essentials' debug mode on and off while
# playing. It always starts off: with $DEBUG set during startup the game
# would recompile its data from PBS/.
module Input
  CHEATS_KEY_0 = 39            # SDL scancodes
  CHEATS_CTRL  = [224, 228]    # left and right Control
  CHEATS_SHIFT = [225, 229]    # left and right Shift

  class << self
    alias cheats_update update
    def update
      cheats_update
      keys = raw_key_states
      down = keys[CHEATS_KEY_0] &&
             (keys[CHEATS_CTRL[0]] || keys[CHEATS_CTRL[1]]) &&
             (keys[CHEATS_SHIFT[0]] || keys[CHEATS_SHIFT[1]])
      if down && !@cheats_down
        $DEBUG = !$DEBUG
        # higher-pitched sound = on, lower = off
        Audio.se_play("Audio/SE/expfull", 80, $DEBUG ? 120 : 70) rescue nil
      end
      @cheats_down = down
    end

    # The debug shortcuts in the game scripts (walk through walls, skip
    # battles...) check Input::CTRL. Make them need Control+Shift instead,
    # so Control alone does nothing special.
    alias cheats_press? press?
    def press?(button)
      return cheats_press?(button) unless $DEBUG && button == CTRL
      keys = raw_key_states
      (keys[CHEATS_CTRL[0]] || keys[CHEATS_CTRL[1]]) &&
        (keys[CHEATS_SHIFT[0]] || keys[CHEATS_SHIFT[1]])
    end
  end
end
