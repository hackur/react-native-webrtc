//
//  RTCVideoViewManager.m
//  TestReact
//
//  Created by one on 2015/9/25.
//  Copyright © 2015年 Facebook. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>

#import "RTCVideoViewManager.h"
#import "RTCEAGLVideoView.h"
#import "RTCVideoTrack.h"
#import "RTCMediaStream.h"
#import "WebRTCModule.h"

/**
 * Implements an equivalent of HTMLVideoElement i.e. Web's video element.
 */
@interface RTCVideoView : UIView <RTCVideoRenderer, RTCEAGLVideoViewDelegate>

@end

@implementation RTCVideoView {
  /**
   * The RTCEAGLVideoView which implements the actual RTCVideoRenderer of this
   * instance and which this instance fits within itself so that the rendered
   * video preserves the aspect ratio of {@link #_videoSize}.
   */
  RTCEAGLVideoView *_subview;
  /**
   * The width and height of the video (frames) rendered by {@link #_subview}.
   */
  CGSize _videoSize;
}

/**
 * Initializes and returns a newly allocated view object with the specified
 * frame rectangle.
 *
 * @param frame the frame rectangle for the view, measured in points
 */
- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _subview = [[RTCEAGLVideoView alloc] init];
    _subview.delegate = self;

    _videoSize.height = 0;
    _videoSize.width = 0;

    self.opaque = NO;
    [self addSubview:_subview];
  }
  return self;
}

/**
 * Lays out the subview of this instance while preserving the aspect ratio of
 * the video it renders.
 */
- (void)layoutSubviews {
  [super layoutSubviews];

  CGFloat width = _videoSize.width, height = _videoSize.height;
  CGRect newValue;
  if (width <= 0 || height <= 0) {
    newValue.origin.x = 0;
    newValue.origin.y = 0;
    newValue.size.width = 0;
    newValue.size.height = 0;
  } else {
    // The implementaiton is in accord with
    // https://www.w3.org/TR/html5/embedded-content-0.html#the-video-element:
    //
    // In the absence of style rules to the contrary, video content should be
    // rendered inside the element's playback area such that the video content
    // is shown centered in the playback area at the largest possible size that
    // fits completely within it, with the video content's aspect ratio being
    // preserved. Thus, if the aspect ratio of the playback area does not match
    // the aspect ratio of the video, the video will be shown letterboxed or
    // pillarboxed. Areas of the element's playback area that do not contain the
    // video represent nothing.
    newValue
      = AVMakeRectWithAspectRatioInsideRect(
          CGSizeMake(width, height),
          self.bounds);
  }

  CGRect oldValue = _subview.frame;
  if (newValue.origin.x != oldValue.origin.x
      || newValue.origin.y != oldValue.origin.y
      || newValue.size.width != oldValue.size.width
      || newValue.size.height != oldValue.size.height) {
    _subview.frame = newValue;
  }
}

#pragma mark - RTCVideoRenderer methods

/**
 * Renders a specific video frame. Delegates to the subview of this instance
 * which implements the actual RTCVideoRenderer.
 *
 * @param frame the video frame to render
 */
- (void)renderFrame:(RTCI420Frame*)frame {
  [_subview renderFrame:frame];
}

/**
 * Sets the size of the video frame to render.
 *
 * @param size the size of the video frame to render
 */
- (void)setSize:(CGSize)size {
  [_subview setSize:size];
}

#pragma mark - RTCEAGLVideoViewDelegate methods

/**
 * Notifies this RTCEAGLVideoViewDelegate that a specific RTCEAGLVideoView had
 * the size of the video (frames) it renders changed.
 *
 * @param videoView the RTCEAGLVideoView which had the size of the video
 * (frames) it renders changed to the specified size
 * @param size the new size of the video (frames) to be rendered by the
 * specified videoView
 */
- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
  if (videoView == _subview) {
    _videoSize = size;

    __weak UIView *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      UIView *strongSelf = weakSelf;
      [strongSelf setNeedsLayout];
    });
  }
}

@end

@interface RTCVideoView (WebRTCModule)

@property (nonatomic, strong) RTCVideoTrack *currentRenderer;

@end

@implementation RTCVideoView (WebRTCModule)

- (RTCVideoTrack *)currentRenderer {
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setCurrentRenderer:(RTCVideoTrack *)currentRenderer {
  objc_setAssociatedObject(self, @selector(currentRenderer), currentRenderer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation RTCVideoViewManager

RCT_EXPORT_MODULE()

- (UIView *)view {
  RTCVideoView *v = [[RTCVideoView alloc] init];
  v.clipsToBounds = YES;
  return v;
}

- (dispatch_queue_t)methodQueue {
  return dispatch_get_main_queue();
}

RCT_CUSTOM_VIEW_PROPERTY(streamURL, NSNumber, RTCVideoView) {
  if (json) {
    NSString *objectID = (NSString *)json;

    WebRTCModule *module = [self.bridge moduleForName:@"WebRTCModule"];
    RTCMediaStream *stream = module.mediaStreams[objectID];

    if (stream.videoTracks.count) {
      RTCVideoTrack *localVideoTrack = stream.videoTracks[0];
      if (view.currentRenderer) {
        [view.currentRenderer removeRenderer:view];
      }
      view.currentRenderer = localVideoTrack;
      [localVideoTrack addRenderer:view];
    }
  }
}

@end
