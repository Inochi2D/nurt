/**
    Internal utilities.

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Luna Nielsen
*/
module core.internal.utils;

package(core.internal):
@nogc nothrow:

//
//          IMPORTS
//
public import numem.core.hooks;


//
//          HELPERS
//
export
extern(C)
size_t _nurt_strlen(inout(char)* str) @system @nogc pure nothrow {
    const(char)* p = str;
    while (*p)
        ++p;
    
    return p - str;
}

export
extern(C)
size_t _nurt_wstrlen(inout(wchar)* str) @system @nogc pure nothrow {
    const(wchar)* p = str;
    while (*p)
        ++p;
    
    return p - str;
}

export
extern(C)
int _nurt_memcmp(scope const(void)* arg1, scope const(void)* arg2, size_t num) {
    foreach(i; 0..num) {
        ubyte a = (cast(ubyte*)arg1)[i];
        ubyte b = (cast(ubyte*)arg2)[i];

        if (a == b)
            continue;

        return a < b ? -1 : 1;
    }
    return 0;
}

export
const(char)[] nurt_fmt(Args...)(scope const(char)* format, Args args) pure {
    version(WebAssembly) {
        
        // TODO: Implement?
        return null;
    } else {
        size_t n = snprintf(null, 0, format, args);

        char* buffer = cast(char*)nu_malloc(n+1);
        n = snprintf(buffer, n+1, format, args);
        return (cast(const(char)*)buffer)[0..n];
    }
}




//
//          C BINDINGS
//

version(CRuntime_Microsoft) {
    
    private
    pragma(printf)
    pragma(mangle, "_snprintf")
    extern(C) int snprintf(scope char* s, size_t n, scope const(char)* format, ...) pure;
} else {

    private
    pragma(printf)
    extern(C) int snprintf(scope char* s, size_t n, scope const(char)* format, ...) pure;
}