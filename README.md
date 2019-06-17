# react-native-sensors-sampler

## Getting started

`$ npm install react-native-sensors-sampler --save`

### Mostly automatic installation

`$ react-native link react-native-sensors-sampler`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-sensors-sampler` and add `SensorsSampler.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libSensorsSampler.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainApplication.java`
  - Add `import com.dayzz.SensorsSamplerPackage;` to the imports at the top of the file
  - Add `new SensorsSamplerPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-sensors-sampler'
  	project(':react-native-sensors-sampler').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-sensors-sampler/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-sensors-sampler')
  	```


## Usage
```javascript
import SensorsSampler from 'react-native-sensors-sampler';

// TODO: What to do with the module?
SensorsSampler;
```
