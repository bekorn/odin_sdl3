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

    log.debugf("%v", "Hello from Odin :3")
}
