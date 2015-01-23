/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGMessageViewModel.h"

@class TGImageInfo;
@class TGUser;
@class TGModernViewContext;

@class TGModernButtonViewModel;
@class TGMessageImageViewModel;

@interface TGImageMessageViewModel : TGMessageViewModel
{
    @protected
    
    bool _mediaIsAvailable;
}

@property (nonatomic, strong) TGMessageImageViewModel *imageModel;

@property (nonatomic) bool previewEnabled;
@property (nonatomic) bool isSecret;

- (instancetype)initWithMessage:(TGMessage *)message imageInfo:(TGImageInfo *)imageInfo author:(TGUser *)author context:(TGModernViewContext *)context;

+ (void)calculateImageSizesForImageSize:(in CGSize)imageSize thumbnailSize:(out CGSize *)thumbnailSize renderSize:(out CGSize *)renderSize squareAspect:(bool)squareAspect;

- (void)updateImageInfo:(TGImageInfo *)imageInfo;

- (UIImage *)dateBackground;
- (UIColor *)dateColor;
- (UIImage *)checkPartialImage;
- (UIImage *)checkCompleteImage;
- (int)clockProgressType;
- (CGPoint)dateOffset;
- (bool)instantPreviewGesture;
- (void)activateMedia;
- (int)defaultOverlayActionType;

- (void)enableInstantPreview;
- (NSString *)defaultAdditionalDataString;

@end
