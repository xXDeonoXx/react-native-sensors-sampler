#import "AudioMonitor.h"
#import <AVFoundation/AVFoundation.h>

@interface AudioMonitor()
{
@private
    AVAudioRecorder *recorder;
    NSTimer *scheduler;
    NSDate *timestamp;
}
@property int interval;
@property int period;
@end

@implementation AudioMonitor

- ( id ) init
{
    // 1. Initialize the parent class(es) up the hierarchy and create self:
    return [self initWithParams:100 period:10000];
}

- ( id ) initWithParams:(int)interval period:(int)period
{
    self = [ super init ];
    
    scheduler = NULL;
    
    self.interval = interval;
    self.period = period;
    return self;
}

- (BOOL) startSampling
{
    if (![self checkMicrophonePermission]) {
        return false;
    }
    NSError *errorSession = NULL;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory:AVAudioSessionCategoryRecord
                    error: &errorSession];
    if (!success && errorSession) {
        return false;
    }
    
    // record audio to /dev/null
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
    // some settings
    NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithFloat: 44100.0], AVSampleRateKey,
                              [NSNumber numberWithInt: kAudioFormatAppleLossless], AVFormatIDKey,
                              [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                              [NSNumber numberWithInt: AVAudioQualityMax], AVEncoderAudioQualityKey,
                              NULL];
    
    // create a AVAudioRecorder
    NSError *errorRecord = NULL;
    recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error: &errorRecord];
    [recorder setMeteringEnabled:YES];
    
    if ( NULL != recorder) {
        [recorder prepareToRecord];
        recorder.meteringEnabled = YES;
        [recorder record];
        
        timestamp = [NSDate date];
        // start update timer
        dispatch_async(dispatch_get_main_queue(), ^{
            float recordInterval = self.interval / 1000.0f;
            scheduler = [NSTimer
                         scheduledTimerWithTimeInterval:recordInterval
                         target:self
                         selector: @selector(handleTimer:)
                         userInfo: nil
                         repeats: YES];
        });
        
        [recorder updateMeters];
        return true;
    }
    return false;
}

- (void) stopSampling
{
    [recorder stop];
    if (scheduler != NULL) {
        [scheduler invalidate];
        scheduler = NULL;
    }
}

- (BOOL) checkMicrophonePermission
{
    AVAudioSessionRecordPermission permission = [[AVAudioSession sharedInstance]
                                                 recordPermission];
    return permission == AVAudioSessionRecordPermissionGranted;
}

- (void)handleTimer:(NSTimer *)timer
{
    [recorder updateMeters];
    
    // here is the DB!
    float averagePower = [recorder averagePowerForChannel: 1];
    // offset to SPL DB
    float spl = averagePower + [self getOffset:averagePower];
    
    NSString *updateType = @"update";
    
    if (timestamp == NULL) {
        timestamp = [NSDate date];
    }
    
    NSDate *now = [NSDate date];
    if ([now timeIntervalSinceDate:timestamp] > (self.period / 1000.0)) {
        [self stopSampling];
        updateType = @"end";
    }
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"RCT_sensorUpdateEvent"
     object:self
     userInfo:@{
                @"event": @"SensorsSamplerUpdate_noise",
                @"type": updateType,
                @"value": [NSNumber numberWithDouble:spl]
                }];
}

- (int)getOffset:(float)averagePower
{
    int offset = 83;
    if (averagePower > -20.0) {
        offset = 86;
    }
    if (averagePower > -15.0) {
        offset = 90;
    }
    if (averagePower > -10.0) {
        offset = 94;
    }
    return offset;
}

@end
