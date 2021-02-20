import pathlib,sys
from os import listdir
from PIL import Image

files = listdir()
for i in range(len(files)):
    if ".JPEG" in files[i]:
        image = Image.open(files[i])
        w,h = image.size
        image = image.resize((int(0.5*w),int(0.5*h)))
        image.save(files[i])
        print('successfully processed',files[i])
