/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGPreparedRemoteVideoMessage.h"

#import "TGMessage.h"

@implementation TGPreparedRemoteVideoMessage

- (instancetype)initWithVideoId:(int64_t)videoId accessHash:(int64_t)accessHash videoSize:(CGSize)videoSize size:(int32_t)size duration:(NSTimeInterval)duration videoInfo:(TGVideoInfo *)videoInfo thumbnailInfo:(TGImageInfo *)thumbnailInfo
{
    self = [super init];
    if (self != nil)
    {
        _videoId = videoId;
        _accessHash = accessHash;
        _videoSize = videoSize;
        _size = size;
        _duration = duration;
        _videoInfo = videoInfo;
        _thumbnailInfo = thumbnailInfo;
    }
    return self;
}

- (TGMessage *)message
{
    TGMessage *message = [[TGMessage alloc] init];
    message.mid = self.mid;
    message.date = self.date;
    message.isBroadcast = self.isBroadcast;
    message.messageLifetime = self.messageLifetime;
    
    TGVideoMediaAttachment *videoAttachment = [[TGVideoMediaAttachment alloc] init];
    videoAttachment.videoId = _videoId;
    videoAttachment.accessHash = _accessHash;
    videoAttachment.duration = (int)_duration;
    videoAttachment.dimensions = _videoSize;
    videoAttachment.thumbnailInfo = _thumbnailInfo;
    videoAttachment.videoInfo = _videoInfo;
    
    message.mediaAttachments = @[videoAttachment];
    
    return message;
}

@end
