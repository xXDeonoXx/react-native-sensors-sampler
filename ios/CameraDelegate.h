#import <Foundation/Foundation.h>
#import <AVFoundation/AVCaptureOutput.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraDelegate : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
- (id) initWithParams:(int) interval period:(int)period useBackCamera:(BOOL)useBackCamera;
- (BOOL) startCamera;
- (void) stopCamera;
@end

NS_ASSUME_NONNULL_END
