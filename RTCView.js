'use strict';

import {
  DeviceEventEmitter,
  NativeModules,
  requireNativeComponent,
} from 'react-native';
const WebRTCModule = NativeModules.WebRTCModule;

import {
  PropTypes,
} from 'react';

const RTCView = {
  name: 'RTCVideoView',
  propTypes: {
    /**
     * In the fashion of
     * https://www.w3.org/TR/html5/embedded-content-0.html#dom-video-videowidth
     * and https://www.w3.org/TR/html5/rendering.html#video-object-fit,
     * resembles the CSS style object-fit.
     */
    objectFit: PropTypes.oneOf(['contain', 'cover']),
    streamURL: PropTypes.string,
  },
};

const v = requireNativeComponent('RTCVideoView', RTCView, {nativeOnly: {
  testID: true,
  accessibilityComponentType: true,
  renderToHardwareTextureAndroid: true,
  accessibilityLabel: true,
  accessibilityLiveRegion: true,
  importantForAccessibility: true,
  onLayout: true,
}});

module.exports = v;
