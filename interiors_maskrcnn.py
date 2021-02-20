'''
this is a modified version of Veemon's code
https://github.com/matterport/Mask_RCNN/blob/master/samples/coco/coco.py
'''

import os,sys,time,imgaug,shutil
import numpy as np
from os.path import join
from pycocotools.coco import COCO
from pycocotools.cocoeval import COCOeval
from pycocotools import mask as maskUtils
from mrcnn.config import Config
from mrcnn import model as modellib, utils

os.environ["CUDA_VISIBLE_DEVICES"] = "0,1"

'''
paths to logs,checkpoints and pretrained weights
SAVE_PATH = r""
MODEL_PATH = join(SAVE_PATH,"interiors_mrcnn.h5")
LOGS_PATH = join(SAVE_PATH,"logs")
'''


annotations_dir = r"C:\project_data\interiors_2\coco_annots"
training_logs = r"C:\project_data\interiors_2\train_logs"

class CocoConfig(Config):
    NAME = "Jash's coco config"
    IMAGES_PER_GPU = 4
    GPU_COUNT = 2
    NUM_CLASSES = 1 + 9

class CocoDataset(utils.Dataset):
    def load_coco(self,dataset_dir,subset,class_ids = None,
                  class_map=None,return_coco=False):
        datasets = os.listdir(dataset_dir)
        coco = []
        for i in range(len(datasets)):
            if subset in datasets[i]:
                coco = COCO(join(annotations_dir,datasets[i]))

        if not class_ids:
            class_ids = sorted(coco.getCatIds())

        if class_ids:
            image_ids = []
            for id in class_ids:
                image_ids.extend(list(coco.getImgIds(catIds=[id])))
                image_ids = list(set(image_ids))
        else:
            image_ids = list(coco.imgs.keys())
        
        
        for i in class_ids:
            self.add_class("coco",i,coco.loadCats(i)[0]["name"])

        for i in image_ids:
            self.add_image(
                "coco",image_id=i,
                path = coco.imgs[i]['file_name'],
            width = coco.imgs[i]["width"],
            height = coco.imgs[i]["height"],
            annotations = coco.loadAnns(coco.getAnnIds(
                imgIds=[i],catIds=class_ids,iscrowd=None)))
        if return_coco:
            return coco

def buld_coco_results(dataset,image_ids,rois,class_ids,scores,masks):
    if rois is None:
        return []

    results = []
    for image_id in image_ids:
        for i in range(rois.shape[0]):
            class_id = chass_ids[i]
            score = scores[i]
            bbox = np.around(rois[i],1)
            mask = masks[:,:,i]

            result = {
                "image_id":image_id,
                "category_id":dataset.get_source_class_id(class_id,"coco"),
                "bbox":[bbox[1],bbox[0],bbox[3]-bbox[1],bbox[2]-bbox[0]],
                "score":score,
                "segmentation":maskUtils.encode(np.asfortranarray(mask))
            }
            results.append(result)
    return results

def evaluate_coco(model,dataset,coco,eval_type="segm",limit=0,image_ids=None):
    
    image_ids = image_ids or dataset.image_ids
    if limit:
        image_ids = image_ids[:limit]
        
    coco_image_ids = [dataset.image_info[id]["id"] for id in image_ids]
    t_prediction = 0
    t_start = time.time()
    results = []
    
    for i,image_id in enumerate(image_ids):
        image = dataset.load_image(image_id)
        t = time.time()
        r = model.detect([image],verbose=0)[0]
        t_prediction += (time.time()-t)
        image_results = build_coco_results(dataset,coco_image_ids[i:i+1],
                                           r["rois"],r["class_ids"],
                                           r["scores"],
                                           r["masks"].astype(np.uint8))
        results.extend(image_results)
        
    coco_results = coco.loadRes(results)
    cocoEval = COCOeval(coco,coco_results,eval_type)
    cocoEval.params.imgIds = coco_image_ids
    cocoEval.evaluate()
    cocoEval.accumulate()
    cocoEval.summarize()

    print("Prediction time: {}. Average {}/image"/format(
        t_prediction,t_prediction/len(image_ids)))
    print("Total time: ", time.time() - t_start)

if __name__ == '__main__':
    import argparse

    parser = argparse.ArgumentParser(
        description = 'Interiors Mask R-CNN')
    parser.add_argument("command",
                        metavar="<command>",
                        help="'train' or 'evaluate' on COCO")
    parser.add_argument('--dataset',required=False,
                        default = annotations_dir,
                        metavar="/path/to/coco",
                        help='directory of coco_format dataset')
    parser.add_argument('--model',required=False,
                        metavar = 'path/to/weights.h5',
                        default = None,
                        help="Path to weights file or 'coco'")
    parser.add_argument('--logs',required=False,
                        default = training_logs,
                        metavar = "/path/to/logs/",
                        help = 'Logs and checkpoints directory(default=logs/)')
    parser.add_argument('--limit',required=False,
                        default = 500,
                        metavar="<image count>",
                        help='Images for evaluation (default = 500)')
    args = parser.parse_args()
    print("command: ",args.command)
    print("model: ",args.model)
    print("dataset: ",args.dataset)
    print("logs: ",args.logs)
    print("limit: ",args.limit)

    if "train" in args.command:
        config = CocoConfig()
    elif "eval" in args.command: 
        class InferenceConfig(CocoConfig):
            GPU_COUNT = 1
            IMAGES_PER_GPU = 1
            DETECTION_MIN_CONFIDENCE = 0
        config = InferenceConfig()
    config.display

    if "train" in args.command:
        model = modellib.MaskRCNN(mode="training",config=config,
                                  model_dir = args.logs)
    elif "eval" in args.command:
        model = modellib.MaskRCNN(mode="inference",config=config,
                                  model_dir = args.logs)

    if args.model is not None:
        if args.model.lower() =="coco":
            model_path = COCO_MODEL_PATH
        elif args.model.lower() == "last":
            model_path = model.find_last()
        elif args.model.lower() == "imagenet":
            model_path = model.get_imagenet_weights()
        else:
            model_path = args.model

        print("loading weights ",model_path)
        model.load_weights(model_path,by_name=True)

    if "train" in args.command:
        dataset_train = CocoDataset()
        dataset_train.load_coco(args.dataset,"train")
        dataset_train.prepare()

        dataset_val = CocoDataset()
        dataset_val.load_coco(args.dataset,"val")
        dataset_val.prepare()

        augmentation = imgaug.augmenters.Fliplr(0.5)

        #training schedule v1: pulled from the original script

        #stage 1
        print("\n\nTraining network heads\n\n")
        model.train(dataset_train,dataset_val,
                    learning_rate = config.LEARNING_RATE,
                    epochs = 40,
                    layers = 'heads',
                    augmentation = augmentation)
        #stage 2
        print("\n\nFine tune resnet stage 4 and up\n\n")
        model.train(dataset_train,dataset_val,
                    learning_rate = config.LEARNING_RATE,
                    epochs = 120,
                    layers = '4+',
                    augmentation = augmentation)

        #stage 3
        print("\n\nFine tune all layers\n\n")
        model.train(dataset_train,dataset_val,
                    learning_rate=config.LEARNING_RATE/10,
                    epochs = 160,
                    layers = 'all',
                    augmentation = augmentation)
    elif "eval" in args.command:
        dataset_val = CocoDataset()
        coco = dataset_val.load_coco(args.dataset,"val",return_coco=True)
        dataset_val.prepare()
        print("running COCO evaluation on {} images".format(args.limit))
    else:
        print("'{}' is not recognized"
              "use 'train' or 'evaluate'".format(args.command))
        






























































































