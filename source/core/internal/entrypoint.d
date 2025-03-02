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
        size_t _nurt_strlen(inout(char)* str) @system @nogc pure nothrow;
        
        int _d_run_main(int argc, char **argv, void* mainFunc) {
            import numem.core.hooks : nu_malloc;

            // This is only meant to be used on SuperH with elf,
            // We can be pretty sure that the input string will be
            // at least ascii.

            char[][] args = (cast(char[]*)nu_malloc(argc * (char[]).sizeof))[0..argc];
            size_t totalArgsLength = 0;

            foreach (i, ref arg; args) {
                arg = argv[i][0 .. _nurt_strlen(argv[i])];
                totalArgsLength += arg.length;
            }

            // We will do no cleanup either, if things break then too bad.
            // TODO: maybe add libunwind support?
            return (cast(int function(char[][]))mainFunc)(args);
        }

        int _Dmain(char[][] args);

        // Handle WebAssembly if need be.
        // NOTE: WebASM can't have start arguments.
        version(WebAssembly) {
            extern(C) void _start() { _Dmain(null); }
        } else {
            int main(int argc, char **argv) {
                return _d_run_main(argc, argv, &_Dmain);
            }
        }
    }
}