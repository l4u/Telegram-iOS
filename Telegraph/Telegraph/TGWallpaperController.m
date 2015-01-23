/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGWallpaperController.h"

#import "TGHacks.h"
#import "TGFont.h"
#import "TGImageUtils.h"

#import "TGHighlightableButton.h"
#import "TGRemoteImageView.h"

#import "TGWallpaperInfo.h"
#import "TGCustomImageWallpaperInfo.h"

@interface TGWallpaperController () <UIScrollViewDelegate>
{
    TGWallpaperInfo *_wallpaperInfo;
    UIImage *_thumbnailImage;
    TGRemoteImageView *_imageView;
    
    CGSize _adjustingImageSize;
    CGFloat _adjustingImageScale;
    UIScrollView *_scrollView;
    
    TGHighlightableButton *_setButton;
}

@end

@implementation TGWallpaperController

- (instancetype)initWithWallpaperInfo:(TGWallpaperInfo *)wallpaperInfo thumbnailImage:(UIImage *)thumbnailImage
{
    self = [super init];
    if (self != nil)
    {
        _actionHandle = [[ASHandle alloc] initWithDelegate:self releaseOnMainThread:true];
        
        _wallpaperInfo = wallpaperInfo;
        _thumbnailImage = thumbnailImage;
        
        [self setTitleText:TGLocalized(@"Wallpaper.Wallpaper")];
        
        self.automaticallyManageScrollViewInsets = false;
    }
    return self;
}

- (void)dealloc
{
    
}

#pragma mark -

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.navigationController == nil && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [TGHacks animateApplicationStatusBarAppearance:TGStatusBarAppearanceAnimationSlideUp delay:0.0 duration:0.5 completion:^
        {
            [TGHacks setApplicationStatusBarAlpha:0.0f];
        }];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
 
    if (self.navigationController == nil && [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        [TGHacks setApplicationStatusBarAlpha:1.0f];
        [TGHacks animateApplicationStatusBarAppearance:TGStatusBarAppearanceAnimationSlideDown duration:iosMajorVersion() >= 7 ? 0.23 : 0.3 completion:nil];
    }
}

- (CGSize)referenceViewSize
{
    if (self.modalPresentationStyle == UIModalPresentationFormSheet || self.navigationController.modalPresentationStyle == UIModalPresentationFormSheet)
        return CGSizeMake(540.0f, 620.0f);
    
    return [TGViewController screenSizeForInterfaceOrientation:UIInterfaceOrientationPortrait];
}

