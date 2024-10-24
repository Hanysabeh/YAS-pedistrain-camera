import cProfile
from video_process import VideoProcess

if __name__ == "__main__":
    vp = VideoProcess()
    
    # Start the profiling
    cProfile.run('vp.Thread("your_camera_stream")')

