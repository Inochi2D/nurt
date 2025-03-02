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
extern(C)
size_t _nurt_strlen(inout(char)* str) @system @nogc pure nothrow {
    const(char)* p = str;
    while (*p)
        ++p;
    
    return p - str;
}

const(char)[] nurt_fmt(Args...)(scope const(char)* format, Args args) {
    size_t n = snprintf(null, 0, format, args);

    char* buffer = cast(char*)nu_malloc(n+1);
    n = snprintf(buffer, n+1, format, args);
    return (cast(const(char)*)buffer)[0..n];
}




//
//          C BINDINGS
//

private
pragma(printf)
extern(C) int snprintf(scope char* s, size_t n, scope const(char)* format, ...);