package main

import "core:log"
import "core:math/linalg/glsl"
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
        num_uniform_buffers = 1,
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



    window_size : glsl.ivec2
    assert(sdl.GetWindowSizeInPixels(window, &window_size.x, &window_size.y))
    window_aspect := f32(window_size.x) / f32(window_size.y)

    proj := glsl.mat4Perspective(glsl.radians_f32(70), window_aspect, 0.001, 1000)

    UBO :: struct {
        matMVP : glsl.mat4,
    }

    rotation := f32(0)
    ubo := UBO{}



    FrameState :: struct {
        idx : u64,
        ticks : u64,
        delta_time : f32,
    }

    frame_state := FrameState{
        idx = 0,
        ticks = sdl.GetTicks(),
        delta_time = 0,
    }

    is_running := true
    for is_running {

        {
            current_ticks := sdl.GetTicks()
            frame_state.idx += 1
            frame_state.delta_time = f32(current_ticks - frame_state.ticks) * 0.001
            frame_state.ticks = current_ticks
        }


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
        rotation += (0.25 * glsl.TAU) * frame_state.delta_time
        model := glsl.mat4Translate({0, 0.1, -1}) * glsl.mat4Rotate({0, 1, 0}, rotation)
        ubo.matMVP = proj * model


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

            sdl.PushGPUVertexUniformData(cmd, 0, &ubo, size_of(ubo))
            sdl.DrawGPUPrimitives(render_pass, 3, 1, 0, 0)
        }
        sdl.EndGPURenderPass(render_pass)


        assert(sdl.SubmitGPUCommandBuffer(cmd))
    }

}
