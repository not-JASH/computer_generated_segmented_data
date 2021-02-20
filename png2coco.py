from os import listdir,mkdir
from os.path import join,basename
from random import shuffle
from PIL import Image
from pycococreatortools import pycococreatortools
import json
import numpy as np
import datetime


def png2coco(INFO,LICENSES,CATEGORIES,output_filepath,dataset):
    coco_output = {
        "info":INFO,
        "licenses":LICENSES,
        "categories":CATEGORIES,
        "images":[],
        "annotations":[]
        }
    image_id = 1
    segmentation_id = 1
    for i in range(len(dataset)):
        print(i,'/',len(dataset))
        image_files = listdir(dataset[i])
        for j in range(len(image_files)):
            if 'image' in image_files[j]:
                image_filename = join(dataset[i],image_files[j])
                image = Image.open(image_filename)
                image_info = pycococreatortools.create_image_info(
                    i,image_filename,image.size)
                coco_output["images"].append(image_info)
            else:
                annotation_filename = join(dataset[i],image_files[j])
                class_id = [x['id'] for x in CATEGORIES if x['name'] in image_files[j]][0]
                category_info = {'id':class_id,'is_crowd':'crowd' in image_filename}
                binary_mask = np.asarray(Image.open(annotation_filename)
                                         .convert('1')).astype(np.uint8)
                annotation_info = pycococreatortools.create_annotation_info(
                    i,image_id,category_info,binary_mask,
                    image.size,tolerance=2)
                if annotation_info is not None:
                    coco_output["annotations"].append(annotation_info)

    with open(output_filepath,'w') as output_json_file:
        json.dump(coco_output,output_json_file)



png_path = r"C:\project_data\interiors_2\png_renders"
coco_path = r"C:\project_data\interiors_2\coco_annots\40parts"
train_output = 'interiors2_train.json'
validation_output = 'interiors2_validation.json'
INFO = {
    "description":"interiors_dataset",
    "url":coco_path,
    "year":2020,
    "contributor":"jash",
    "date_created": datetime.datetime.utcnow().isoformat(' ')
    }

LICENSES = [
    {
        "id":1,
        "name":"no-lisence",
        "url":"not-applicable"
    }
]

CATEGORIES = [
    {
        'id':1,
        'name':'ceiling',
        'supercategory':'surface',
    },{
        'id':2,
        'name':'floor',
        'supercategory':'surface',
    },{
        'id':3,
        'name':'wall',
        'supercategory':'surface',
    },{
        'id':4,
        'name':'bed',
        'supercategory':'object',
    },{
        'id':5,
        'name':'chair',
        'supercategory':'object',
    },{
        'id':6,
        'name':'couch',
        'supercategory':'object',
    },{
        'id':7,
        'name':'door',
        'supercategory':'object',
    },{
        'id':8,
        'name':'drawer',
        'supercategory':'object',
    },{
        'id':9,
        'name':'table',
        'supercategory':'object',
        },
    ]

dataset = []
renders = listdir(png_path)
for i in range(len(renders)):
    frames = listdir(join(png_path,renders[i]))
    for j in range(len(frames)):
        path2frame = join(png_path,renders[i],frames[j])
        if len(listdir(path2frame))>1:
            dataset.append(path2frame)
shuffle(dataset)
test_train_split = 0.8
limit = round(test_train_split*len(dataset))
train_dataset = dataset[:limit]
validation_dataset = dataset[limit:]

train_part_limit = []
train_part_limit.append(0)
valid_part_limit = []
valid_part_limit.append(0)

no_parts = 40
fraction = 0
for i in range(no_parts):
    fraction = fraction+1/no_parts
    train_part_limit.append(round(fraction*len(train_dataset)))
    valid_part_limit.append(round(fraction*len(validation_dataset)))

for i in range(no_parts):
    part_dir = join(coco_path,('part'+str(i+1)))
    mkdir(part_dir)    
    png2coco(INFO,LICENSES,CATEGORIES,join(part_dir,train_output),train_dataset[train_part_limit[i]:train_part_limit[i+1]])
    png2coco(INFO,LICENSES,CATEGORIES,join(part_dir,validation_output),validation_dataset[valid_part_limit[i]:valid_part_limit[i+1]])











            
