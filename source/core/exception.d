/**
    Exceptions

    Copyright:
        Copyright © 2000-2025, Digital Mars 
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License: Distributed under the
       $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0).
       (See accompanying file LICENSE)

    Authors:
        DLang Contributors
        Luna Nielsen
*/
module core.exception;
public import core.internal.exception;

/**
    Thrown on a range error.
*/
class RangeError : Error {
@safe pure nothrow @nogc:
    this(string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super("Range violation", file, line, next);
    }

    protected this(string msg, string file, size_t line, Throwable next = null) {
        super(msg, file, line, next);
    }
}

/**
    Thrown on an assert error.
*/
class AssertError : Error {
@safe pure nothrow @nogc:
    this(string file, size_t line) {
        this(cast(Throwable) null, file, line);
    }

    this(Throwable next, string file = __FILE__, size_t line = __LINE__) {
        this("Assertion failure", file, line, next);
    }

    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
    }
}

/**
    Thrown on finalize error.
*/
class FinalizeError : Error {
    TypeInfo info;

    this(TypeInfo ci, Throwable next, string file = __FILE__, size_t line = __LINE__) @safe pure nothrow @nogc {
        this(ci, file, line, next);
    }

    this(TypeInfo ci, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow @nogc {
        super("Finalization error", file, line, next);
        info = ci;
    }

    override
    string toString() const @safe {
        return "An exception was thrown while finalizing an instance of " ~ info.toString();
    }
}

/**
 * Thrown on an out of memory error.
 */
class OutOfMemoryError : Error {
    this(string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow @nogc {
        this(true, file, line, next);
    }

    this(bool trace, string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow @nogc {
        super("Memory allocation failed", file, line, next);
        if (!trace)
            this.info = SuppressTraceInfo.instance;
    }

    override string toString() const @trusted {
        return msg.length ? (cast() this).superToString() : "Memory allocation failed";
    }

    // kludge to call non-const super.toString
    private string superToString() @trusted {
        return super.toString();
    }
}

/**
    Thrown on an invalid memory operation.

    An invalid memory operation error occurs in circumstances when the garbage
    collector has detected an operation it cannot reliably handle. The default
    D GC is not re-entrant, so this can happen due to allocations done from
    within finalizers called during a garbage collection cycle.
*/
class InvalidMemoryOperationError : Error {
    this(string file = __FILE__, size_t line = __LINE__, Throwable next = null) @safe pure nothrow @nogc {
        super("Invalid memory operation", file, line, next);
    }

    override string toString() const @trusted {
        return msg.length ? (cast() this).superToString() : "Invalid memory operation";
    }

    // kludge to call non-const super.toString
    private string superToString() @trusted {
        return super.toString();
    }
}

/**
    Thrown on a configuration error.
*/
class ForkError : Error {
@safe pure nothrow @nogc:
    this(string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super("fork() failed", file, line, next);
    }
}

/**
    Thrown on a switch error.
*/
class SwitchError : Error {
@safe pure nothrow @nogc:
    this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
    }
}

/**
    Thrown on a unicode conversion error.
*/
class UnicodeException : Exception {
@safe pure nothrow @nogc:
    size_t idx;

    this(string msg, size_t idx, string file = __FILE__, size_t line = __LINE__, Throwable next = null) {
        super(msg, file, line, next);
        this.idx = idx;
    }
}

// TLS storage shared for all errors, chaining might create circular reference
private align(2 * size_t.sizeof) void[256] _store;
version (LDC) version (Windows) {
    version = LDC_Windows;

    // cannot access TLS globals directly across DLL boundaries, e.g.,
    // when instantiating `staticError` below in another DLL
    pragma(inline, false) // could be safely inlined in the binary containing druntime only
    private ref getStore() {
        return _store;
    }
}

// Suppress traceinfo generation when the GC cannot be used.  Workaround for
// Bugzilla 14993. We should make stack traces @nogc instead.
package class SuppressTraceInfo : Throwable.TraceInfo
{
    override int opApply(scope int delegate(ref const(char[]))) const { return 0; }
    override int opApply(scope int delegate(ref size_t, ref const(char[]))) const { return 0; }
    override string toString() const { return null; }
    static SuppressTraceInfo instance() @trusted @nogc pure nothrow
    {
        static immutable SuppressTraceInfo it = new SuppressTraceInfo;
        return cast(SuppressTraceInfo)it;
    }
}