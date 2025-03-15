/**
    Exceptions

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        Luna Nielsen
*/
module core.internal.exception;
import core.internal.utils;

@nogc nothrow:

private alias dummy__switch_errorT = __switch_errorT!();
void __switch_errorT()(string file, size_t line) @trusted @nogc {
    _d_assert_msg("No appropriate switch clause found!\0", file, cast(uint) line);
}

extern(C) {

    //
    //          OVERRIDABLE
    //
    noreturn onOutOfMemoryError(void* pretend_sideffect = null) @trusted nothrow @nogc /* dmd @@@BUG11461@@@ */ {
        assert(false, "Out of memory!\0");
    }

    noreturn onOutOfMemoryErrorNoGC() @trusted nothrow @nogc {
        assert(false, "Out of memory!\0");
    }

    noreturn onInvalidMemoryOperationError()(void* pretend_sideffect = null) @nogc nothrow pure @trusted {
        assert(0, "Invalid memory operation!\0");
    }

    //
    //          ASSERTS
    //
    void _d_assertp(immutable(char)* file, uint line) {
        nu_fatal(nurt_fmt("Assertation Failure: %s(%llu)", file, line));
    }

    void _d_assert(string file, uint line) @trusted @nogc {
        nu_fatal(nurt_fmt("Assertation Failure: %s(%llu)", file.ptr, line));
    }

    void _d_assert_msg(string msg, string file, uint line) @trusted @nogc {
        nu_fatal(nurt_fmt("Assertation Failure: %s(%llu) %s", file.ptr, line, msg.ptr));
    }

    //
    //          UNIT TESTS
    //

    void _d_unittestp(immutable(char)* file, uint line) {
        nu_fatal(nurt_fmt("Unittest Failure: %s(%llu)", file, line));
    }

    void _d_unittest(string file, uint line) @trusted @nogc {
        nu_fatal(nurt_fmt("Unittest Failure: %s(%llu)", file.ptr, line));
    }

    void _d_unittest_msg(string msg, string file, uint line) @trusted @nogc {
        nu_fatal(nurt_fmt("Unittest Failure: %s(%llu) %s", file.ptr, line, msg.ptr));
    }

    //
    //          ARRAY BOUNDS VIOLATION
    //
    void _d_arrayboundsp(immutable(char)* file, uint line) @trusted @nogc {
        nu_fatal(nurt_fmt("Range violation %s(%llu)", file, line));
    }

    void _d_arraybounds(string file, uint line) @trusted @nogc {
        nu_fatal(nurt_fmt("Range violation %s(%llu)", file.ptr, line));
    }

    //
    //          ARRAY SLICE VIOLATION
    //
    void _d_arraybounds_slicep(immutable(char*) file, uint line, size_t lower, size_t upper, size_t length) {
        const(char)* FMT_STR = 
            lower > upper ? 
                "%s(%llu): slice [%llu .. %llu] has a larger lower index than upper index %llu" :
                "%s(%llu): slice [%llu .. %llu] extends past source array of length %llu";

        nu_fatal(nurt_fmt(FMT_STR, file, line, lower, upper, length));
    }

    void _d_arraybounds_slice(string file, uint line, size_t lower, size_t upper, size_t length) {
        _d_arraybounds_slicep(file.ptr, line, lower, upper, length);
    }

    //
    //          ARRAY INDEX VIOLATION
    //
    void _d_arraybounds_indexp(immutable(char*) file, uint line, size_t index, size_t length) {
            enum FMT_STR = 
                "%s(%llu): index [%llu] is out of bounds for array of length %llu";
        nu_fatal(nurt_fmt(FMT_STR, file, line, index, length));
    }

    void _d_arraybounds_index(string file, uint line, size_t index, size_t length) {
        _d_arraybounds_indexp(file.ptr, line, index, length);
    }

    //
    //          EXCEPTIONS
    //
    extern (C) void _d_throw_exception(Throwable o) {
        nu_fatal(nurt_fmt("%s(%llu) %s: %s", o.file.ptr, o.line, o.classinfo.name.ptr, o.msg.ptr));
    }

    version(GNU) {
        extern(C) void _d_throw(Throwable o) {
            _d_throw_exception(o);
        }

        extern(C) void __gdc_begin_catch(void* a) {
            
        }
    } version(Windows) {
        extern(C) void _d_throwc(Throwable o) {
            _d_throw_exception(o);
        }
    } else {
        extern(C) void _d_throwdwarf(Throwable o) {
            _d_throw_exception(o);
        }
    }
}