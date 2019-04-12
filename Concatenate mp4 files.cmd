(for %i in (*.mp4) do @echo file '%i') > mylist.txt
ffmpeg -safe 0 -f concat -i list.txt -c copy output.mp4