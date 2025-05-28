package make_assets

import "core:os"
import "core:path/filepath"
import "core:fmt"
import "core:strings"
import "core:c/libc"

main :: proc() {

    err : os.Error

    assets_path := filepath.join({os.get_current_directory(), "assets"})
    assets_dir : os.Handle
    assets_dir, err = os.open(assets_path)
    if err != os.ERROR_NONE {
        fmt.panicf("Error {}, assets folder is {}", err, assets_path)
    }

    os.make_directory("bin_assets")

    files : []os.File_Info
    files, err = os.read_dir(assets_dir, 0)
    if err != os.ERROR_NONE {
        fmt.panicf("Error {}, couldn't read files in {}", err, assets_path)
    }

    glsl_files : [dynamic]os.File_Info
    for file in files {
        if strings.contains(file.name, ".glsl") {
            append(&glsl_files, file)
        }
    }

    for glsl_file in glsl_files {
        fmt.printfln("... Compiling {}", glsl_file.name)

        spirv_name, _ := strings.replace(glsl_file.name, ".glsl.", ".spv.", 1)
    
        command := fmt.tprintf("glslc {} -o bin_assets/{}", glsl_file.fullpath, spirv_name)
        exit_code := libc.system(strings.clone_to_cstring(command))
        if exit_code != 0 do fmt.eprintfln("Error caused by: {}", command) 
    }
}