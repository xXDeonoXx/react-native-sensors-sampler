#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioMonitor : NSObject
- (id) initWithParams:(int)interval period:(int)period;
- (BOOL) startSampling;
- (void) stopSampling;
@end

NS_ASSUME_NONNULL_END
