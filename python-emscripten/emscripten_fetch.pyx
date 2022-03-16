# Python wrapper for emscripten_* C functions - Fetch API

# Copyright (C) 2019  Sylvain Beucler

# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.

# http://docs.cython.org/en/latest/src/tutorial/strings.html#auto-encoding-and-decoding
# Most of our strings are converted from/to JS through emscripten stringToUTF8/UTF8ToString
# cython: c_string_type=unicode, c_string_encoding=utf8
# Note: Py->C auto-UTF-8 (instead of .encode('UTF-8')) not supported for Py2
# Note: causes issues with Typed Memoryviews

# TODO: move to emscripten.fetch but requires emscripten/__init__.py,
# patching emscripten_fetch.c, etc.

from __future__ import print_function

from cpython.mem cimport PyMem_Malloc, PyMem_Free
from cpython.ref cimport PyObject, Py_XINCREF, Py_XDECREF

from cpython.buffer cimport PyBuffer_FillInfo

from libc.string cimport strncpy

from libc.stdint cimport uint32_t, uint64_t

cdef extern from "emscripten/html5.h":
    ctypedef int EM_BOOL
    ctypedef int EMSCRIPTEN_RESULT
    enum: EM_TRUE
    enum: EM_FALSE

cdef extern from "emscripten/fetch.h":
    ctypedef struct emscripten_fetch_attr_t:
        char requestMethod[32]
        void *userData
        void (*onsuccess)(emscripten_fetch_t *fetch)
        void (*onerror)(emscripten_fetch_t *fetch)
        void (*onprogress)(emscripten_fetch_t *fetch)
        void (*onreadystatechange)(emscripten_fetch_t *fetch)
        uint32_t attributes
        unsigned long timeoutMSecs
        EM_BOOL withCredentials
        const char *destinationPath
        const char *userName
        const char *password
        const char * const *requestHeaders
        const char *overriddenMimeType
        const char *requestData
        size_t requestDataSize

    ctypedef struct emscripten_fetch_t:
        unsigned int id
        void *userData
        const char *url
        const char *data
        uint64_t numBytes
        uint64_t dataOffset
        uint64_t totalBytes
        unsigned short readyState
        unsigned short status
        char statusText[64]
        uint32_t __proxyState
        emscripten_fetch_attr_t __attributes

    enum:
        EMSCRIPTEN_FETCH_LOAD_TO_MEMORY
        EMSCRIPTEN_FETCH_STREAM_DATA
        EMSCRIPTEN_FETCH_PERSIST_FILE
        EMSCRIPTEN_FETCH_APPEND
        EMSCRIPTEN_FETCH_REPLACE
        EMSCRIPTEN_FETCH_NO_DOWNLOAD
        EMSCRIPTEN_FETCH_SYNCHRONOUS
        EMSCRIPTEN_FETCH_WAITABLE

    void emscripten_fetch_attr_init(emscripten_fetch_attr_t *fetch_attr)
    emscripten_fetch_t *emscripten_fetch(emscripten_fetch_attr_t *fetch_attr, const char *url)
    #EMSCRIPTEN_RESULT emscripten_fetch_wait(emscripten_fetch_t *fetch, double timeoutMSecs)
    EMSCRIPTEN_RESULT emscripten_fetch_close(emscripten_fetch_t *fetch)
    size_t emscripten_fetch_get_response_headers_length(emscripten_fetch_t *fetch)
    size_t emscripten_fetch_get_response_headers(emscripten_fetch_t *fetch, char *dst, size_t dstSizeBytes)
    char **emscripten_fetch_unpack_response_headers(const char *headersString)
    void emscripten_fetch_free_unpacked_response_headers(char **unpackedHeaders)

LOAD_TO_MEMORY = EMSCRIPTEN_FETCH_LOAD_TO_MEMORY
STREAM_DATA = EMSCRIPTEN_FETCH_STREAM_DATA
PERSIST_FILE = EMSCRIPTEN_FETCH_PERSIST_FILE
APPEND = EMSCRIPTEN_FETCH_APPEND
REPLACE = EMSCRIPTEN_FETCH_REPLACE
NO_DOWNLOAD = EMSCRIPTEN_FETCH_NO_DOWNLOAD
SYNCHRONOUS = EMSCRIPTEN_FETCH_SYNCHRONOUS
WAITABLE = EMSCRIPTEN_FETCH_WAITABLE

