/**
    Application entrypoint.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Luna Nielsen
*/
module core.internal.entrypoint;

template _d_cmain() {

    extern(C) {
        int _Dmain(char[][] args);
        version(WASI) {
            import ldc.attributes : llvmAttr;

            @llvmAttr("wasm-import-module", "wasi_snapshot_preview1")
            @llvmAttr("wasm-import-name", "proc_exit")
            extern noreturn __wasi_proc_exit(ubyte);

            // NOTE:    WebAssembly has a custom entrypoint called
            //          _start, additionally webassembly can't have
            //          launch arguments, so we just pass null.
            //          HOWEVER, WASI supports process exit codes via
            //          proc_exit.
            void _start() { 
                int rval = _Dmain(null);

                if (rval != 0)
                    __wasi_proc_exit(cast(ubyte)rval % 127);
            }
        } else version(WebAssembly) {

            // NOTE:    WebAssembly has a custom entrypoint called
            //          _start, additionally webassembly can't have
            //          launch arguments, so we just pass null.
            void _start() { _Dmain(null); }
        } else {
            
            // NOTE:    All other platforms should call into _d_run_main,
            //          if you're adding platform support and your platform
            //          requires a custom entrypoint, add it to this file.
            int _d_run_main(int argc, char **argv, void* mainFunc);
            int main(int argc, char **argv) {
                return _d_run_main(argc, argv, &_Dmain);
            }

            // Solaris requires a function called _main as well.
            version (Solaris) {
                int _main(int argc, char** argv) {
                    return main(argc, argv);
                }
            }
        }
    }
}