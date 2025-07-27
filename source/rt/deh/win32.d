module rt.deh.win32;
import core.internal.exception : _d_throw_exception;

version(Windows):
extern(C) export:

void _d_throwc(Throwable o) {
    _d_throw_exception(o);
}

// LDC adds extra error handling symbols we need to include.
version(LDC) {
    export
    extern(C) bool _d_enter_cleanup(void* ptr) => true;
    
    export
    extern(C) void _d_leave_cleanup(void* ptr) { }
}