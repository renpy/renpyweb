class Condition():
    def __enter__(self): pass

    def __exit__(self, _type, value, traceback): pass

    def notify(self): pass

    def acquire(self): pass

    def release(self): pass

    def notifyAll(self): pass

    def wait(self, duration=None): pass


class RLock(object):
    def __enter__(self): pass

    def __exit__(self, _type, value, traceback): pass


class Event(object):
    def set(self): pass

    def isSet(self): return True

    def clear(self): pass

    def wait(self, timeout=None): return True


class Thread(object):
    def __init__(self, *args, **kwargs): pass

    def start(self): pass

    def join(self): pass

    def setDaemon(self, value): pass
