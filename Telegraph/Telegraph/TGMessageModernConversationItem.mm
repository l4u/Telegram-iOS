#import "TGMessageModernConversationItem.h"

#import "NSObject+TGLock.h"

#import "TGUser.h"
#import "TGMessage.h"
#import "TGMessageViewModel.h"
#import "TGPhotoMessageViewModel.h"
#import "TGVideoMessageViewModel.h"
#import "TGMapMessageViewModel.h"
#import "TGContactMessageViewModel.h"
#import "TGDocumentMessageViewModel.h"
#import "TGNotificationMessageViewModel.h"
#import "TGAudioMessageViewModel.h"
#import "TGAnimatedImageMessageViewModel.h"
#import "TGYoutubeMessageViewModel.h"
#import "TGInstagramMessageViewModel.h"
#import "TGStickerMessageViewModel.h"

#import "TGPreparedLocalDocumentMessage.h"

#import "TGTextMessageModernViewModel.h"

#import "TGModernCollectionCell.h"

#import "TGInterfaceAssets.h"
#import "TGImageUtils.h"

#import <map>
#import <CommonCrypto/CommonDigest.h>

typedef enum {
    TGCachedMessageTypeUnknown = 0,
    TGCachedMessageTypeText = 1,
    TGCachedMessageTypeImage = 2,
    TGCachedMessageTypeNotification = 3
} TGCachedMessageType;

int32_t TGMessageModernConversationItemLocalUserId = 0;

static UIColor *coloredNameForUid(int uid, __unused int currentUserId)
{
    return [[TGInterfaceAssets instance] userColor:uid];
}

@interface TGMessageModernConversationItem () <TGModernCollectionRelativeBoundsObserver>
{
    TGMessageViewModel *_viewModel;
    TGModernViewContext *_context;
    
    TGCachedMessageType _cachedMessageType;
    bool _layoutIsInvalid;
}

@end

@implementation TGMessageModernConversationItem

