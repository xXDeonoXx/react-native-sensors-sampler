//  Created by Ofri Ivzori on 24/06/2019.
//  Copyright © 2019 Facebook. All rights reserved.
//
// helpful link:
// http://easynativeextensions.com/camera-tutorial-part-4-connect-to-the-camera-in-objective-c/
//
#import <AVFoundation/AVCaptureSession.h>
#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVCaptureInput.h>
#import <AVFoundation/AVCaptureOutput.h> // For capturing frames
#import <CoreVideo/CVPixelBuffer.h> // for using pixel format types
#import "CameraDelegate.h"

@interface CameraDelegate()
{
@private
    AVCaptureSession *captureSession; // Lets us set up and control the camera
    AVCaptureDevice *camera;
    AVCaptureDeviceInput *cameraInput;
    AVCaptureVideoDataOutput *videoOutput;

    NSTimer *scheduler;
    NSDate *timestamp;
    double lux;
}
@property int interval; // update interval - default 100 millis
@property int period; // sample period - default 10000 millis
@property BOOL useBackCamera; // default NO
@property NSTimer *scheduler;
@end

@implementation CameraDelegate

@synthesize scheduler = _scheduler;

- (id) init
{
    return [self initWithParams:100 period:10000 useBackCamera:NO];
}

- (id) initWithParams:(int) interval
                 period:(int)period
          useBackCamera:(BOOL)useBackCamera
{
    // 1. Initialize the parent class(es) up the hierarchy and create self:
    self = [super init];

    // 2. Initialize members:
    captureSession = NULL;
    camera = NULL;
    cameraInput = NULL;
    videoOutput = NULL;
    lux = 0.0;

    self.interval = interval;
    self.period = period;
    self.useBackCamera = useBackCamera;
    self.scheduler = NULL;

    return self;
}

- (BOOL) startCamera
{
    // 1. Check for camera permission
    if (![self checkCameraPermission])
    {
        return false;
    }
    // 2. Find the back camera
    if (![self findCamera])
    {
        return false;
    }

    // 3. Make sure we have a capture session
    if (captureSession == NULL)
    {
        captureSession = [[AVCaptureSession alloc] init];
    }

    // 4. Choose a preset for the session.
    NSString *cameraResolutionPreset = AVCaptureSessionPreset640x480;

    // 5. Check if the preset is supported on the device by asking the capture session:
    if (![captureSession canSetSessionPreset: cameraResolutionPreset])
    {
        return false;
    }

    // 5.1. The preset is OK, now set up the capture session to use it
    [captureSession setSessionPreset: cameraResolutionPreset];

    // 6. Plug camera and capture sesiossion together
    [self attachCameraToCaptureSession];

    // 7. Add the video output
    [self setupVideoOutput];

    // 8. Set up a callback, so we are notified when the camera actually starts
    [[NSNotificationCenter defaultCenter ] addObserver: self
                                                selector: @selector(videoCameraStarted:)
                                                    name: AVCaptureSessionDidStartRunningNotification
                                                  object: captureSession];
    // 9. Start!!!
    [captureSession startRunning];

    // Note: Returning true from this function only means that setting up went OK.
    // It doesn't mean that the camera has started yet.
    // We get notified about the camera having started in the videoCameraStarted() callback.
    return true;
}

- (void) stopCamera
{
    if (self.scheduler != NULL)
    {
        [self.scheduler invalidate];
        self.scheduler = NULL;
    }

    if (captureSession == NULL)
    {
        // The camera was never started, don't bother stpping it
        return;
    }

    // Make sure we don't pull the rug out of the camera thread's feet.
    // Get hold of a mutex with @synchronized and then stop
    // and tidy up the capture session.
    @synchronized( self )
    {
        if ( [captureSession isRunning])
        {
            [captureSession stopRunning];

            [captureSession removeOutput: videoOutput];

            [captureSession removeInput: cameraInput];

            // Allow the garbage collector to tidy up:
            captureSession = NULL;
            camera = NULL;
            cameraInput = NULL;
            videoOutput = NULL;
        }
    }
}

-(BOOL) checkCameraPermission
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return authStatus == AVAuthorizationStatusAuthorized;
}

- (BOOL) findCamera
{
    // 0. Make sure we initialize our camera pointer:
    camera = NULL;

    // 1. Get a list of available devices:
    // specifying AVMediaTypeVideo will ensure we only get a list of cameras, no microphones
    AVCaptureDevicePosition position = self.useBackCamera
        ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
    camera = [AVCaptureDevice defaultDeviceWithDeviceType: AVCaptureDeviceTypeBuiltInWideAngleCamera
                                                   mediaType:AVMediaTypeVideo
                                                    position:position];

    // 2. Set a frame rate for the camera:
    if (camera != NULL)
    {
        // We firt need to lock the camera, so noone else can mess with its configuration:
        if ([camera lockForConfiguration: NULL])
        {
            // Set a minimum frame rate of 10 frames per second
            [camera setActiveVideoMinFrameDuration: CMTimeMake( 1, 10 )];

            // and a maximum of 20 frames per second
            [camera setActiveVideoMaxFrameDuration: CMTimeMake( 1, 20 )];

            [camera unlockForConfiguration];
        }
    }

    // 4. If we've found the camera we want, return true
    return (camera != NULL);
}

