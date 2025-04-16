/**
    Implementation of D main function interop.

    Copyright:
        Copyright © Digital Mars, 2000-2025.
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Walter Bright,
        Sean Kelly, 
        Luna Nielsen
*/
module rt.dmain;
import numem.core.hooks : nu_malloc, nu_free;

private:

alias _d_main_t = extern(C) int function(char[][] args);

export
extern(C)
int _d_run_main(int argc, char **argv, _d_main_t mainFunc) {
    char[][] args;

    // No arguments passed.
    if (argc == 0)
        return mainFunc(args);

    version(Windows) {
        enum CP_UTF8 = 65001;

        // On Windows, args may NOT be UTF8, as such
        // we need to convert it in here.
        const cmdline = GetCommandLineW();
        immutable(size_t) cmdlineLength = _nurt_wstrlen(cmdline);
        int wargc;

        if (auto wargs = CommandLineToArgvW(cmdline, &wargc)) {
            args = (cast(char[]*)nu_malloc(argc * (char[]).sizeof))[0..argc];

            int totalLength = WideCharToMultiByte(CP_UTF8, 0, cmdline, cast(int)cmdlineLength, null, 0, null, null);
            if (totalLength > 0) {
                char* argsBuffer = cast(char*)nu_malloc(totalLength);
                size_t j = 0;
                foreach(i; 0 .. wargc) {
                    immutable(size_t) wlen = _nurt_wstrlen(wargs[i]);
                    immutable(int) len = WideCharToMultiByte(CP_UTF8, 0, &wargs[i][0], cast(int)wlen, null, 0, null, null);
                    
                    args[i] = argsBuffer[j .. j + len];
                    if (len == 0)
                        continue;
                
                    j += len;
                    WideCharToMultiByte(CP_UTF8, 0, &wargs[i][0], cast(int)wlen, &args[i][0], len, null, null); // @suppress(dscanner.unused_result)
                }
            }

            LocalFree(wargs);
        }
    } else {

        args = (cast(char[]*)nu_malloc(argc * (char[]).sizeof))[0..argc];
        size_t totalLength = 0;

        foreach (i, ref arg; args) {
            arg = argv[i][0 .. _nurt_strlen(argv[i])];
            totalLength += arg.length;
        }
    }
        
    return mainFunc(args);
}


//
//          C BINDINGS
//

version(Windows) {
extern(Windows):
    extern wchar* GetCommandLineW();
    extern wchar** CommandLineToArgvW(const(wchar)* arg, int* argc);
    extern void LocalFree(void* ptr) @system @nogc nothrow;
    extern int WideCharToMultiByte(uint, uint, const(wchar)*, int, char*, int, char*, bool*);
    
    extern(C) size_t _nurt_wstrlen(inout(wchar)* str);
} else {
    
    extern(C) 
    size_t _nurt_strlen(inout(char)* str) @system @nogc pure nothrow;
}