import { NativeModules, DeviceEventEmitter, NativeEventEmitter, Platform } from 'react-native';

const { SensorsSampler } = NativeModules;

export const allowedSubscriptions = {
    NOISE: 'noise',
    LIGHT: 'light',
};
const subscriptions = {};

/**
 * set settings in Native SensorsSampler
 * all keys are optional, it will set only the keys which you define in the settingsMap
 * @param settingsMap: {
 *      interval: define update interval in millis, default 100 millis
 *      period: total sample period in millis, default 10000 millis
 *      useBackCamera: iOS only - for light sampler
 * }
 */
export const settings = (settingsMap) => {
    SensorsSampler.settings(settingsMap);
};

/**
 * subscribe to sample event
 * @param event: one of allowedSubscriptions
 * @param successCallback: invoked every update
 * @param errorCallback: invoked when error occurred
 */
export const subscribeTo = (event, successCallback, errorCallback) => {
    if (!successCallback) {
        if (errorCallback) {
            errorCallback({ code: 'no_success_callback', msg: 'successCallback must be set' });
        } else {
            console.warn('react-native-sensors-sampler, successCallback must be set');
        }
        return;
    }
    if (!Object.values(allowedSubscriptions).includes(event)) {
        if (errorCallback) {
            errorCallback({ code: 'unsupported_event', event });
        }
        return;
    }
    if (subscriptions[event]) {
        if (errorCallback) {
            errorCallback({ code: 'already_subscribed', event });
        }
        return;
    }

    SensorsSampler.subscribeToEvent(event)
        .then(() => {
            const listenerObject = Platform.OS === 'ios'
                ? new NativeEventEmitter(SensorsSampler)
                : DeviceEventEmitter;
            subscriptions[event] = listenerObject.addListener(
                `SensorsSamplerUpdate_${event}`,
                (params) => {
                    const { type, value } = params;
                    successCallback({ value, updateType: type });
                    if (type === 'end') {
                        subscriptions[event].remove();
                        delete subscriptions[event];
                    }
                },
            );
        })
        .catch((error) => {
            if (errorCallback) {
                const { code } = error || {};
                errorCallback({ code });
            } else {
                console.warn('react-native-sensors-sampler, error on subscribeTo', error);
            }
        });
};

export const unsubscribe = (event) => {
    if (!subscriptions[event]) {
        console.warn('react-native-sensors-sampler invalid event for unsubscribe', event);
        return;
    }
    SensorsSampler.unsubscribeFromEvent(event);
    subscriptions[event].remove();
    delete subscriptions[event];
};
