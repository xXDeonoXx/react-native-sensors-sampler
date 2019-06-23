#import "SensorsSampler.h"
#import <React/RCTConvert.h>

@interface SensorsSampler()
@property int interval;
@property int period;
@property BOOL useBackCamera; // default false

@end

@implementation SensorsSampler

RCT_EXPORT_MODULE()

-(int) getInterval {
    return self.interval ? self.interval : 100;
}
-(int) getPeriod {
    return self.period ? self.period : 10000;
}

RCT_EXPORT_METHOD(settings:(NSDictionary *)settings)
{
    if ([settings objectForKey:@"interval"]) {
        self.interval = [RCTConvert NSNumber:settings[@"interval"]].intValue;
    }
    if ([settings objectForKey:@"period"]) {
        self.period = [RCTConvert NSNumber:settings[@"period"]].intValue;
    }
    if ([settings objectForKey:@"useBackCamera"]) {
        self.useBackCamera = [RCTConvert BOOL:settings[@"useBackCamera"]];
    }
}

RCT_EXPORT_METHOD(subscribe:(NSString *)subscribeToEvent
                  subscribeWithResolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([subscribeToEvent isEqualToString:@"light"]) {
        return resolve(@"fine");
    }
    if ([subscribeToEvent isEqualToString:@"noise"]) {
        return resolve(@"fine");
    }
    reject(@"SensorsSamplerError", @"undefined event", NULL);
}

RCT_EXPORT_METHOD(subscribe:(NSString *)unsubscribeFromEvent)
{
    
}


@end

