/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGImageView.h"

#import "TGModernView.h"

typedef enum {
    TGMessageImageViewOverlayNone = 0,
    TGMessageImageViewOverlayProgress = 1,
    TGMessageImageViewOverlayDownload = 2,
    TGMessageImageViewOverlayPlay = 3,
    TGMessageImageViewOverlaySecret = 4,
    TGMessageImageViewOverlaySecretViewed = 5,
    TGMessageImageViewOverlaySecretProgress = 6,
    TGMessageImageViewOverlayProgressNoCancel = 7
} TGMessageImageViewOverlay;

typedef enum {
    TGMessageImageViewActionDownload = 0,
    TGMessageImageViewActionCancelDownload = 1,
    TGMessageImageViewActionPlay = 2,
    TGMessageImageViewActionSecret = 3
} TGMessageImageViewActionType;

@class TGMessageImageView;

@protocol TGMessageImageViewDelegate <NSObject>

@optional

- (void)messageImageViewActionButtonPressed:(TGMessageImageView *)messageImageView withAction:(TGMessageImageViewActionType)action;

@end

@interface TGMessageImageViewContainer : UIView <TGModernView>

@property (nonatomic, strong) TGMessageImageView *imageView;

@end

@interface TGMessageImageView : TGImageView <TGModernView>

@property (nonatomic, weak) id<TGMessageImageViewDelegate> delegate;

@property (nonatomic) int overlayType;
@property (nonatomic) float progress;
@property (nonatomic) NSTimeInterval completeDuration;
@property (nonatomic, strong) UIColor *overlayBackgroundColorHint;

@property (nonatomic, copy) void (^progressBlock)(TGImageView *, float);
@property (nonatomic, copy) void (^completionBlock)(TGImageView *);

- (UIImage *)currentImage;

- (void)setOverlayType:(int)overlayType animated:(bool)animated;
- (void)setProgress:(float)progress animated:(bool)animated;
- (void)setSecretProgress:(float)progress completeDuration:(NSTimeInterval)completeDuration animated:(bool)animated;
- (void)setTimestampColor:(UIColor *)color;
- (void)setTimestampHidden:(bool)timestampHidden;
- (void)setTimestampPosition:(int)timestampPosition;
- (void)setTimestampString:(NSString *)timestampString displayCheckmarks:(bool)displayCheckmarks checkmarkValue:(int)checkmarkValue animated:(bool)animated;
- (void)setAdditionalDataString:(NSString *)additionalDataString animated:(bool)animated;
- (void)setDisplayTimestampProgress:(bool)displayTimestampProgress;
- (void)setIsBroadcast:(bool)isBroadcast;
- (void)setDetailStrings:(NSArray *)detailStrings animated:(bool)animated;

@end
