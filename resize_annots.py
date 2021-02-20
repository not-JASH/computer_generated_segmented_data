from os import listdir
from os.path import join
from PIL import Image
png_path = r"C:\project_data\interiors_2\png_renders"

dataset = []
renders = listdir(png_path)
for i in range(len(renders)):
    frames = listdir(join(png_path,renders[i]))
    for j in range(len(frames)):
        path2frame = join(png_path,renders[i],frames[j])
        if len(listdir(path2frame))>1:
            dataset.append(path2frame)

for i in range(len(dataset)):
    files = listdir(dataset[i])
    for j in range(len(files)):
        if files[j].endswith('.png'):
            image_path = join(dataset[i],files[j])
            image = Image.open(image_path)
            image = image.resize((1600,900))
            image.save(image_path)
            print('successfully processed',image_path)