- (void)loadView
{
    [super loadView];
    
    self.view.clipsToBounds = true;
    self.view.backgroundColor = [UIColor blackColor];
    
    CGSize screenSize = [self referenceViewSize];
    
    _imageView = [[TGRemoteImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, screenSize.width, screenSize.height)];
    
    bool imageLoading = false;
    
    UIImage *immediateImage = [_wallpaperInfo image];
    if (immediateImage != nil)
        [_imageView loadImage:immediateImage];
    else
    {
        _imageView.useCache = false;
        _imageView.contentHints = TGRemoteImageContentHintLoadFromDiskSynchronously;
        _imageView.fadeTransition = true;
        _imageView.fadeTransitionDuration = 0.3;
        
        imageLoading = true;
        
        ASHandle *actionHandle = _actionHandle;
        [_imageView setProgressHandler:^(TGRemoteImageView *imageView, float progress)
        {
            if (ABS(progress - 1.0f) < FLT_EPSILON && [imageView currentImage] != nil)
            {
                [actionHandle requestAction:@"imageLoaded" options:nil];
            }
        }];
        [_imageView loadImage:[_wallpaperInfo fullscreenUrl] filter:nil placeholder:_thumbnailImage];
    }
    
    if (_enableWallpaperAdjustment && immediateImage != nil)
    {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, screenSize.width, screenSize.height)];
        [self.view addSubview:_scrollView];
        
        _scrollView.showsHorizontalScrollIndicator = false;
        _scrollView.showsVerticalScrollIndicator = false;
        _scrollView.delegate = self;
        
        _adjustingImageScale = immediateImage.scale;
        _adjustingImageSize = CGSizeMake(immediateImage.size.width / _adjustingImageScale, immediateImage.size.height / _adjustingImageScale);
        
        _imageView.frame = CGRectMake(0, 0, _adjustingImageSize.width, _adjustingImageSize.height);
        _imageView.contentMode = UIViewContentModeScaleToFill;
        [_scrollView addSubview:_imageView];
        
        [self _adjustScrollView];
        _scrollView.zoomScale = _scrollView.minimumZoomScale;
        
        CGSize contentSize = _scrollView.contentSize;
        CGSize viewSize = _scrollView.frame.size;
        _scrollView.contentOffset = CGPointMake(MAX(0, floorf((contentSize.width - viewSize.width) / 2)), MAX(0, floorf((contentSize.height - viewSize.height) / 2)));
    }
    else
    {
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self.view addSubview:_imageView];
    }
    
    UIView *_panelView = [[UIView alloc] initWithFrame:CGRectMake(0, screenSize.height - 49, screenSize.width, 49)];
    
    if (iosMajorVersion() >= 7 && [TGViewController isWidescreen])
    {
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:_panelView.bounds];
        toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_panelView addSubview:toolbar];
    }
    else
        _panelView.backgroundColor = UIColorRGBA(0xffffff, 0.96f);
    [self.view addSubview:_panelView];
    
    CGFloat separatorWidth = TGIsRetina() ? 0.5f : 1.0f;
    
    TGHighlightableButton *cancelButton = [[TGHighlightableButton alloc] initWithFrame:CGRectMake(0, 0, floorf(_panelView.frame.size.width / 2) - separatorWidth, _panelView.frame.size.height)];
    cancelButton.normalBackgroundColor = [UIColor clearColor];
    cancelButton.highlightedBackgroundColor = UIColorRGBA(0x000000, 0.08f);
    [cancelButton addTarget:self action:@selector(cancelButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [cancelButton setTitle:TGLocalized(@"Common.Cancel") forState:UIControlStateNormal];
    cancelButton.titleLabel.font = TGSystemFontOfSize(17);
    [cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [cancelButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [_panelView addSubview:cancelButton];
    
    _setButton = [[TGHighlightableButton alloc] initWithFrame:CGRectMake(cancelButton.frame.origin.x + cancelButton.frame.size.width + separatorWidth, 0, floorf(_panelView.frame.size.width / 2), _panelView.frame.size.height)];
    _setButton.normalBackgroundColor = [UIColor clearColor];
    _setButton.highlightedBackgroundColor = UIColorRGBA(0x000000, 0.08f);
    _setButton.enabled = !imageLoading;
    [_setButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_setButton setTitle:TGLocalized(@"Wallpaper.Set") forState:UIControlStateNormal];
    _setButton.titleLabel.font = TGSystemFontOfSize(17);
    [_setButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [_setButton setTitleColor:UIColorRGBA(0x000000, 0.4f) forState:UIControlStateDisabled];
    [_setButton setTitleShadowColor:[UIColor clearColor] forState:UIControlStateNormal];
    [_panelView addSubview:_setButton];
    
    UIView *separatorView = [[UIView alloc] initWithFrame:CGRectMake(floorf(_panelView.frame.size.width / 2) - separatorWidth, 0, separatorWidth, _panelView.frame.size.height)];
    separatorView.backgroundColor = UIColorRGBA(0x000000, 0.52f);
    [_panelView addSubview:separatorView];
}

- (BOOL)shouldAutorotate
{
    return [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark -

- (void)scrollViewDidZoom:(UIScrollView *)__unused scrollView
{
    [self _adjustScrollView];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)__unused scrollView withView:(UIView *)__unused view atScale:(float)__unused scale
{
    [self _adjustScrollView];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)__unused scrollView
{
    return _imageView;
}

- (void)_adjustScrollView
{
    CGSize imageSize = _adjustingImageSize;
    float imageScale = _adjustingImageScale;
    imageSize.width /= imageScale;
    imageSize.height /= imageScale;
    
    CGFloat scaleWidth = _scrollView.frame.size.width / imageSize.width;
    CGFloat scaleHeight = _scrollView.frame.size.height / imageSize.height;
    CGFloat minScale = MAX(scaleWidth, scaleHeight);
    
    if (_scrollView.minimumZoomScale != minScale)
        _scrollView.minimumZoomScale = minScale;
    if (_scrollView.maximumZoomScale != minScale * 3.0f)
        _scrollView.maximumZoomScale = minScale * 3.0f;
    
    CGSize boundsSize = _scrollView.bounds.size;
    CGRect contentsFrame = _imageView.frame;
    
    if (boundsSize.width > contentsFrame.size.width)
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
    else
        contentsFrame.origin.x = 0;
    
    if (boundsSize.height > contentsFrame.size.height)
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
    else
        contentsFrame.origin.y = 0;
    
    _imageView.frame = contentsFrame;
}

#pragma mark

- (void)cancelButtonPressed
{
    if (self.navigationController != nil)
        [self.navigationController popViewControllerAnimated:true];
    else
        [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
}

- (void)doneButtonPressed
{
    UIImage *currentImage = [_imageView currentImage];
    if (currentImage != nil)
    {
        TGWallpaperInfo *selectedWallpaperInfo = _wallpaperInfo;
        
        if (_enableWallpaperAdjustment)
        {
            CGSize screenSize = [self referenceViewSize];
            CGFloat screenScale = [UIScreen mainScreen].scale;
            screenSize.width *= screenScale;
            screenSize.height *= screenScale;
            
            CGFloat screenSide = MAX(screenSize.width, screenSize.height);
            
            float scale = 1.0f / _scrollView.zoomScale;
            
            CGRect visibleRect;
            visibleRect.origin.x = _scrollView.contentOffset.x * scale;
            visibleRect.origin.y = _scrollView.contentOffset.y * scale;
            visibleRect.size.width = _scrollView.bounds.size.width * scale;
            visibleRect.size.height = _scrollView.bounds.size.height * scale;
            
            UIImage *croppedImage = TGFixOrientationAndCrop(currentImage, visibleRect, TGFitSize(visibleRect.size, CGSizeMake(screenSide, screenSide)));
            if (croppedImage != nil)
                selectedWallpaperInfo = [[TGCustomImageWallpaperInfo alloc] initWithImage:croppedImage];
        }
        
        id<TGWallpaperControllerDelegate> delegate = _delegate;
        if ([delegate respondsToSelector:@selector(wallpaperController:didSelectWallpaperWithInfo:)])
            [delegate wallpaperController:self didSelectWallpaperWithInfo:selectedWallpaperInfo];
        
        [self.presentingViewController dismissViewControllerAnimated:true completion:nil];
    }
}

- (void)actionStageActionRequested:(NSString *)action options:(id)__unused options
{
    if ([action isEqualToString:@"imageLoaded"])
    {
        _setButton.enabled = true;
    }
}

@end
