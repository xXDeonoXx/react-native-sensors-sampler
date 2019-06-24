#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#elif __has_include("React/RCTBridgeModule.h")
#import "React/RCTBridgeModule.h"
#else
#import "RCTBridgeModule.h"
#endif

#if __has_include(<React/RCTEventEmitter.h>)
#import <React/RCTEventEmitter.h>
#elif __has_include("React/RCTEventEmitter.h")
#import "React/RCTEventEmitter.h"
#else
#import "RCTEventEmitter.h"
#endif

@interface SensorsSampler : RCTEventEmitter <RCTBridgeModule>

@end
