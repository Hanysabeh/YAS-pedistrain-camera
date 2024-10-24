import numpy as np
import cv2
import time
import onnxruntime as ort
import onnx
import os
import threading
from ultralytics import YOLO
import logging
import json 
from get_config import *

def im_resize(im, precentage): 
    scale_percent = precentage * 100  # percent of original size
    width = int(im.shape[1] * scale_percent / 100)
    height = int(im.shape[0] * scale_percent / 100)
    dim = (width, height)
    print("dim : ", dim) # 1280 x 720 
    # resize image
    return cv2.resize(im, dim, interpolation=cv2.INTER_AREA)

class VideoProcess:
    def __init__(self, scale_percent=.5, stream='videos/5.mp4', fps=40) -> None:
        self.FPS = fps
        self.stream = stream
        self.scale_percent = scale_percent  # percent of original size
        self.cfgFile = 0
        self.rectArray = []
        self.ratio_xy_array = []
        self.CONFIDENCE = 0.5
        self.SCORE_THRESHOLD = 0.5
        self.IOU_THRESHOLD = 0.5
        self.frame_cnt = 0
        self.text = ""
        self.logs, self.model, self.labels_path, self.out_images, self.out_videos, self.ratio_xy_array, self.stream, self.FPS, self.pedestrian_guide_box_array = getConfigs(self, config_path='config.json')
        # print("self.pedestrian_guide_box_array : ", self.pedestrian_guide_box_array)
        self.action_logging()
        self.labels = open(self.labels_path).read().strip().split("\n")
        self.colors = np.random.randint(0, 255, size=(len(self.labels), 3), dtype='uint8')
        self.video = 'videos/2.mp4'
        self.frame_size_ratio = 1.0

        self.pedestrian_guide_box_array = np.array(
            [[[int(330 * self.frame_size_ratio), int(690 * self.frame_size_ratio)]],
             [[int(1525 * self.frame_size_ratio), int(590 * self.frame_size_ratio)]],
             [[int(2260 * self.frame_size_ratio), int(795 * self.frame_size_ratio)]],
             [[int(460 * self.frame_size_ratio), int(890 * self.frame_size_ratio)]]],
            np.int32)
        self.pedestrian_guide_box_array = self.pedestrian_guide_box_array.reshape((-1, 1, 2))
        # print("self.pedestrian_guide_box_array : ", self.pedestrian_guide_box_array)

        self.vehicle_entry = False
        self.vehicle_entry_time = 0
        self.pedestrian_entry = False
        self.pedestrian_entry_time = 0
        self.isClosed = True
        self.sess = YOLO(self.model)
        self.video_writer = None
        self.video_filename = None
        self.video_recording = False
        self.danger_frame_counter = 0
        self.DANGER_FRAME_LIMIT = 70  
        self.frame_counter = 0  
        self.danger_detected = False  
        
        os.makedirs(self.out_images, exist_ok=True) 
        os.makedirs(self.out_videos, exist_ok=True)

    def start_video_writer(self, frame_size):
        fourcc = cv2.VideoWriter_fourcc(*'MJPG')
        timestamp = time.strftime("%Y%m%d-%H%M%S")
        self.video_filename = os.path.join(self.out_videos, f"dangerous_{timestamp}.avi")
        os.makedirs(self.out_videos, exist_ok=True)
        self.video_writer = cv2.VideoWriter(self.video_filename, fourcc, 20.0, frame_size)
        if not self.video_writer.isOpened():
            raise Exception(f"Failed to open video writer for file {self.video_filename}")

    def stop_video_writer(self):
        if self.video_writer:
            self.video_writer.release()
            self.video_writer = None

    def action_logging(self):
        logging.basicConfig(filename=self.logs, format='%(asctime)s:%(levelname)s:%(message)s', level=logging.INFO)  #   level=logging.INFO,
        logging.info(self.text)

    def detect(self, im):
        self.image = im
        vehicle_boxes = []
        pedestrian_boxes = []
        h, w = self.image.shape[:2]
        
        # Resize the image to 640x640
        results = self.sess(self.image)
        boxes, confidences, class_ids = [], [], []

        # Loop over each of the detections
        for detection in results:
            for box in detection.boxes:
                if len(box.xyxy) == 1:
                    x1, y1, x2, y2 = box.xyxy[0].tolist()
                    confidence = box.conf
                    class_id = box.cls
                    if confidence > self.CONFIDENCE:
                        boxes.append([int(x1), int(y1), int(x2 - x1), int(y2 - y1)])
                        confidences.append(float(confidence))
                        class_ids.append(int(class_id))
                else:
                    print(f"Unexpected box format: {box.xyxy}")

        # Perform non-maximum suppression
        idxs = cv2.dnn.NMSBoxes(boxes, confidences, self.SCORE_THRESHOLD, self.IOU_THRESHOLD)
        
        # ensure at least one detection exists
        self.pedestrian_entry = False
        self.vehicle_entry = False

        if len(idxs) > 0:
            # loop over all the objects we are keeping
            for i in idxs.flatten():
                # extract the bounding
                center_x = int(boxes[i][0] + (boxes[i][2] / 2))
                center_y = int(boxes[i][1] + boxes[i][3])
                # print("Pedestrian guide box coordinates:", self.pedestrian_guide_box_array)
                # print("Detected center_x, center_y:", center_x, center_y)
                cv2.circle(self.image, (center_x, center_y), 3, (0, 0, 255), 3)
                
                # loop over all the vehicles we are keeping
                if class_ids[i] in (2, 3, 5, 7):
                    vehicle_boxes.append(boxes[i])
                    dist = cv2.pointPolygonTest(self.pedestrian_guide_box_array, (center_x, center_y), True)
                    # print("dist : ", dist)

                    if dist > 0:
                        # print("Vehicles inside class_ids[i]", class_ids[i])
                        if not self.vehicle_entry:
                            self.vehicle_entry_time = time.strftime("%Y%m%d-%H%M%S")
                            self.vehicle_entry = True
                        if self.pedestrian_entry:
                            safety = "[Dangerous]"
                            self.danger_detected = True
                            cv2.imwrite(f"{self.out_images}/dangerous_veh_{self.vehicle_entry_time}.jpg", self.image)
                            logging.info(safety)
                        else:
                            safety = "[Safe]"
                            logging.info(safety)
                    else:
                        safety = "[Safe]"
                        logging.info(safety)

                elif class_ids[i] == 0:
                    pedestrian_boxes.append(boxes[i])
                    dist = cv2.pointPolygonTest(self.pedestrian_guide_box_array, (center_x, center_y), True)
                    # print("dist ", dist)
                    if dist > 0:
                        # print("Person inside class_ids[i]", class_ids[i])
                        if not self.pedestrian_entry:
                            self.pedestrian_entry_time = time.strftime("%Y%m%d-%H%M%S")
                            self.pedestrian_entry = True
                        if self.vehicle_entry:
                            safety = "[Dangerous]"
                            self.danger_detected = True
                            cv2.imwrite(f"{self.out_images}/dangerous_ped_{self.pedestrian_entry_time}.jpg", self.image)
                            logging.info(safety)
                        else:
                            safety = "[Safe]"
                            logging.info(safety)
                    else:
                        safety = "[Safe]"
                        logging.info(safety)
                else:
                    safety = ""
                    logging.info(safety)

        return self.image #, vehicle_boxes, pedestrian_boxes

    ####################################
    def openCVProcess(self, cap):
        self.frame_cnt += 1
        print("frame_cnt : ", self.frame_cnt)
        time.sleep(1 / self.FPS)
        ret, self.image = cap.read()

        if not ret:
            print("Can't receive frame (stream end?). Exiting ...")
            time.sleep(2)
            return False
        else:
            if self.danger_detected:
                self.process_frame(self.image)
            elif not self.danger_detected:
                self.stop_video_writer()

            self.image = im_resize(self.image, 0.5)
            # self.image = cv2.resize(self.image, dsize=(640, 640), interpolation=cv2.INTER_AREA)
            
            # Unpack the returned values from detect
            self.image_out = self.detect(self.image)
            
            # Now you can safely print the image size
            print("Type of self.image_out:", type(self.image_out))
            print("Image size:", self.image_out.shape[1], "x", self.image_out.shape[0])  # Width x Height

            return True

    ############################################################
    def Thread(self, cam):
        cam = self.stream
        cap = cv2.VideoCapture(cam)
        running = True

        while True:
            if not cap.isOpened() or not running:
                print("Cannot open camera")
                # exit()
                cap.release()
                time.sleep(5)
                print(cam)
                cap = cv2.VideoCapture(cam)
                running = self.openCVProcess(cap)
            else:
                running = self.openCVProcess(cap)

    def process_frame(self, frame):
        self.frame_counter += 1
        if self.danger_detected:
            if not self.video_recording:
                self.start_video_writer((frame.shape[1], frame.shape[0]))
                self.video_recording = True

            self.danger_frame_counter += 1
            if self.danger_frame_counter >= self.DANGER_FRAME_LIMIT:
                print("Danger frame limit reached. Stopping detection.")
                self.stop_video_writer()
                self.danger_detected = False
                self.video_recording = False
                return
            if self.video_writer:
                self.video_writer.write(frame)


