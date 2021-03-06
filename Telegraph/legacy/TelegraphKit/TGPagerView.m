#import "TGPagerView.h"

@interface TGPagerView ()
{
    NSArray *_dotColors;
    NSMutableArray *_dotNormalViews;
    NSMutableArray *_dotHighlightedViews;
    
    UIImage *_normalDotImage;
}

@end

@implementation TGPagerView

- (instancetype)initWithDotColors:(NSArray *)colors
{
    self = [super init];
    if (self != nil)
    {
        _dotColors = colors;
        _dotNormalViews = [[NSMutableArray alloc] init];
        _dotHighlightedViews = [[NSMutableArray alloc] init];
        _dotSpacing = 9;
        
        _normalDotImage = [self dotImageWithColor:UIColorRGB(0xe5e5e5)];
    }
    return self;
}

- (UIImage *)dotImageWithColor:(UIColor *)color
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(7.0f, 7.0f), false, 0.0f);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillEllipseInRect(context, CGRectMake(0.0f, 0.0f, 7.0f, 7.0f));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)setPagesCount:(int)count
{
    if (_dotNormalViews.count != count)
    {
        bool resetPage = false;
        
        if (count < _dotNormalViews.count)
        {
            for (int i = _dotNormalViews.count - 1; i >= count; i--)
            {
                UIView *view = [_dotNormalViews objectAtIndex:i];
                [view removeFromSuperview];
                
                view = [_dotHighlightedViews objectAtIndex:i];
                [view removeFromSuperview];
                
                [_dotNormalViews removeObjectAtIndex:i];
                [_dotHighlightedViews removeObjectAtIndex:i];
            }
        }
        else if (count > _dotNormalViews.count)
        {
            if (_dotNormalViews.count == 0)
                resetPage = true;
            int index = _dotNormalViews.count - 1;
            while (_dotNormalViews.count < count)
            {
                index++;
                
                UIImageView *normalView = [[UIImageView alloc] initWithImage:_normalDotImage];
                [_dotNormalViews addObject:normalView];
                [self addSubview:normalView];
                
                UIImageView *highlightedView = [[UIImageView alloc] initWithImage:[self dotImageWithColor:_dotColors[index % _dotColors.count]]];
                [_dotHighlightedViews addObject:highlightedView];
                [self addSubview:highlightedView];
            }
        }
        
        if (resetPage)
            [self setPage:0];
        
        [self setNeedsLayout];
    }
}

- (void)setPage:(float)page
{
    if (page < 0)
        page = 0;
    else if (page > _dotNormalViews.count - 1)
        page = _dotNormalViews.count - 1;
    
    for (int index = 0; index < (int)_dotNormalViews.count; index++)
    {
        float alpha = 0.0f;
        if (ABS(index - page) > 1)
            alpha = 0.0f;
        else
        {
            alpha = 1.0f - (ABS((float)index - page));
            alpha *= alpha * alpha;
        }
        
        if (alpha < 0.0f)
            alpha = 0.0f;
        if (alpha > 1)
            alpha = 1;
        
        ((UIView *)_dotHighlightedViews[index]).alpha = alpha;
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGSize dotSize = CGSizeMake(7.0f, 7.0f);
    
    float dotSpacing = _dotSpacing;
    float startX = (int)((self.frame.size.width - (dotSize.width * _dotNormalViews.count + dotSpacing * (_dotNormalViews.count - 1))) / 2);

    for (int index = 0; index < (int)_dotNormalViews.count; index++)
    {
        ((UIView *)_dotNormalViews[index]).frame = CGRectMake(startX + index * (dotSize.width + dotSpacing), 0.0f, dotSize.width, dotSize.height);
        ((UIView *)_dotHighlightedViews[index]).frame = ((UIView *)_dotNormalViews[index]).frame;
    }
}

@end
