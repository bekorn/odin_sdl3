package main

import "core:log"
import sdl "vendor:sdl3"

main :: proc () {
    context.logger = log.create_console_logger(opt = log.Options{
        .Level,
        .Terminal_Color,
        .Short_File_Path,
        .Line,
        .Procedure,
    })

    // sdl.callback

    assert(sdl.Init({.VIDEO}))

    window := sdl.CreateWindow("Odin SDL3", 800, 600, {.BORDERLESS})
    assert(window != nil)

    gpu := sdl.CreateGPUDevice({.SPIRV}, debug_mode=true, name=nil)
    assert(gpu != nil)

    assert(sdl.ClaimWindowForGPUDevice(gpu, window))

    
    is_running := true
    for is_running {

        // Handle events
        for e: sdl.Event; sdl.PollEvent(&e); {
            #partial switch e.type {
                case .QUIT:
                    is_running = false
                case .KEY_DOWN:
                    if e.key.scancode == .ESCAPE do is_running = false
            }
        }

        // Update
        

        // Draw

    }

}
