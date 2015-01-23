#import "TGDocumentMessageIconView.h"

#import "TGFont.h"

#import "TGMessageImageView.h"

#import "TGMessageImageViewOverlayView.h"
#import "TGModernButton.h"

static const CGFloat circleDiameter = 50.0f;

@interface TGDocumentMessageIconView ()
{
    UIImageView *_backgroundView;
    UILabel *_extensionLabel;
    
    TGModernButton *_buttonView;
    TGMessageImageViewOverlayView *_overlayView;
    
    CGFloat _progress;
}

@property (nonatomic, strong) NSString *viewIdentifier;
@property (nonatomic, strong) NSString *viewStateIdentifier;

@end

@implementation TGDocumentMessageIconView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil)
    {
        static UIImage *backgroundImage = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            UIImage *rawImage = [UIImage imageNamed:@"ModernDocumentMessageIconBackground.png"];
            backgroundImage = [rawImage stretchableImageWithLeftCapWidth:(int)(rawImage.size.width / 2) topCapHeight:(int)(rawImage.size.height / 2)];
        });
        
        _backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
        _backgroundView.frame = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
        [self addSubview:_backgroundView];
        
        _extensionLabel = [[UILabel alloc] init];
        _extensionLabel.backgroundColor = [UIColor clearColor];
        _extensionLabel.opaque = false;
        _extensionLabel.textColor = TGAccentColor();
        _extensionLabel.font = TGSystemFontOfSize(19.0f);
        [self addSubview:_extensionLabel];
        
        _buttonView = [[TGModernButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, circleDiameter, circleDiameter)];
        _buttonView.exclusiveTouch = true;
        _buttonView.modernHighlight = true;
        [_buttonView addTarget:self action:@selector(actionButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        
        _overlayView = [[TGMessageImageViewOverlayView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, circleDiameter, circleDiameter)];
        [_overlayView setOverlayStyle:TGMessageImageViewOverlayStyleAccent];
        _overlayView.userInteractionEnabled = false;
        [_buttonView addSubview:_overlayView];
        
        static UIImage *highlightImage = nil;
        static dispatch_once_t onceToken2;
        dispatch_once(&onceToken2, ^
        {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(circleDiameter, circleDiameter), false, 0.0f);
            CGContextRef context = UIGraphicsGetCurrentContext();
            CGContextSetFillColorWithColor(context, UIColorRGBA(0x000000, 0.4f).CGColor);
            CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, circleDiameter, circleDiameter));
            highlightImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        });
        
        _buttonView.highlightImage = highlightImage;
    }
    return self;
}

- (void)willBecomeRecycled
{
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    _backgroundView.frame = CGRectMake(0.0f, 0.0f, frame.size.width, frame.size.height);
    _extensionLabel.frame = CGRectMake(CGFloor((frame.size.width - _extensionLabel.bounds.size.width) / 2.0f), CGFloor((frame.size.height - _extensionLabel.bounds.size.height) / 2.0f), _extensionLabel.bounds.size.width, _extensionLabel.bounds.size.height);
    
    CGRect buttonFrame = _buttonView.frame;
    buttonFrame.origin = CGPointMake(CGFloor(frame.size.width - buttonFrame.size.width) / 2.0f, CGFloor(frame.size.height - buttonFrame.size.height) / 2.0f);
    if (!CGRectEqualToRect(_buttonView.frame, buttonFrame))
    {
        _buttonView.frame = buttonFrame;
    }
}

- (void)setFileExtension:(NSString *)fileExtension
{
    if (!TGStringCompare(_fileExtension, fileExtension))
    {
        _fileExtension = fileExtension;
        _extensionLabel.text = fileExtension;
        CGSize labelSize = [_extensionLabel sizeThatFits:CGSizeMake(65.0f, 1000.0f)];
        _extensionLabel.frame = CGRectMake(CGFloor((self.frame.size.width - labelSize.width) / 2.0f), CGFloor((self.frame.size.height - labelSize.height) / 2.0f), labelSize.width, labelSize.height);
    }
}

- (void)setOverlayType:(int)overlayType
{
    [self setOverlayType:overlayType animated:false];
}

- (void)setOverlayType:(int)overlayType animated:(bool)animated
{
    if (_overlayType != overlayType)
    {
        _overlayType = overlayType;
        
        switch (_overlayType)
        {
            case TGMessageImageViewOverlayDownload:
            {
                if (_buttonView.superview == nil)
                {
                    [self addSubview:_buttonView];
                }
                
                _buttonView.alpha = 1.0f;
                _extensionLabel.alpha = 0.0f;
                
                [_overlayView setDownload];
                
                break;
            }
            case TGMessageImageViewOverlayPlay:
            {
                if (_buttonView.superview == nil)
                {
                    [self addSubview:_buttonView];
                }
                
                _buttonView.alpha = 1.0f;
                _extensionLabel.alpha = 0.0f;
                
                [_overlayView setPlay];
                
                break;
            }
            case TGMessageImageViewOverlayProgress:
            {
                if (_buttonView.superview == nil)
                {
                    [self addSubview:_buttonView];
                }
                
                _buttonView.alpha = 1.0f;
                _extensionLabel.alpha = 0.0f;
                
                [_overlayView setProgress:_progress animated:false];
                
                break;
            }
            case TGMessageImageViewOverlayNone:
            default:
            {
                if (_buttonView.superview != nil)
                {
                    if (animated)
                    {
                        [UIView animateWithDuration:0.2 animations:^
                         {
                             _buttonView.alpha = 0.0f;
                             _extensionLabel.alpha = 1.0f;
                         } completion:^(BOOL finished)
                         {
                             if (finished)
                             {
                                 [_buttonView removeFromSuperview];
                             }
                         }];
                    }
                    else
                    {
                        [_buttonView removeFromSuperview];
                        _extensionLabel.alpha = 1.0f;
                    }
                }
                
                break;
            }
        }
    }
}

- (void)setProgress:(float)progress
{
    [self setProgress:progress animated:false];
}

- (void)setProgress:(float)progress animated:(bool)animated
{
    if (ABS(_progress - progress) > FLT_EPSILON)
    {
        _progress = progress;
        
        if (_overlayType == TGMessageImageViewOverlayProgress)
            [_overlayView setProgress:progress animated:animated];
    }
}

- (void)actionButtonPressed
{
    TGMessageImageViewActionType action = TGMessageImageViewActionDownload;
    
    switch (_overlayType)
    {
        case TGMessageImageViewOverlayDownload:
        {
            action = TGMessageImageViewActionDownload;
            break;
        }
        case TGMessageImageViewOverlayProgress:
        {
            action = TGMessageImageViewActionCancelDownload;
            break;
        }
        case TGMessageImageViewOverlayPlay:
        {
            action = TGMessageImageViewActionPlay;
            break;
        }
        default:
            break;
    }
    
    id<TGMessageImageViewDelegate> delegate = _delegate;
    if ([delegate respondsToSelector:@selector(messageImageViewActionButtonPressed:withAction:)])
        [delegate messageImageViewActionButtonPressed:(TGMessageImageView *)self withAction:action];
}

@end
