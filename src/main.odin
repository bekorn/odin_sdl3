package main

import "core:log"
import sdl "vendor:sdl3"

vert_shader_code := #load("../bin_assets/simple.spv.vert")
frag_shader_code := #load("../bin_assets/simple.spv.frag")

main :: proc () {
    context.logger = log.create_console_logger(opt = log.Options{
        .Level,
        .Terminal_Color,
        .Short_File_Path,
        .Line,
        .Procedure,
    })

    sdl.SetLogPriorities(.VERBOSE)

    assert(sdl.Init({.VIDEO}))

    window := sdl.CreateWindow("Odin SDL3", 800, 600, {.VULKAN})
    assert(window != nil)

    device := sdl.CreateGPUDevice({.SPIRV}, debug_mode=true, name=nil)
    assert(device != nil)

    assert(sdl.ClaimWindowForGPUDevice(device, window))

    assert(sdl.SetGPUSwapchainParameters(device, window, .SDR, .VSYNC))

    swapchain_color_target_desc := sdl.GPUColorTargetDescription{
        format = sdl.GetGPUSwapchainTextureFormat(device, window),
    }

    vert_shader := sdl.CreateGPUShader(device, sdl.GPUShaderCreateInfo{
        code = raw_data(vert_shader_code),
        code_size = len(vert_shader_code),
        format = {.SPIRV},
        entrypoint = "main",
        stage = .VERTEX,
    })
    frag_shader := sdl.CreateGPUShader(device, sdl.GPUShaderCreateInfo{
        code = raw_data(frag_shader_code),
        code_size = len(frag_shader_code),
        format = {.SPIRV},
        entrypoint = "main",
        stage = .FRAGMENT,
    })
 
    pipeline := sdl.CreateGPUGraphicsPipeline(device, sdl.GPUGraphicsPipelineCreateInfo{
        primitive_type = .TRIANGLELIST,
        vertex_shader = vert_shader,
        fragment_shader = frag_shader,
        target_info = {
            num_color_targets = 1,
            color_target_descriptions = &swapchain_color_target_desc,
        }
    })

    sdl.ReleaseGPUShader(device, vert_shader)
    sdl.ReleaseGPUShader(device, frag_shader)

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
        cmd := sdl.AcquireGPUCommandBuffer(device)
        assert(cmd != nil)

        swapchain_texture : ^sdl.GPUTexture 
        assert(sdl.WaitAndAcquireGPUSwapchainTexture(cmd, window, &swapchain_texture, nil, nil))

        if swapchain_texture == nil {
            // This happens when the window is minimized for example.
            assert(sdl.SubmitGPUCommandBuffer(cmd))
            continue
        }

        color_target := sdl.GPUColorTargetInfo{
            texture = swapchain_texture,
            clear_color = {0.2, 0.3, 0.6, 1.0},
            load_op = .CLEAR,
            store_op = .STORE,
        }
        render_pass := sdl.BeginGPURenderPass(cmd, &color_target, 1, nil)
        {
            sdl.BindGPUGraphicsPipeline(render_pass, pipeline)

            sdl.DrawGPUPrimitives(render_pass, 3, 1, 0, 0)


        }
        sdl.EndGPURenderPass(render_pass)


        assert(sdl.SubmitGPUCommandBuffer(cmd))
    }

}
