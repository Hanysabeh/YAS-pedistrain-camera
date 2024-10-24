import os
import json
import numpy as np

def getConfigs(self, config_path):
    if os.path.exists(config_path):
        with open(config_path, 'r') as f:
            config = json.load(f)

        # Extracting data from JSON
        logs = config['logging']
        model = config['model']
        labels_path = config['labels']
        out_images = config['out_images']
        out_videos = config['out_videos']
        ratio_xy_array = config['ratio_xy']
        rectArray = config['signals']
        stream = config['stream']
        FPS = config['fps']

        pedestrian_guide_box_array = np.array(
            [[[int(rectArray[0][0] * ratio_xy_array[0]), int(rectArray[0][1] * ratio_xy_array[1])]],
                [[int(rectArray[1][0] * ratio_xy_array[0]), int(rectArray[1][1] * ratio_xy_array[1])]],
                [[int(rectArray[2][0] * ratio_xy_array[0]), int(rectArray[2][1] * ratio_xy_array[1])]],
                [[int(rectArray[3][0] * ratio_xy_array[0]), int(rectArray[3][1] * ratio_xy_array[1])]]], np.int32)
        pedestrian_guide_box_array = pedestrian_guide_box_array.reshape((-1, 1, 2))

    return logs, model, labels_path, out_images, out_videos, ratio_xy_array, stream, FPS, pedestrian_guide_box_array