- (BOOL) attachCameraToCaptureSession
{
    // 1. Initialize the camera input
    cameraInput = NULL;

    // 2. Request a camera input from the camera
    NSError * error = NULL;
    cameraInput = [AVCaptureDeviceInput deviceInputWithDevice: camera error: &error];

    // 2.1. Check if we've got any errors
    if (error != NULL)
    {
        return false;
    }

    // 3. We've got the input from the camera, now attach it to the capture session:
    if ([captureSession canAddInput: cameraInput])
    {
        [captureSession addInput: cameraInput];
    }
    else
    {
        return false;
    }

    // 4. Done, the attaching was successful, return true to signal that
    return true;
}

- (void) setupVideoOutput
{
    // 1. Create the video data output
    videoOutput = [[AVCaptureVideoDataOutput alloc ] init];

    // 2. Create a queue for capturing video frames
    dispatch_queue_t sensorsSamplerQueue = dispatch_queue_create( "sensorsSamplerQueue", DISPATCH_QUEUE_SERIAL);

    // 3. Use the AVCaptureVideoDataOutputSampleBufferDelegate capabilities of CameraDelegate:
    [videoOutput setSampleBufferDelegate: self queue: sensorsSamplerQueue];

    // 4. Set up the video output
    // 4.1. Do we care about missing frames?
    videoOutput.alwaysDiscardsLateVideoFrames = NO;

//    // 4.2. We want the frames in some RGB format, which is what ActionScript can deal with
//    NSNumber *framePixelFormat = [NSNumber numberWithInt: kCVPixelFormatType_32BGRA];
//    videoOutput.videoSettings = [NSDictionary dictionaryWithObject: framePixelFormat
//                                                               forKey: (id) kCVPixelBufferPixelFormatTypeKey];

    // 5. Add the video data output to the capture session
    [captureSession addOutput: videoOutput];
}

- (void)captureOutput:(AVCaptureOutput *)output
        didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    // 1. Check if this is the output we are expecting:
    if ( output == videoOutput )
    {
        CFDictionaryRef rawMetadata = CMCopyDictionaryOfAttachments(NULL, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
        CFMutableDictionaryRef metadataRef = CFDictionaryCreateMutableCopy(NULL, 0, rawMetadata);
        NSMutableDictionary *metadata = (NSMutableDictionary *)CFBridgingRelease(metadataRef);
        NSMutableDictionary *exifData = [metadata valueForKey:@"{Exif}"];

        double FNumber = ((NSNumber *)[exifData valueForKey:@"FNumber"]).doubleValue;
        double ExposureTime = ((NSNumber *)[exifData valueForKey:@"ExposureTime"]).doubleValue;
        NSArray *ISOSpeedRatingsArray = (NSArray *)[exifData valueForKey:@"ISOSpeedRatings"];
        double ISOSpeedRatings = ((NSNumber *)ISOSpeedRatingsArray[0]).doubleValue;
        double CalibrationConstant = 50;

        lux = (CalibrationConstant * FNumber * FNumber ) / ( ExposureTime * ISOSpeedRatings );
    }
}

- (void) videoCameraStarted: (NSNotification *)note
{
    // This callback has done its job, now disconnect it
    [[NSNotificationCenter defaultCenter] removeObserver: self
                                                       name: AVCaptureSessionDidStartRunningNotification
                                                     object: captureSession];

    timestamp = [NSDate date];
    // start update timer
    dispatch_async(dispatch_get_main_queue(), ^{
        self.scheduler = [NSTimer
                          scheduledTimerWithTimeInterval: self.interval / 1000.0
                          target:self
                          selector: @selector(handleTimer:)
                          userInfo:nil
                          repeats:YES];
    });
}

- (void) handleTimer:(NSTimer *)timer {
    NSString *updateType = @"update";

    if (timestamp == NULL) {
        timestamp = [NSDate date];
    }

    NSDate *now = [NSDate date];
    if ([now timeIntervalSinceDate:timestamp] > (self.period / 1000.0)) {
        [self stopCamera];
        updateType = @"end";
    }

    [[NSNotificationCenter defaultCenter]
        postNotificationName:@"RCT_sensorUpdateEvent"
        object:self
        userInfo:@{
                @"event": @"SensorsSamplerUpdate_light",
                @"type": updateType,
                @"value": [NSNumber numberWithDouble:lux]
                }];
}


@end
