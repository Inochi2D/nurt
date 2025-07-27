module rt.deh.gnu;
import core.internal.exception : _d_throw_exception;

version(Windows):
extern(C) export:

void _d_throw(Throwable o) {
    _d_throw_exception(o);
}

void __gdc_begin_catch(void* a) {
    
}