# Fetch API
# https://emscripten.org/docs/api_reference/fetch.html

# http://docs.cython.org/en/latest/src/userguide/extension_types.html
cdef class Fetch:
    cdef emscripten_fetch_t *fetch
    cdef callbacks

    def __cinit__(self, url, requestMethod=None, userData=None,
            onsuccess=None, onerror=None, onprogress=None, onreadystatechange=None,
            attributes=None, timeoutMSecs=None, withCredentials=None,
            destinationPath=None, userName=None, password=None,
            requestHeaders=None, overriddenMimeType=None, requestData=None):
    
        # Keep track of temporary Python strings we pass emscripten_fetch() for copy
        py_str_refs = []
    
        cdef emscripten_fetch_attr_t attr
        emscripten_fetch_attr_init(&attr)
    
        Py_XINCREF(<PyObject*>self)  # survive until callback
        attr.userData = <PyObject*>self
    
        if requestMethod is not None:
            strncpy(attr.requestMethod,
                requestMethod.encode('UTF-8'),
                sizeof(attr.requestMethod) - 1)
    
        self.userData = userData
    
        self.callbacks = {}
        attr.onsuccess = callpyfunc_fetch_onsuccess
        attr.onerror = callpyfunc_fetch_onerror
        if onsuccess is not None:
            self.callbacks['onsuccess'] = onsuccess
        if onerror is not None:
            self.callbacks['onerror'] = onerror
        if onprogress is not None:
            self.callbacks['onprogress'] = onprogress
            attr.onprogress = callpyfunc_fetch_onprogress
        if onreadystatechange is not None:
            self.callbacks['onreadystatechange'] = onreadystatechange
            attr.onreadystatechange = callpyfunc_fetch_onreadystatechange
    
        if attributes is not None:
            attr.attributes = attributes
        if timeoutMSecs is not None:
            attr.timeoutMSecs = timeoutMSecs
        if withCredentials is not None:
            attr.withCredentials = withCredentials
        if destinationPath is not None:
            py_str_refs.append(destinationPath.encode('UTF-8'))
            attr.destinationPath = py_str_refs[-1]
        if userName is not None:
            py_str_refs.append(userName.encode('UTF-8'))
            attr.userName = py_str_refs[-1]
        if password is not None:
            py_str_refs.append(password.encode('UTF-8'))
            attr.password = py_str_refs[-1]
    
        cdef char** headers
        if requestHeaders is not None:
            size = (2 * len(requestHeaders) + 1) * sizeof(char*)
            headers = <char**>PyMem_Malloc(size)
            i = 0
            for name,value in requestHeaders.items():
                py_str_refs.append(name.encode('UTF-8'))
                headers[i] = py_str_refs[-1]
                i += 1
                py_str_refs.append(value.encode('UTF-8'))
                headers[i] = py_str_refs[-1]
                i += 1
            headers[i] = NULL
            attr.requestHeaders = <const char* const *>headers
    
        if overriddenMimeType is not None:
            py_str_refs.append(overriddenMimeType.encode('UTF-8'))
            attr.overriddenMimeType = py_str_refs[-1]
    
        if requestData is not None:
            size = len(requestData)
            attr.requestDataSize = size
            # direct pointer, no UTF-8 encoding pass:
            attr.requestData = requestData
    
        # Fetch
        cdef emscripten_fetch_t *fetch = emscripten_fetch(&attr, url.encode('UTF-8'))
        self.fetch = fetch
    
        # Explicitely deref temporary Python strings.  Test for forgotten refs with e.g.:
        # print(attr.overriddenMimeType, attr.destinationPath, attr.userName, attr.password)
        del py_str_refs
    
        if requestHeaders is not None:
            PyMem_Free(<void*>attr.requestHeaders)

    def __dealloc__(self):
        emscripten_fetch_close(self.fetch)

    # Currently unsafe:
    # https://github.com/emscripten-core/emscripten/issues/8234
    #def fetch_close(fetch):
    #    pass

    # http://docs.cython.org/en/latest/src/userguide/buffer.html
    # https://docs.python.org/3/c-api/typeobj.html#c.PyBufferProcs.bf_getbuffer
    # https://docs.python.org/3/c-api/buffer.html#c.PyObject_GetBuffer
    # https://docs.python.org/3/c-api/buffer.html#c.PyBuffer_FillInfo
    def __getbuffer__(self, Py_buffer *view, int flags):
        if self.fetch.data != NULL:
            is_readonly = 1
            PyBuffer_FillInfo(view, self, <void*>self.fetch.data, self.fetch.numBytes, is_readonly, flags)
        else:
            view.obj = None
            raise BufferError
    def __releasebuffer__(self, Py_buffer *view):
        pass

    def __repr__(self):
        return u'<Fetch: id={}, userData={}, url={}, data={}, numBytes={}, dataOffset={}, totalBytes={}, readyState={}, status={}, statusText={}>'.format(repr(self.id), repr(self.userData), repr(self.url), self.data and "<buffer>" or "None", repr(self.numBytes), repr(self.dataOffset), repr(self.totalBytes), repr(self.readyState), repr(self.status), repr(self.statusText))

    # For testing whether a copy occurred:
    #def overwrite(self):
    #    cdef char* overwrite = <char*>(self.fetch.data)
    #    overwrite[0] = b'O'

    def get_response_headers(self):
        cdef char* buf = NULL
        # Note: JS crash if applied on a persisted request from IDB cache
        # https://github.com/emscripten-core/emscripten/issues/7026#issuecomment-545488132
        cdef length = emscripten_fetch_get_response_headers_length(self.fetch)
        if length > 0:
            headersString = <char*>PyMem_Malloc(length)
            emscripten_fetch_get_response_headers(self.fetch, headersString, length+1)
            ret = headersString[:length]  # copy
            PyMem_Free(headersString)
            return ret
        else:
            return None

    def get_unpacked_response_headers(self):
        cdef char* headersString = NULL
        cdef char** unpackedHeaders = NULL
        # Note: JS crash if applied on a persisted request from IDB cache
        cdef length = emscripten_fetch_get_response_headers_length(self.fetch)
        if length > 0:
            headersString = <char*>PyMem_Malloc(length)
            emscripten_fetch_get_response_headers(self.fetch, headersString, length+1)
            unpackedHeaders = emscripten_fetch_unpack_response_headers(headersString)
            PyMem_Free(headersString)
            d = {}
            i = 0
            while unpackedHeaders[i] != NULL:
                k = unpackedHeaders[i]  # c_string_encoding
                i += 1
                v = unpackedHeaders[i]  # c_string_encoding
                i += 1
                d[k] = v
            emscripten_fetch_free_unpacked_response_headers(unpackedHeaders)
            return d
        else:
            return None

    @property
    def id(self):
        return self.fetch.id
    cdef readonly userData
    @property
    def url(self):
        #return self.fetch.url.decode('UTF-8')
        return self.fetch.url  # c_string_encoding
    @property
    def data(self):
        if self.fetch.data != NULL:
            return self
        else:
            return None
    @property
    def numBytes(self):
        return self.fetch.numBytes
    @property
    def dataOffset(self):
        return self.fetch.dataOffset
    @property
    def totalBytes(self):
        return self.fetch.totalBytes  # Content-Length
    @property
    def readyState(self):
        return self.fetch.readyState
    @property
    def status(self):
        return self.fetch.status
    @property
    def statusText(self):
        #return self.fetch.statusText.decode('UTF-8')
        return self.fetch.statusText  # c_string_encoding

