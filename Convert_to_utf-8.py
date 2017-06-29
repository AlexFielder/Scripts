import os;
import sys;
filePathSrc="C:\\CM"
for root, dirs, files in os.walk(filePathSrc):
    for fn in files:
      if fn[-3:] == '.cm' or fn[-3:] == '.rs':
        notepad.open(root + "\\" + fn)
        console.write(root + "\\" + fn + "\r\n")
        notepad.runMenuCommand("Encoding", "Convert to UTF-8")
        notepad.save()
        notepad.close()