- (instancetype)initWithMessage:(TGMessage *)message context:(TGModernViewContext *)context
{
    self = [super init];
    if (self != nil)
    {
        _message = message;
        _context = context;
        
        _mediaAvailabilityStatus = true;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)__unused zone
{
    TGMessageModernConversationItem *copyItem = [[TGMessageModernConversationItem alloc] initWithMessage:_message context:_context];
    copyItem->_viewModel = _viewModel;
    copyItem->_author = _author;
    copyItem->_additionalUsers = _additionalUsers;
    copyItem->_additionalDate = _additionalDate;
    copyItem->_collapseFlags = _collapseFlags;
    copyItem->_cachedMessageType = _cachedMessageType;
    copyItem->_mediaAvailabilityStatus = _mediaAvailabilityStatus;
    return copyItem;
}

- (id)deepCopy
{
    TGMessageModernConversationItem *copyItem = [[TGMessageModernConversationItem alloc] initWithMessage:[_message copy] context:_context];
    copyItem->_viewModel = _viewModel;
    copyItem->_author = _author;
    copyItem->_additionalUsers = _additionalUsers;
    copyItem->_additionalDate = _additionalDate;
    copyItem->_collapseFlags = _collapseFlags;
    copyItem->_cachedMessageType = _cachedMessageType;
    copyItem->_mediaAvailabilityStatus = _mediaAvailabilityStatus;
    return copyItem;
}

- (Class)cellClass
{
    return [TGModernCollectionCell class];
}

- (void)bindCell:(TGModernCollectionCell *)cell viewStorage:(TGModernViewStorage *)viewStorage
{
    [super bindCell:cell viewStorage:viewStorage];
    
    if (cell != nil)
        cell->_needsRelativeBoundsUpdateNotifications = _viewModel.needsRelativeBoundsUpdates;
    
    [_viewModel bindViewToContainer:[cell contentViewForBinding] viewStorage:viewStorage];
}

- (void)unbindCell:(TGModernViewStorage *)viewStorage
{
    [_viewModel unbindView:viewStorage];
    
    [super unbindCell:viewStorage];
}

- (void)moveToCell:(TGModernCollectionCell *)cell
{
    [super moveToCell:cell];
    
    if ([self boundCell] == cell)
    {
        [_viewModel moveViewToContainer:[cell contentViewForBinding]];
        
        if (cell != nil)
            cell->_needsRelativeBoundsUpdateNotifications = _viewModel.needsRelativeBoundsUpdates;
    }
}

- (void)temporaryMoveToView:(UIView *)view
{
    [_viewModel moveViewToContainer:view];
    
    [super temporaryMoveToView:view];
}

- (void)drawInContext:(CGContextRef)context
{
    [_viewModel drawInContext:context];
}

- (void)relativeBoundsUpdated:(TGModernCollectionCell *)cell bounds:(CGRect)bounds
{
    if (cell == [self boundCell])
    {
        if ([_viewModel needsRelativeBoundsUpdates])
            [_viewModel relativeBoundsUpdated:bounds];
    }
}

- (void)updateAssets
{
    [_viewModel updateAssets];
}

- (void)refreshMetrics
{
    _layoutIsInvalid = true;
    
    [_viewModel refreshMetrics];
}

- (void)updateMessage:(TGMessage *)message viewStorage:(TGModernViewStorage *)viewStorage
{
    [_viewModel updateMessage:message viewStorage:viewStorage];
}

- (void)updateMediaVisibility
{
    [_viewModel updateMediaVisibility];
}

- (void)updateMessageAttributes
{
    [_viewModel updateMessageAttributes];
}

- (void)updateEditingState:(TGModernViewStorage *)viewStorage animationDelay:(NSTimeInterval)animationDelay
{
    [_viewModel updateEditingState:[[self boundCell] contentViewForBinding] viewStorage:viewStorage animationDelay:animationDelay];
}

- (void)imageDataInvalidated:(NSString *)imageUrl
{
    [_viewModel imageDataInvalidated:imageUrl];
}

- (void)setTemporaryHighlighted:(bool)temporaryHighlighted viewStorage:(TGModernViewStorage *)viewStorage
{
    [_viewModel setTemporaryHighlighted:temporaryHighlighted viewStorage:viewStorage];
}

- (CGRect)effectiveContentFrame
{
    return [_viewModel effectiveContentFrame];
}

- (UIView *)referenceViewForImageTransition
{
    return [_viewModel referenceViewForImageTransition];
}

- (void)collectBoundModelViewFramesRecursively:(NSMutableDictionary *)dict
{
    [_viewModel collectBoundModelViewFramesRecursively:dict];
}

- (void)collectBoundModelViewFramesRecursively:(NSMutableDictionary *)dict ifPresentInDict:(NSMutableDictionary *)anotherDict
{
    [_viewModel collectBoundModelViewFramesRecursively:dict ifPresentInDict:anotherDict];
}

- (void)restoreBoundModelViewFramesRecursively:(NSMutableDictionary *)dict
{
    [_viewModel restoreBoundModelViewFramesRecursively:dict];
}

- (TGModernViewModel *)viewModel
{
    return _viewModel;
}

- (TGModernViewModel *)viewModelForContainerSize:(CGSize)containerSize
{
    bool updateCell = false;
    
    if (_viewModel == nil)
    {
        _viewModel = [self createMessageViewModel:_message containerSize:containerSize];
        [_viewModel updateMediaAvailability:_mediaAvailabilityStatus viewStorage:nil];
        updateCell = true;
    }
    else if (ABS(_viewModel.frame.size.width - containerSize.width) > FLT_EPSILON || _viewModel.collapseFlags != _collapseFlags || _layoutIsInvalid)
    {
        _layoutIsInvalid = false;
        
        _viewModel.collapseFlags = _collapseFlags;
        [_viewModel layoutForContainerSize:containerSize];
        updateCell = true;
    }
    
    if (updateCell)
    {
        if ([self boundCell] != nil)
            [self boundCell]->_needsRelativeBoundsUpdateNotifications = _viewModel.needsRelativeBoundsUpdates;
    }
    
    return _viewModel;
}

- (CGSize)sizeForContainerSize:(CGSize)containerSize
{
    return CGSizeMake(containerSize.width, [self viewModelForContainerSize:containerSize].frame.size.height);
}

- (void)updateToItem:(TGMessageModernConversationItem *)updatedItem viewStorage:(TGModernViewStorage *)viewStorage
{
    if ([updatedItem isKindOfClass:[TGMessageModernConversationItem class]])
    {
        if (_message != updatedItem->_message) // by reference
        {
            _message = updatedItem->_message;
            [self updateMessage:_message viewStorage:viewStorage];
        }
        
        if (_mediaAvailabilityStatus != updatedItem->_mediaAvailabilityStatus)
        {
            _mediaAvailabilityStatus = updatedItem->_mediaAvailabilityStatus;
            [_viewModel updateMediaAvailability:_mediaAvailabilityStatus viewStorage:viewStorage];
        }
    }
}

- (void)updateProgress:(float)progress viewStorage:(TGModernViewStorage *)viewStorage animated:(bool)animated
{
    [_viewModel updateProgress:progress > -FLT_EPSILON progress:MAX(0.0f, progress) viewStorage:viewStorage animated:animated];
}

- (void)updateInlineMediaContext
{
    [_viewModel updateInlineMediaContext];
}

- (void)updateAnimationsEnabled
{
    [_viewModel updateAnimationsEnabled];
}

- (void)stopInlineMedia
{
    [_viewModel stopInlineMedia];
}

- (void)bindSpecialViewsToContainer:(UIView *)container viewStorage:(TGModernViewStorage *)viewStorage atItemPosition:(CGPoint)itemPosition
{
    [_viewModel bindSpecialViewsToContainer:container viewStorage:viewStorage atItemPosition:itemPosition];
}

- (NSDictionary *)parseMimeArguments:(NSString *)string
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    NSUInteger rangeStart = 0;
    while (rangeStart < string.length && rangeStart != NSNotFound)
    {
        NSUInteger rangeEnd = [string rangeOfString:@";" options:0 range:NSMakeRange(rangeStart, string.length - rangeStart)].location;
        NSString *pairString = nil;
        if (rangeEnd == NSNotFound)
        {
            pairString = [string substringWithRange:NSMakeRange(rangeStart, string.length - rangeStart)];
            rangeStart = rangeEnd;
        }
        else
        {
            pairString = [string substringWithRange:NSMakeRange(rangeStart, rangeEnd - rangeStart)];
            rangeStart = rangeEnd + 1;
        }
        
        pairString = [pairString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if (pairString.length != 0)
        {
            NSUInteger eqRange = [pairString rangeOfString:@"="].location;
            if (eqRange != NSNotFound)
            {
                NSString *key = [[pairString substringWithRange:NSMakeRange(0, eqRange)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *value = [[pairString substringWithRange:NSMakeRange(eqRange + 1, pairString.length - eqRange - 1)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                dict[key] = value;
            }
        }
    }
    
    return dict;
}

- (TGMessageViewModel *)createMessageViewModel:(TGMessage *)message containerSize:(CGSize)containerSize
{
    bool useAuthor = _author != nil && !message.outgoing;
    
    int forwardIndex = -1;
    int contactIndex = -1;
    int32_t contactUid = 0;
    bool unsupportedMessage = false;
    
    if (message.mediaAttachments.count != 0)
    {
        int index = -1;
        for (TGMediaAttachment *attachment in message.mediaAttachments)
        {
            index++;
            
            if (attachment.type == TGForwardedMessageMediaAttachmentType)
            {
                forwardIndex = index;
                
                break;
            }
        }
        
        index = -1;
        for (TGMediaAttachment *attachment in message.mediaAttachments)
        {
            index++;
            
            switch (attachment.type)
            {
                case TGImageMediaAttachmentType:
                {
                    TGPhotoMessageViewModel *model = [[TGPhotoMessageViewModel alloc] initWithMessage:message imageMedia:(TGImageMediaAttachment *)attachment author:useAuthor ? _author : nil context:_context];
                    if (useAuthor)
                        [model setAuthorAvatarUrl:_author.photoUrlSmall];
                    model.collapseFlags = _collapseFlags;
                    [model layoutForContainerSize:containerSize];
                    return model;
                }
                case TGVideoMediaAttachmentType:
                {
                    TGVideoMessageViewModel *model = [[TGVideoMessageViewModel alloc] initWithMessage:message imageInfo:((TGVideoMediaAttachment *)attachment).thumbnailInfo video:(TGVideoMediaAttachment *)attachment author:useAuthor ? _author : nil context:_context];
                    if (useAuthor)
                        [model setAuthorAvatarUrl:_author.photoUrlSmall];
                    model.collapseFlags = _collapseFlags;
                    [model layoutForContainerSize:containerSize];
                    return model;
                }
                case TGLocationMediaAttachmentType:
                {
                    TGMapMessageViewModel *model = [[TGMapMessageViewModel alloc] initWithLatitude:((TGLocationMediaAttachment *)attachment).latitude longitude:((TGLocationMediaAttachment *)attachment).longitude message:message author:useAuthor ? _author : nil context:_context];
                    if (useAuthor)
                        [model setAuthorAvatarUrl:_author.photoUrlSmall];
                    model.collapseFlags = _collapseFlags;
                    [model layoutForContainerSize:containerSize];
                    return model;
                }
                case TGContactMediaAttachmentType:
                {
                    contactIndex = index;
                    contactUid = ((TGContactMediaAttachment *)attachment).uid;
                    break;
                }
                case TGActionMediaAttachmentType:
                {
                    TGNotificationMessageViewModel *model = [[TGNotificationMessageViewModel alloc] initWithMessage:_message actionMedia:(TGActionMediaAttachment *)attachment author:_author additionalUsers:_additionalUsers context:_context];
                    model.collapseFlags = _collapseFlags;
                    [model layoutForContainerSize:containerSize];
                    return model;
                }
                case TGDocumentMediaAttachmentType:
                {
                    TGDocumentMediaAttachment *documentAttachment = (TGDocumentMediaAttachment *)attachment;
                    
                    bool isAnimated = false;
                    CGSize imageSize = CGSizeZero;
                    bool isSticker = false;
                    for (id attribute in documentAttachment.attributes)
                    {
                        if ([attribute isKindOfClass:[TGDocumentAttributeAnimated class]])
                        {
                            isAnimated = true;
                        }
                        else if ([attribute isKindOfClass:[TGDocumentAttributeImageSize class]])
                        {
                            imageSize = ((TGDocumentAttributeImageSize *)attribute).size;
                        }
                        else if ([attribute isKindOfClass:[TGDocumentAttributeSticker class]])
                        {
                            isSticker = true;
                        }
                    }
                    
                    if (isSticker)
                    {
                        if (imageSize.width <= FLT_EPSILON || imageSize.height <= FLT_EPSILON)
                        {
                            CGSize size = CGSizeZero;
                            [documentAttachment.thumbnailInfo imageUrlForLargestSize:&size];
                            if (size.width > FLT_EPSILON && size.height > FLT_EPSILON)
                            {
                                imageSize = TGFillSize(TGFitSize(size, CGSizeMake(512.0f, 512.0f)), CGSizeMake(512.0f, 512.0f));
                            }
                            else
                                imageSize = CGSizeMake(512.0f, 512.0f);
                        }
                        
                        if (imageSize.width > FLT_EPSILON && imageSize.height > FLT_EPSILON)
                        {
                            TGStickerMessageViewModel *model = [[TGStickerMessageViewModel alloc] initWithMessage:_message document:documentAttachment size:imageSize author:useAuthor ? _author : nil context:_context];
                            if (useAuthor)
                                [model setAuthorAvatarUrl:_author.photoUrlSmall];
                            model.collapseFlags = _collapseFlags;
                            [model layoutForContainerSize:containerSize];
                            return model;
                        }
                    }
                    
                    if ((isAnimated || [documentAttachment.mimeType isEqualToString:@"image/gif"]) && ((imageSize.width > FLT_EPSILON && imageSize.height > FLT_EPSILON) || (documentAttachment.thumbnailInfo != nil && ![documentAttachment.thumbnailInfo empty])))
                    {
                        TGAnimatedImageMessageViewModel *model = [[TGAnimatedImageMessageViewModel alloc] initWithMessage:_message imageInfo:documentAttachment.thumbnailInfo document:documentAttachment author:useAuthor ? _author : nil context:_context];
                        if (useAuthor)
                            [model setAuthorAvatarUrl:_author.photoUrlSmall];
                        model.collapseFlags = _collapseFlags;
                        [model layoutForContainerSize:containerSize];
                        return model;
                    }
                    
                    if ([documentAttachment.mimeType isEqualToString:@"audio/mpeg"])
                    {
                        TGAudioMessageViewModel *model = [[TGAudioMessageViewModel alloc] initWithMessage:_message duration:0 size:documentAttachment.size fileType:[documentAttachment.fileName pathExtension] author:useAuthor ? _author : nil context:_context];
                        if (useAuthor)
                        {
                            [model setAuthorNameColor:coloredNameForUid(_author.uid, TGMessageModernConversationItemLocalUserId)];
                            [model setAuthorAvatarUrl:_author.photoUrlSmall];
                        }
                        if (forwardIndex != -1)
                        {
                            TGForwardedMessageMediaAttachment *forwardAttachment = message.mediaAttachments[forwardIndex];
                            int forwardUid = forwardAttachment.forwardUid;
                            TGUser *forwardUser = nil;
                            for (TGUser *user in _additionalUsers)
                            {
                                if (user.uid == forwardUid)
                                {
                                    forwardUser = user;
                                    break;
                                }
                            }
                            [model setForwardHeader:forwardUser];
                        }
                        model.collapseFlags = _collapseFlags;
                        [model layoutForContainerSize:containerSize];
                        return model;
                    }
                    
                    TGDocumentMessageViewModel *model = [[TGDocumentMessageViewModel alloc] initWithMessage:_message document:(TGDocumentMediaAttachment *)attachment author:useAuthor ? _author : nil context:_context];
                    if (useAuthor)
                    {
                        [model setAuthorNameColor:coloredNameForUid(_author.uid, TGMessageModernConversationItemLocalUserId)];
                        [model setAuthorAvatarUrl:_author.photoUrlSmall];
                    }
                    
                    if (forwardIndex != -1)
                    {
                        TGForwardedMessageMediaAttachment *forwardAttachment = message.mediaAttachments[forwardIndex];
                        int forwardUid = forwardAttachment.forwardUid;
                        TGUser *forwardUser = nil;
                        for (TGUser *user in _additionalUsers)
                        {
                            if (user.uid == forwardUid)
                            {
                                forwardUser = user;
                                break;
                            }
                        }
                        [model setForwardHeader:forwardUser];
                    }
                    
                    model.collapseFlags = _collapseFlags;
                    [model layoutForContainerSize:containerSize];
                    return model;
                }
                case TGAudioMediaAttachmentType:
                {
                    TGAudioMessageViewModel *model = [[TGAudioMessageViewModel alloc] initWithMessage:_message duration:((TGAudioMediaAttachment *)attachment).duration size:((TGAudioMediaAttachment *)attachment).fileSize fileType:@"" author:useAuthor ? _author : nil context:_context];
                    if (useAuthor)
                    {
                        [model setAuthorNameColor:coloredNameForUid(_author.uid, TGMessageModernConversationItemLocalUserId)];
                        [model setAuthorAvatarUrl:_author.photoUrlSmall];
                    }
                    if (forwardIndex != -1)
                    {
                        TGForwardedMessageMediaAttachment *forwardAttachment = message.mediaAttachments[forwardIndex];
                        int forwardUid = forwardAttachment.forwardUid;
                        TGUser *forwardUser = nil;
                        for (TGUser *user in _additionalUsers)
                        {
                            if (user.uid == forwardUid)
                            {
                                forwardUser = user;
                                break;
                            }
                        }
                        [model setForwardHeader:forwardUser];
                    }
                    model.collapseFlags = _collapseFlags;
                    [model layoutForContainerSize:containerSize];
                    return model;
                }
                case TGUnsupportedMediaAttachmentType:
                {
                    unsupportedMessage = true;
                    break;
                }
                default:
                    break;
            }
        }
    }
    
    if (contactIndex != -1)
    {
        TGUser *contactUser = nil;
        for (TGUser *user in _additionalUsers)
        {
            if (user.uid == contactUid)
            {
                contactUser = user;
                break;
            }
        }
        
        TGContactMessageViewModel *model = [[TGContactMessageViewModel alloc] initWithMessage:_message contact:contactUser author:useAuthor ? _author : nil context:_context];
        
        if (contactUser != nil)
        {
            if (forwardIndex != -1)
            {
                TGForwardedMessageMediaAttachment *forwardAttachment = message.mediaAttachments[forwardIndex];
                int forwardUid = forwardAttachment.forwardUid;
                TGUser *forwardUser = nil;
                for (TGUser *user in _additionalUsers)
                {
                    if (user.uid == forwardUid)
                    {
                        forwardUser = user;
                        break;
                    }
                }
                [model setForwardHeader:forwardUser];
            }
        }
        if (useAuthor)
        {
            [model setAuthorNameColor:coloredNameForUid(_author.uid, TGMessageModernConversationItemLocalUserId)];
            [model setAuthorAvatarUrl:_author.photoUrlSmall];
        }
        
        model.collapseFlags = _collapseFlags;
        [model layoutForContainerSize:containerSize];
        return model;
    }
    
    
    if ([message.text hasPrefix:@"http://youtu.be/"])
    {
        TGYoutubeMessageViewModel *model = [[TGYoutubeMessageViewModel alloc] initWithVideoId:[message.text substringFromIndex:@"http://youtu.be/".length] message:message author:useAuthor ? _author : nil context:_context];
        if (useAuthor)
            [model setAuthorAvatarUrl:_author.photoUrlSmall];
        model.collapseFlags = _collapseFlags;
        [model layoutForContainerSize:containerSize];
        return model;
    }
    
    if ([message.text hasPrefix:@"http://www.youtube.com/watch?v="] || [message.text hasPrefix:@"https://www.youtube.com/watch?v="])
    {
        NSRange range1 = [message.text rangeOfString:@"?v="];
        bool match = true;
        for (NSInteger i = range1.location + range1.length; i < (NSInteger)message.text.length; i++)
        {
            unichar c = [message.text characterAtIndex:i];
            if (!((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '-' || c == '=' || c == '&' || c == '#'))
            {
                match = false;
                break;
            }
        }
        
        if (match)
        {
            NSString *videoId = nil;
            NSRange ampRange = [message.text rangeOfString:@"&"];
            NSRange hashRange = [message.text rangeOfString:@"#"];
            if (ampRange.location != NSNotFound || hashRange.location != NSNotFound)
            {
                NSInteger location = MIN(ampRange.location, hashRange.location);
                videoId = [message.text substringWithRange:NSMakeRange(range1.location + range1.length, location - range1.location - range1.length)];
            }
            else
                videoId = [message.text substringFromIndex:range1.location + range1.length];
            
            if (videoId.length != 0)
            {
                TGYoutubeMessageViewModel *model = [[TGYoutubeMessageViewModel alloc] initWithVideoId:videoId message:message author:useAuthor ? _author : nil context:_context];
                if (useAuthor)
                    [model setAuthorAvatarUrl:_author.photoUrlSmall];
                model.collapseFlags = _collapseFlags;
                [model layoutForContainerSize:containerSize];
                return model;
            }
        }
    }
    
    if ([message.text hasPrefix:@"http://instagram.com/p/"])
    {
        int length = message.text.length;
        bool badCharacters = false;
        bool foundOneSlash = false;
        for (int i = @"http://instagram.com/p/".length; i < length; i++)
        {
            unichar c = [message.text characterAtIndex:i];
            if ((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_' || c == '/')
            {
                if (c == '/')
                {
                    if (foundOneSlash)
                    {
                        badCharacters = true;
                        break;
                    }
                    foundOneSlash = true;
                }
            }
            else
            {
                badCharacters = true;
                break;
            }
        }
        
        if (!badCharacters)
        {
            NSString *shortcode = [message.text substringFromIndex:@"http://instagram.com/p/".length];
            if ([shortcode hasSuffix:@"/"])
                shortcode = [shortcode substringToIndex:shortcode.length - 1];
            
            TGInstagramMessageViewModel *model = [[TGInstagramMessageViewModel alloc] initWithShortcode:shortcode message:message author:useAuthor ? _author : nil context:_context];
            if (useAuthor)
                [model setAuthorAvatarUrl:_author.photoUrlSmall];
            model.collapseFlags = _collapseFlags;
            [model layoutForContainerSize:containerSize];
            return model;
        }
    }
    
    /*if ([message.text hasPrefix:@"https://twitter.com/"])
    {
        NSRange range1 = [message.text rangeOfString:@"/status/"];
        if (range1.location != NSNotFound)
        {
            bool match = true;
            for (NSInteger i = range1.location + range1.length; i < (NSInteger)message.text.length; i++)
            {
                unichar c = [message.text characterAtIndex:i];
                if (!(c >= '0' && c <= '9'))
                {
                    match = false;
                    break;
                }
            }
            
            if (match)
            {
                NSRange range0 = [message.text rangeOfString:@"twitter.com/"];
                NSString *userName = [message.text substringWithRange:NSMakeRange(range0.location + range0.length, range1.location - range0.location - range0.length)];
                NSString *statusId = [message.text substringFromIndex:range1.location + range1.length];
                
            }
        }
    }*/
    
    TGTextMessageModernViewModel *model = [[TGTextMessageModernViewModel alloc] initWithMessage:message author:useAuthor ? _author : nil context:_context];
    if (unsupportedMessage)
        [model setIsUnsupported:true];
    
    if (forwardIndex != -1)
    {
        TGForwardedMessageMediaAttachment *forwardAttachment = message.mediaAttachments[forwardIndex];
        int forwardUid = forwardAttachment.forwardUid;
        TGUser *forwardUser = nil;
        for (TGUser *user in _additionalUsers)
        {
            if (user.uid == forwardUid)
            {
                forwardUser = user;
                break;
            }
        }
        [model setForwardHeader:forwardUser];
    }
    if (useAuthor)
    {
        [model setAuthorNameColor:coloredNameForUid(_author.uid, TGMessageModernConversationItemLocalUserId)];
        [model setAuthorAvatarUrl:_author.photoUrlSmall];
    }
    model.collapseFlags = _collapseFlags;
    [model layoutForContainerSize:containerSize];
    return model;
}

static inline TGCachedMessageType getMessageType(TGMessageModernConversationItem *item)
{
    if (item->_cachedMessageType == TGCachedMessageTypeUnknown)
    {
        if (item->_message.mediaAttachments.count != 0)
        {
            int index = -1;
            for (TGMediaAttachment *attachment in item->_message.mediaAttachments)
            {
                index++;
                
                switch (attachment.type)
                {
                    case TGImageMediaAttachmentType:
                    case TGVideoMediaAttachmentType:
                    case TGLocationMediaAttachmentType:
                    {
                        item->_cachedMessageType = TGCachedMessageTypeImage;
                        return item->_cachedMessageType;
                    }
                    case TGActionMediaAttachmentType:
                    {
                        item->_cachedMessageType = TGCachedMessageTypeNotification;
                        return item->_cachedMessageType;
                    }
                    default:
                        break;
                }
            }
        }
        
        item->_cachedMessageType = TGCachedMessageTypeText;
        return item->_cachedMessageType;
    }
    
    return item->_cachedMessageType;
}

- (bool)collapseWithItem:(TGMessageModernConversationItem *)item forContainerSize:(CGSize)__unused containerSize
{
    if (item->_message.outgoing == _message.outgoing)
    {
        if (!item->_message.outgoing && item->_author != nil)
            return false;
        
        TGCachedMessageType currentType = getMessageType(self);
        TGCachedMessageType anotherType = getMessageType(item);
        
        if ((currentType == TGCachedMessageTypeText || currentType == TGCachedMessageTypeImage) == (anotherType == TGCachedMessageTypeText || anotherType == TGCachedMessageTypeImage))
        {
            if (!_message.outgoing && (_message.fromUid != item->_message.fromUid))
                return false;
            return true;
        }
    }
    
    return false;
}

@end

