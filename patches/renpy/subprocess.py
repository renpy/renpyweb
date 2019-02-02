Index: renpy/renpy/__init__.py
===================================================================
--- renpy.orig/renpy/__init__.py
+++ renpy/renpy/__init__.py
@@ -532,8 +532,8 @@ def post_import():
     renpy.exports.store = renpy.store
     sys.modules['renpy.store'] = sys.modules['store']
 
-    import subprocess
-    sys.modules['renpy.subprocess'] = subprocess
+    #import subprocess
+    #sys.modules['renpy.subprocess'] = subprocess
 
     for k, v in renpy.defaultstore.__dict__.iteritems():
         renpy.store.__dict__.setdefault(k, v)
Index: renpy/renpy/bootstrap.py
===================================================================
--- renpy.orig/renpy/bootstrap.py
+++ renpy/renpy/bootstrap.py
@@ -22,7 +22,7 @@
 from __future__ import print_function
 import os.path
 import sys
-import subprocess
+#import subprocess
 import io
 
 FSENCODING = sys.getfilesystemencoding() or "utf-8"
@@ -356,4 +356,4 @@ You may be using a system install of pyt
 
         # Prevent subprocess from throwing errors while trying to run it's
         # __del__ method during shutdown.
-        subprocess.Popen.__del__ = popen_del
+        #subprocess.Popen.__del__ = popen_del
Index: renpy/renpy/display/tts.py
===================================================================
--- renpy.orig/renpy/display/tts.py
+++ renpy/renpy/display/tts.py
@@ -24,7 +24,7 @@ from __future__ import print_function
 import sys
 import os
 import renpy.audio
-import subprocess
+#import subprocess
 import pygame
 
 
Index: renpy/renpy/editor.py
===================================================================
--- renpy.orig/renpy/editor.py
+++ renpy/renpy/editor.py
@@ -24,7 +24,7 @@ from __future__ import print_function
 import os
 import renpy
 import traceback
-import subprocess
+#import subprocess
 
 
 class Editor(object):
@@ -100,7 +100,8 @@ class SystemEditor(Editor):
             elif renpy.macintosh:
                 subprocess.call([ "open", filename ])  # @UndefinedVariable
             elif renpy.linux:
-                subprocess.call([ "xdg-open", filename ])  # @UndefinedVariable
+                #subprocess.call([ "xdg-open", filename ])  # @UndefinedVariable
+                pass
         except:
             traceback.print_exc()
 
