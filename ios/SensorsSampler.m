#if __has_include(<React/RCTConvert.h>)
#import <React/RCTConvert.h>
#elif __has_include("React/RCTConvert.h")
#import "React/RCTConvert.h"
#else
#import "RCTConvert.h"
#endif

#import "SensorsSampler.h"
#import "CameraDelegate.h"

@interface SensorsSampler()
{
@private
    CameraDelegate *cameraDelegate;
}
@property int interval;
@property int period;
@property BOOL useBackCamera; // default false
@property BOOL hasListener;
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

RCT_REMAP_METHOD(subscribeToEvent,
                event:(NSString *)event
                resolver:(RCTPromiseResolveBlock)resolve
                rejecter:(RCTPromiseRejectBlock)reject)
{
    if ([event isEqualToString:@"light"]) {
        cameraDelegate = [[CameraDelegate alloc] initWithParams:[self getInterval] period:[self getPeriod] useBackCamera:self.useBackCamera];
        if ([cameraDelegate startCamera]) {
            [self addUpdateEventListener];
            return resolve(@"camera is set");
        } else {
            return reject(@"SensorsSamplerError", @"could not set camera", NULL);
        }
    }
    if ([event isEqualToString:@"noise"]) {
        return resolve(@"fine");
    }
    reject(@"SensorsSamplerError", @"undefined event", NULL);
}

RCT_EXPORT_METHOD(unsubscribeFromEvent:(NSString *)unsubscribeFromEvent)
{
    if ([unsubscribeFromEvent isEqualToString:@"light"]) {
        if (cameraDelegate) {
            [cameraDelegate stopCamera];
        }
        [self removeUpdateEventListener];
    }
    if ([unsubscribeFromEvent isEqualToString:@"noise"]) {
        // TODO: ...
    }
}

-(void) addUpdateEventListener
{
    [[NSNotificationCenter defaultCenter]
        addObserver:self
        selector:@selector(eventUpdateNotification:)
        name:@"RCT_sensorUpdateEvent"
        object:nil];
    self.hasListener = YES;
}

-(void) removeUpdateEventListener
{
    if (self.hasListener) {
        [[NSNotificationCenter defaultCenter]
            removeObserver:self
            name:@"RCT_sensorUpdateEvent"
            object:nil];
        self.hasListener = NO;
    }
}

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"SensorsSamplerUpdate_light", @"SensorsSamplerUpdate_noise"];
}


-(void) eventUpdateNotification:(NSNotification *)notification
{
    NSString *event = notification.userInfo[@"event"];
    NSString *type = notification.userInfo[@"type"];
    NSNumber *value = (NSNumber *)notification.userInfo[@"value"];
    NSLog(@"eventUpdateNotification %@, %@, %@", event, type, value);
    [self sendEventWithName:event
                       body:@{@"type": type, @"value": value}];

    if ([type isEqualToString:@"end"]) {
        [self removeUpdateEventListener];
    }
}


@end
