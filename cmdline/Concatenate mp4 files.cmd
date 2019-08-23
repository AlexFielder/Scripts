(for %%i in (*.mp4) do @echo file '%%i') > list.txt
ffmpeg -safe 0 -f concat -i list.txt -c copy output.mp4