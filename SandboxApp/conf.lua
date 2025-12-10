function love.conf(config)
    config.identity = "Sandbox"               -- The name of the save directory (string)
    config.appendidentity = false            -- Search files in source directory before save directory (boolean)
    config.version = "11.4"                  -- The LÖVE version this game was made for (string)
    config.console = false                   -- Attach a console (boolean, Windows only)
    config.accelerometerjoystick = false     -- Enable the accelerometer on iOS and Android by exposing it as a Joystick (boolean)
    config.externalstorage = false           -- True to save files (and read from the save directory) in external storage on Android (boolean) 
    config.gammacorrect = false              -- Enable gamma-correct rendering, when supported by the system (boolean)

    config.audio.mic = false                 -- Request and use microphone capabilities in Android (boolean)
    config.audio.mixwithsystem = true        -- Keep background music playing when opening LOVE (boolean, iOS and Android only)

    config.modules.audio = false             -- Enable the audio module (boolean)
    config.modules.data = true               -- Enable the data module (boolean)
    config.modules.event = true              -- Enable the event module (boolean)
    config.modules.font = true               -- Enable the font module (boolean)
    config.modules.graphics = true           -- Enable the graphics module (boolean)
    config.modules.image = true              -- Enable the image module (boolean)
    config.modules.joystick = false          -- Enable the joystick module (boolean)
    config.modules.keyboard = true           -- Enable the keyboard module (boolean)
    config.modules.math = true               -- Enable the math module (boolean)
    config.modules.mouse = true              -- Enable the mouse module (boolean)
    config.modules.physics = false           -- Enable the physics module (boolean)
    config.modules.sound = false             -- Enable the sound module (boolean)
    config.modules.system = true             -- Enable the system module (boolean)
    config.modules.thread = true             -- Enable the thread module (boolean)
    config.modules.timer = true              -- Enable the timer module (boolean), Disabling it will result 0 delta time in love.update
    config.modules.touch = false             -- Enable the touch module (boolean)
    config.modules.video = false             -- Enable the video module (boolean)
    config.modules.window = true             -- Enable the window module (boolean)

	config.window = nil
end