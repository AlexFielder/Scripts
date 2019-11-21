#! /usr/bin/python3

# original idea from this threddit: https://www.reddit.com/r/PlaysTV/comments/dz8oe4/psa_plays_is_shutting_down_download_your_videos/f877esw/
# original code from this gist: https://gist.github.com/st0le/b6cb31272e1e03a7e1d479b2686d3e3e#file-playstv_videos_downloader-py
# download all PlaysTv videos of a user
# To find the user id, navigate to the your profile while logged in (IMPORTANT!)
# View source of the page, In the <html> tag there's data-conf attribute. 
# The json in there will have the user id under [login_user.id]
import time
import os
from re import sub
from json import load
from urllib.request import urlretrieve, urlopen

def safe_title(index, title):
    only_chars = sub(r'[^\w]+', '_', title).strip("_")
    return f"{index} - {only_chars}.mp4"[:255]

def get_playstv_videos(user_id):
    last_id = ""
    items = []
    while last_id != None:
        batch = load(urlopen(f"https://plays.tv/playsapi/feedsys/v1/userfeed/{user_id}/uploaded?limit=200&filter=&lastId={last_id}"))
        items.extend(batch["items"])
        last_id = batch["lastId"]
    print(len(items))

    for index,item in enumerate(items, start=1):
        description = item["description"]
        title = safe_title(index,description)
        if "downloadUrl" in item:
            url = item["downloadUrl"]
        else:
            url = item["src"]

        print(title, url)
        try:
            urlretrieve(url, title)
            try:
                created = item["created"] / 1000
                stamp = time.strftime('%m/%d/%Y %H:%M:%S', time.localtime(created))
                os.utime(title,stamp)
                # command = 'SetFile -d \"' + stamp + '\" \"' + title + '\"'
                # os.system(command)
            except Exception as e:
                pass
        except:
            print("Failed to download.")


if __name__ == "__main__":
    get_playstv_videos("b1d3e741b0f3657ffd255b1cb6c53100")