import { NativeModules, DeviceEventEmitter } from 'react-native';

const { SensorsSampler } = NativeModules;

export const allowedSubscriptions = {
    NOISE: 'noise',
    LIGHT: 'light',
};
const subscriptions = {};

/**
 * subscribe to sample event
 * @param interval: define update interval in millis
 * @param period: total sample period in millis
 * @param event: one of allowedSubscriptions
 * @param successCallback: invoked every update
 * @param errorCallback: invoked when error occurred
 */
export const subscribeTo = (interval, period, event, successCallback, errorCallback) => {
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

    SensorsSampler.subscribe(interval || 100, period || 10000, event)
        .then(() => {
            subscriptions[event] = DeviceEventEmitter.addEventListener(
                `RCTSensorsSamplerUpdate_${event}`,
                (params) => {
                    const { type, value } = params;
                    successCallback(value);
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
    SensorsSampler.unsubscribe(event);
    subscriptions[event].remove();
    delete subscriptions[event];
};
