import pathlib,sys
from os import listdir
from PIL import Image

files = listdir()
for i in range(len(files)):
    image = Image.open(files[i])
    w,h = image.size
    x1 = 80
    y1 = 80
    x2 = w-80
    y2 = h-80
    image = image.crop([x1,y1,x2,y2])
    image.save(files[i])
    print('successfully processed',files[i])