cdef void callpyfunc_fetch_callback(emscripten_fetch_t *fetch, char* callback_name):
    cdef Fetch py_fetch = <Fetch>fetch.userData
    # for theoretical concurrency, if we're called during emscripten_fetch()
    py_fetch.fetch = fetch
    # call Python function
    if py_fetch.callbacks.get(callback_name, None):
        py_fetch.callbacks[callback_name](py_fetch)

# one of {onsuccess,onerror} is guaranteed to run, deref Fetch there
cdef void callpyfunc_fetch_onsuccess(emscripten_fetch_t *fetch):
    callpyfunc_fetch_callback(fetch, 'onsuccess')
    Py_XDECREF(<PyObject*>fetch.userData)
cdef void callpyfunc_fetch_onerror(emscripten_fetch_t *fetch):
    callpyfunc_fetch_callback(fetch, 'onerror')
    Py_XDECREF(<PyObject*>fetch.userData)
cdef void callpyfunc_fetch_onprogress(emscripten_fetch_t *fetch):
    callpyfunc_fetch_callback(fetch, 'onprogress')
cdef void callpyfunc_fetch_onreadystatechange(emscripten_fetch_t *fetch):
    callpyfunc_fetch_callback(fetch, 'onreadystatechange')


# import emscripten_fetch,sys; f=lambda x:sys.stdout.write(repr(x)+"\n");
# #Module.cwrap('PyRun_SimpleString', 'number', ['string'])("def g(x):\n    global a; a=x")
# emscripten_fetch.Fetch('/', onsuccess=f)
# emscripten_fetch.Fetch(u'/helloé', onsuccess=f)
# emscripten_fetch.Fetch('/hello', attributes=emscripten_fetch.LOAD_TO_MEMORY, onsuccess=f); del f  # output
# fetch_attr={'onsuccess':f}; emscripten_fetch.Fetch('/hello', **fetch_attr); del fetch_attr['onsuccess']  # output
# emscripten_fetch.Fetch('/non-existent', onerror=lambda x:sys.stdout.write(repr(x)+"\n"))
# emscripten_fetch.Fetch('https://bank.confidential/', onerror=lambda x:sys.stdout.write(repr(x)+"\n"))  # simulated 404
# emscripten_fetch.Fetch('/hello', attributes=emscripten_fetch.LOAD_TO_MEMORY|emscripten_fetch.PERSIST_FILE, onsuccess=f)
# Note: fe.fetch.id changes (in-place) when first caching
# emscripten_fetch.Fetch('/hello', requestMethod='EM_IDB_DELETE', onsuccess=f)
# emscripten_fetch.Fetch('/hello', attributes=emscripten_fetch.LOAD_TO_MEMORY, requestMethod='POST', requestData='AA\xffBB\x00CC', onsuccess=f, onerror=f)
# emscripten_fetch.Fetch('/hello', attributes=emscripten_fetch.LOAD_TO_MEMORY, requestMethod='12345678901234567890123456789012', onerror=f)
# emscripten_fetch.Fetch('/hello', attributes=emscripten_fetch.LOAD_TO_MEMORY, onsuccess=f, userData='userData', overriddenMimeType='text/html', userName='userName', password='password', requestHeaders={'Content-Type':'text/plain','Cache-Control':'no-store'})
# emscripten_fetch.Fetch('/hello', attributes=emscripten_fetch.LOAD_TO_MEMORY|emscripten_fetch.PERSIST_FILE, onsuccess=f, destinationPath='destinationPath'); emscripten_fetch.Fetch('destinationPath', requestMethod='EM_IDB_DELETE', onsuccess=f)
# fe=emscripten_fetch.Fetch('/hello', attributes=emscripten_fetch.LOAD_TO_MEMORY|emscripten_fetch.PERSIST_FILE, onsuccess=f, destinationPath='destinationPath'); fe2=emscripten_fetch.Fetch('destinationPath', requestMethod='EM_IDB_DELETE', onsuccess=f); print("fe=",fe); print("fe2=",fe2)
# Note: fe2 can occur before fe1
# r=emscripten_fetch.Fetch('/hello', attributes=emscripten_fetch.LOAD_TO_MEMORY)
# open('test.txt','wb').write(r); open('test.txt','rb').read()
# r.data != None
# memoryview(r)[:5].tobytes()
# import cStringIO; cStringIO.StringIO(r).read(5)
