#import "TGAttachmentSheetButtonItemView.h"

#import "TGModernButton.h"
#import "TGImageUtils.h"
#import "TGFont.h"

@interface TGAttachmentSheetButtonItemView ()
{
    TGModernButton *_button;
}

@end

@implementation TGAttachmentSheetButtonItemView

- (instancetype)initWithTitle:(NSString *)title pressed:(void (^)())pressed
{
    self = [super init];
    if (self != nil)
    {
        _button = [[TGModernButton alloc] init];
        [_button setTitle:title forState:UIControlStateNormal];
        [_button setTitleColor:TGAccentColor()];
        _button.titleLabel.font = TGSystemFontOfSize(20.0f + TGRetinaPixel);
        [_button addTarget:self action:@selector(_buttonPressed) forControlEvents:UIControlEventTouchUpInside];
        CGFloat separatorHeight = TGIsRetina() ? 0.5f : 1.0f;
        _button.backgroundSelectionInsets = UIEdgeInsetsMake(1.0f + separatorHeight, 0.0f, 1.0f, 0.0f);
        _button.highlightBackgroundColor = TGSelectionColor();
        _button.highlighted = false;
        
        __weak TGAttachmentSheetButtonItemView *weakSelf = self;
        _button.highlitedChanged = ^(bool highlighted)
        {
            __strong TGAttachmentSheetButtonItemView *strongSelf = weakSelf;
            if (strongSelf != nil && highlighted)
            {
                for (UIView *sibling in strongSelf.superview.subviews.reverseObjectEnumerator)
                {
                    if ([sibling isKindOfClass:[TGAttachmentSheetItemView class]])
                    {
                        if (sibling != strongSelf)
                        {
                            [strongSelf.superview exchangeSubviewAtIndex:[strongSelf.superview.subviews indexOfObject:strongSelf] withSubviewAtIndex:[strongSelf.superview.subviews indexOfObject:sibling]];
                        }
                        break;
                    }
                }
            }
        };
        
        [self addSubview:_button];
        
        _pressed = [pressed copy];
        
    }
    return self;
}

- (void)setTitle:(NSString *)title
{
    [_button setTitle:title forState:UIControlStateNormal];
}

- (void)setBold:(bool)bold
{
    _button.titleLabel.font = bold ? TGMediumSystemFontOfSize(20.0f + TGRetinaPixel) : TGSystemFontOfSize(20.0f + TGRetinaPixel);
}

- (void)_buttonPressed
{
    if (_pressed)
        _pressed();
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _button.frame = CGRectMake(0.0f, 1.0f, self.bounds.size.width, self.bounds.size.height - 2.0f);
}

@end
