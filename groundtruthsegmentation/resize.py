import pathlib,sys
from os import listdir
from PIL import Image

files = listdir()
for i in range(len(files)):
    if ".jpg" in files[i]:
        image = Image.open(files[i])
        w,h = image.size
        image = image.resize((720,370))
        image.save(files[i])
        print('successfully processed',files[i])
