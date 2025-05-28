package build

import "core:log"
import "core:path/filepath"
import "core:os"
import "core:sys/windows"


execute_command :: proc(cmd: string) -> (output: string, success: bool) {
    // Set up the security attributes
    sa: windows.SECURITY_ATTRIBUTES
    sa.nLength = size_of(sa)
    sa.bInheritHandle = true
    sa.lpSecurityDescriptor = nil

    // Create pipes for stdout
    hChildStd_OUT_Rd, hChildStd_OUT_Wr: windows.HANDLE
    if !windows.CreatePipe(&hChildStd_OUT_Rd, &hChildStd_OUT_Wr, &sa, 0) {
        log.error("CreatePipe failed")
        return "", false
    }
    defer windows.CloseHandle(hChildStd_OUT_Wr) // We don't need the write end in parent

    // Ensure the read handle is not inherited
    if !windows.SetHandleInformation(hChildStd_OUT_Rd, windows.HANDLE_FLAG_INHERIT, 0) {
        log.error("SetHandleInformation failed")
        return "", false
    }

    // Set up the process startup info
    si: windows.STARTUPINFOW
    si.cb = size_of(si)
    si.hStdError = hChildStd_OUT_Wr
    si.hStdOutput = hChildStd_OUT_Wr
    si.dwFlags |= windows.STARTF_USESTDHANDLES

    // Convert command to UTF-16 for CreateProcessW
    cmd_w := windows.utf8_to_wstring(cmd)

    // Create the process
    pi: windows.PROCESS_INFORMATION
    if !windows.CreateProcessW(
        nil,                   // No module name (use command line)
        cmd_w,                 // Command line
        nil,                   // Process handle not inheritable
        nil,                   // Thread handle not inheritable
        true,                  // Set handle inheritance to TRUE
        windows.CREATE_NO_WINDOW, // Creation flags
        nil,                   // Use parent's environment block
        nil,                   // Use parent's starting directory 
        &si,                   // Pointer to STARTUPINFO structure
        &pi) {                 // Pointer to PROCESS_INFORMATION structure
        log.error("CreateProcess failed")
        return "", false
    }
    defer {
        windows.CloseHandle(pi.hProcess)
        windows.CloseHandle(pi.hThread)
    }

    // Close the write end of the pipe in the parent so we can read
    windows.CloseHandle(hChildStd_OUT_Wr)

    // Read output from the child process
    buffer: [4096]u8
    bytes_read: windows.DWORD
    total_output: [dynamic]u8

    for {
        if !windows.ReadFile(hChildStd_OUT_Rd, &buffer[0], u32(len(buffer)), &bytes_read, nil) || bytes_read == 0 {
            break
        }
        append(&total_output, ..buffer[:bytes_read])
    }

    // Wait for the process to finish
    windows.WaitForSingleObject(pi.hProcess, windows.INFINITE)

    return string(total_output[:]), true
}


main :: proc() {

    odin_root, success := execute_command("odin root")
    if !success do os.exit(1)

    log.debug("odin root: {}", odin_root)

    build_dir := "bin_deb"

    windows.CreateDirectoryW(windows.utf8_to_wstring(build_dir), nil)

    sdl_src := windows.utf8_to_wstring(filepath.join({odin_root, "vendor", "sdl3", "SDL3.dll"}))
    sdl_dst := windows.utf8_to_wstring(filepath.join({build_dir, "SDL3.dll"}))
    windows.CopyFileW(sdl_src, sdl_dst, false)
}