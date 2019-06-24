import { NativeModules, DeviceEventEmitter, NativeEventEmitter } from 'react-native';

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
            errorCallback('successCallback must be set');
        } else {
            console.warn('react-native-sensors-sampler, successCallback must be set');
        }
        return;
    }
    if (!Object.values(allowedSubscriptions).includes(event)) {
        if (errorCallback) {
            errorCallback(`unsupported event ${event}`);
        }
        return;
    }
    if (subscriptions[event]) {
        if (errorCallback) {
            errorCallback(`${event} already subscribed`);
        }
        return;
    }

    // TODO: android was DeviceEventEmitter.addListener(...) - check if can work like ios
    SensorsSampler.subscribeToEvent(event)
        .then(() => {
            subscriptions[event] = new NativeEventEmitter(SensorsSampler).addListener(
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
                errorCallback(`error while subscribeTo ${event}, ${error}`);
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
