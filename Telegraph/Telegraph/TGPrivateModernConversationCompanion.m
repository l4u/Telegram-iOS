#import "TGPrivateModernConversationCompanion.h"

#import "TGDatabase.h"
#import "TGDateUtils.h"
#import "TGStringUtils.h"
#import "TGPhoneUtils.h"

#import "ActionStage.h"
#import "SGraphObjectNode.h"

#import "TGAppDelegate.h"
#import "TGTelegraph.h"
#import "TGPopoverController.h"

#import "TGInterfaceManager.h"
#import "TGNavigationBar.h"
#import "TGTelegraphUserInfoController.h"

#import "TGModernConversationController.h"
#import "TGModernConversationActionInputPanel.h"
#import "TGModernConversationPrivateTitlePanel.h"
#import "TGModernConversationContactLinkTitlePanel.h"

#import "TGModernConversationTitleIcon.h"

#import "TGModernConversationTitleView.h"

typedef enum {
    TGPhoneSharingStatusUnknown = 0,
    TGPhoneSharingStatusNotShared = 1,
    TGPhoneSharingStatusMyShared = 2
} TGPhoneSharingStatus;

static NSMutableDictionary *dismissedContactLinkPanelsByUserId()
{
    static NSMutableDictionary *dict = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

@interface TGPrivateModernConversationCompanion () <TGModernConversationContactLinkTitlePanelDelegate>
{
    NSString *_initialActivity;
    
    NSString *_cachedPhone;
    
    bool _hasUnblockPanel;
    
    bool _isBlocked; // Main Thread
    bool _isContact; // Main Thread
    
    bool _isMuted; // Main Thread
    
    NSArray *_additionalTitleIcons; // Main Thread
    
    TGPhoneSharingStatus _phoneSharingStatus; // Main Thread
}

@end

@implementation TGPrivateModernConversationCompanion

- (instancetype)initWithUid:(int)uid activity:(NSString *)activity mayHaveUnreadMessages:(bool)mayHaveUnreadMessages
{
    return [self initWithConversationId:uid uid:uid activity:activity mayHaveUnreadMessages:mayHaveUnreadMessages];
}

- (instancetype)initWithConversationId:(int64_t)conversationId uid:(int)uid activity:(NSString *)activity mayHaveUnreadMessages:(bool)mayHaveUnreadMessages
{
    self = [super initWithConversationId:conversationId mayHaveUnreadMessages:mayHaveUnreadMessages];
    if (self != nil)
    {
        _uid = uid;
        _initialActivity = activity;
    }
    return self;
}

- (void)setAdditionalTitleIcons:(NSArray *)additionalTitleIcons
{
    TGDispatchOnMainThread(^
    {
        _additionalTitleIcons = additionalTitleIcons;
        [self _updateTitleIcons];
    });
}

- (bool)shouldDisplayContactLinkPanel
{
    return true;
}

- (void)_updateTitleIcons
{
    TGDispatchOnMainThread(^
    {
        NSMutableArray *icons = [[NSMutableArray alloc] initWithArray:_additionalTitleIcons];
        
        if (_isMuted)
        {
            TGModernConversationTitleIcon *muteIcon = [[TGModernConversationTitleIcon alloc] init];
            muteIcon.bounds = CGRectMake(0.0f, 0.0f, 16, 16);
            muteIcon.offsetWeight = 0.5f;
            muteIcon.imageOffset = CGPointMake(4.0f, 7.0f);
            
            static UIImage *muteImage = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^
            {
                muteImage = [UIImage imageNamed:@"ModernConversationTitleIconMute.png"];
            });
            
            muteIcon.image = muteImage;
            muteIcon.iconPosition = TGModernConversationTitleIconPositionAfterTitle;
            
            [icons addObject:muteIcon];
        }
        
        [self _setTitleIcons:icons];
    });
}

- (void)_updateUserMute:(bool)isMuted
{
    TGDispatchOnMainThread(^
    {
        if (_isMuted != isMuted)
        {
            _isMuted = isMuted;
            [self _updateTitleIcons];
        }
    });
}

- (void)_updatePhoneSharingStatusFromUserLink:(int)userLink
{
    TGDispatchOnMainThread(^
    {
        TGPhoneSharingStatus phoneSharingStatus = TGPhoneSharingStatusUnknown;
        if (userLink & TGUserLinkKnown)
        {
            if (userLink & (TGUserLinkForeignHasPhone | TGUserLinkForeignMutual | TGUserLinkMyRequested))
                phoneSharingStatus = TGPhoneSharingStatusMyShared;
            else
                phoneSharingStatus = TGPhoneSharingStatusNotShared;
        }
        
        if (phoneSharingStatus != _phoneSharingStatus)
        {
            _phoneSharingStatus = phoneSharingStatus;
            [self _updateContactLinkPanel];
        }
    });
}

- (void)_updateContactLinkPanel
{
    TGDispatchOnMainThread(^
    {
        if (![self shouldDisplayContactLinkPanel])
            return;
        
        TGModernConversationController *controller = self.controller;
        
        TGModernConversationContactLinkTitlePanel *panel = [controller.secondaryTitlePanel isKindOfClass:[TGModernConversationContactLinkTitlePanel class]] ? (TGModernConversationContactLinkTitlePanel *)controller.secondaryTitlePanel : nil;
        TGUser *user = [TGDatabaseInstance() loadUser:_uid];
        
        if ((_phoneSharingStatus == TGPhoneSharingStatusNotShared || (!_isContact && user.phoneNumber.length != 0)))
        {
            bool shareContact = _isContact || _phoneSharingStatus == TGPhoneSharingStatusNotShared;
            
            NSMutableDictionary *dict = dismissedContactLinkPanelsByUserId()[@(TGTelegraphInstance.clientUserId)];
            if (dict == nil)
            {
                dict = [[NSMutableDictionary alloc] init];
                dismissedContactLinkPanelsByUserId()[@(TGTelegraphInstance.clientUserId)] = dict;
            }
            if (![dict[[[NSString alloc] initWithFormat:@"%" PRId32 "_%@", _uid, shareContact ? @"share" : @"add"]] boolValue])
            {
                if (panel == nil)
                {
                    panel = [[TGModernConversationContactLinkTitlePanel alloc] init];
                    panel.delegate = self;
                }
                
                [panel setShareContact:shareContact];
            }
        }
        else
            panel = nil;
        
        [controller setSecondaryTitlePanel:panel];
    });
}

- (void)contactLinkTitlePanelShareContactPressed:(TGModernConversationContactLinkTitlePanel *)panel
{
    [self contactLinkTitlePanelDismissed:panel];
    
    [self shareVCard];
}

- (void)contactLinkTitlePanelAddContactPressed:(TGModernConversationContactLinkTitlePanel *)__unused panel
{
    TGUser *contact = [TGDatabaseInstance() loadUser:_uid];
    TGDispatchOnMainThread(^
    {
        if (contact != nil)
        {
            TGModernConversationController *controller = self.controller;
            [controller showAddContactMenu:contact];
        }
    });
}

- (void)contactLinkTitlePanelDismissed:(TGModernConversationContactLinkTitlePanel *)panel
{
    TGDispatchOnMainThread(^
    {
        NSMutableDictionary *dict = dismissedContactLinkPanelsByUserId()[@(TGTelegraphInstance.clientUserId)];
        if (dict == nil)
        {
            dict = [[NSMutableDictionary alloc] init];
            dismissedContactLinkPanelsByUserId()[@(TGTelegraphInstance.clientUserId)] = dict;
        }
        dict[[[NSString alloc] initWithFormat:@"%" PRId32 "_%@", _uid, panel.shareContact ? @"share" : @"add"]] = @(true);
        
        TGModernConversationController *controller = self.controller;
        [controller setSecondaryTitlePanel:nil];
    });
}

#pragma mark -

- (void)_controllerWillAppearAnimated:(bool)animated firstTime:(bool)firstTime
{
    [super _controllerWillAppearAnimated:animated firstTime:firstTime];
    
    if (firstTime)
    {
        [ActionStageInstance() dispatchOnStageQueue:^
        {
            [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/blockedUsers/(%" PRId32 ",cached)", _uid] options:@{@"uid": @(_uid)} watcher:self];
            [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/completeUsers/(%" PRId32 ",cached)", _uid] options:@{@"uid": @(_uid)} watcher:TGTelegraphInstance];
        }];
        
        [TGDatabaseInstance() dispatchOnDatabaseThread:^
        {
            bool outdated = false;
            int userLink = [TGDatabaseInstance() loadUserLink:_uid outdated:&outdated];
            [self _updatePhoneSharingStatusFromUserLink:userLink];
        } synchronous:false];
    }
}

#pragma mark -

- (void)_controllerAvatarPressed
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        [[TGInterfaceManager instance] navigateToProfileOfUser:_uid];
    else
    {
        TGModernConversationController *controller = self.controller;
        if (controller != nil)
        {
            TGTelegraphUserInfoController *userInfoController = [[TGTelegraphUserInfoController alloc] initWithUid:_uid];
            
            TGNavigationController *navigationController = [TGNavigationController navigationControllerWithControllers:@[userInfoController] navigationBarClass:[TGWhiteNavigationBar class]];
            navigationController.presentationStyle = TGNavigationControllerPresentationStyleRootInPopover;
            TGPopoverController *popoverController = [[TGPopoverController alloc] initWithContentViewController:navigationController];
            navigationController.parentPopoverController = popoverController;
            [popoverController setContentSize:CGSizeMake(320.0f, 528.0f)];

            controller.associatedPopoverController = popoverController;
            [popoverController presentPopoverFromBarButtonItem:controller.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:true];
            userInfoController.collectionView.contentOffset = CGPointMake(0.0f, -userInfoController.collectionView.contentInset.top);
        }
    }
}

- (NSString *)stringForTitle:(TGUser *)user isContact:(bool)isContact
{
    if (user.uid == [TGTelegraphInstance serviceUserUid])
        return @"Telegram Notifications";
    
    if (isContact || user.phoneNumber.length == 0)
        return user.displayName;
    
    if (_cachedPhone == nil)
        _cachedPhone = [TGPhoneUtils formatPhone:user.phoneNumber forceInternational:true];
    
    return _cachedPhone;
}

- (NSString *)statusStringForUser:(TGUser *)user accentColored:(bool *)accentColored
{
    if (user.uid == [TGTelegraphInstance serviceUserUid])
        return @"Service notifications";
    
    if (user.presence.online)
    {
        if (accentColored != NULL)
            *accentColored = true;
        return TGLocalizedStatic(@"Presence.online");
    }
    else if (user.presence.lastSeen != 0)
        return [TGDateUtils stringForRelativeLastSeen:user.presence.lastSeen];
    
    return TGLocalized(@"Presence.offline");
}

- (NSString *)stringForActivity:(NSString *)activity
{
    if ([activity isEqualToString:@"recordingAudio"])
        return TGLocalized(@"Activity.RecordingAudio");
    else if ([activity isEqualToString:@"uploadingPhoto"])
        return TGLocalized(@"Activity.UploadingPhoto");
    else if ([activity isEqualToString:@"uploadingVideo"])
        return TGLocalized(@"Activity.UploadingVideo");
    else if ([activity isEqualToString:@"uploadingDocument"])
        return TGLocalized(@"Activity.UploadingDocument");
    else if ([activity isEqualToString:@"pickingLocation"])
        return nil;
        
    return TGLocalized(@"Conversation.typing");
}

- (int)activityTypeForActivity:(NSString *)activity
{
    if ([activity isEqualToString:@"recordingAudio"])
        return TGModernConversationTitleViewActivityAudioRecording;
    else if ([activity isEqualToString:@"uploadingPhoto"])
        return TGModernConversationTitleViewActivityUploading;
    else if ([activity isEqualToString:@"uploadingVideo"])
        return TGModernConversationTitleViewActivityUploading;
    else if ([activity isEqualToString:@"uploadingDocument"])
        return TGModernConversationTitleViewActivityUploading;
    else if ([activity isEqualToString:@"pickingLocation"])
        return 0;
    
    return TGModernConversationTitleViewActivityTyping;
}

- (void)loadInitialState
{
    [super loadInitialState];
    
    TGUser *user = [TGDatabaseInstance() loadUser:_uid];
    _isContact = [TGDatabaseInstance() uidIsRemoteContact:_uid];
    [self _setTitle:[self stringForTitle:user isContact:_isContact]];
    [self _setAvatarConversationId:_uid firstName:user.firstName lastName:user.lastName];
    [self _setAvatarUrl:user.photoUrlSmall];
    bool accentColored = false;
    NSString *statusString = [self statusStringForUser:user accentColored:&accentColored];
    [self _setStatus:statusString accentColored:accentColored allowAnimation:false];
    
    if (_initialActivity != nil)
        [self _setTypingStatus:[self stringForActivity:_initialActivity] activity:[self activityTypeForActivity:_initialActivity]];
}

#pragma mark -

- (bool)imageDownloadsShouldAutosavePhotos
{
    return TGAppDelegateInstance.autosavePhotos;
}

- (bool)shouldAutomaticallyDownloadPhotos
{
    return TGAppDelegateInstance.autoDownloadPhotosInPrivateChats;
}

- (bool)shouldAutomaticallyDownloadAudios
{
    return TGAppDelegateInstance.autoDownloadAudioInPrivateChats;
}

- (NSString *)_sendMessagePathForMessageId:(int32_t)mid
{
    return [[NSString alloc] initWithFormat:@"/tg/sendCommonMessage/(%@)/(%d)", [self _conversationIdPathComponent], mid];
}

- (NSString *)_sendMessagePathPrefix
{
    return [[NSString alloc] initWithFormat:@"/tg/sendCommonMessage/(%@)/", [self _conversationIdPathComponent]];
}

- (NSDictionary *)_optionsForMessageActions
{
    return @{@"conversationId": @(_conversationId)};
}

- (void)subscribeToUpdates
{
    [ActionStageInstance() watchForPaths:@[
        [[NSString alloc] initWithFormat:@"/tg/conversation/(%" PRId64 ")/typing", _conversationId],
        [[NSString alloc] initWithFormat:@"/tg/userLink/(%" PRId32 ")", _uid],
        @"/tg/blockedUsers"
    ] watcher:self];

    [ActionStageInstance() watchForPath:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId32 ")", _uid] watcher:self];
    [ActionStageInstance() requestActor:[NSString stringWithFormat:@"/tg/peerSettings/(%" PRId32 ",cachedOnly)", _uid] options:@{@"peerId": @(_uid)} watcher:self];
    
    [super subscribeToUpdates];
}

#pragma mark -

- (void)_createOrUpdatePrimaryTitlePanel:(bool)createIfNeeded
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        TGModernConversationController *controller = self.controller;
        
        TGModernConversationPrivateTitlePanel *privateTitlePanel = nil;
        if ([[controller primaryTitlePanel] isKindOfClass:[TGModernConversationPrivateTitlePanel class]])
            privateTitlePanel = (TGModernConversationPrivateTitlePanel *)[controller primaryTitlePanel];
        else
        {
            if (createIfNeeded)
            {
                privateTitlePanel = [[TGModernConversationPrivateTitlePanel alloc] init];
                privateTitlePanel.companionHandle = self.actionHandle;
            }
            else
                return;
        }
        
        if (_isContact)
        {
            [privateTitlePanel setButtonsWithTitlesAndActions:@[
                @{@"title": TGLocalized(@"Conversation.Call"), @"action": @"call"},
                @{@"title": TGLocalized(@"Common.Edit"), @"action": @"edit"},
                @{@"title": TGLocalized(@"Conversation.Info"), @"action": @"info"},
            ]];
        }
        else
        {
            NSMutableArray *actions = [[NSMutableArray alloc] init];
            if (_isBlocked)
                [actions addObject:@{@"title": TGLocalized(@"Conversation.Unblock"), @"action": @"unblock"}];
            else
                [actions addObject:@{@"title": TGLocalized(@"Conversation.Block"), @"action": @"block"}];
            [actions addObject:@{@"title": TGLocalized(@"Common.Edit"), @"action": @"edit"}];
            [actions addObject:@{@"title": TGLocalized(@"Conversation.Info"), @"action": @"info"}];
            [privateTitlePanel setButtonsWithTitlesAndActions:actions];
        }

        [controller setPrimaryTitlePanel:privateTitlePanel];
    }
}

- (void)_loadControllerPrimaryTitlePanel
{
    [self _createOrUpdatePrimaryTitlePanel:true];
}

- (void)controllerDidUpdateTypingActivity
{
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        if ((![TGDatabaseInstance() uidIsRemoteContact:_uid] || [TGDatabaseInstance() loadUser:_uid].presence.online || [TGDatabaseInstance() loadUser:_uid].presence.lastSeen <= 0))
        {
            [[TGTelegraphInstance activityManagerForConversationId:_conversationId] addActivityWithType:@"typing" priority:10 timeout:5.0];
        }
    }];
}

- (void)controllerDidCancelTypingActivity
{
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        [[TGTelegraphInstance activityManagerForConversationId:_conversationId] removeActivityWithType:@"typing"];
    }];
}

- (void)requestUserBlocked:(bool)blocked
{
    [ActionStageInstance() dispatchOnStageQueue:^
    {
        _hasUnblockPanel = blocked;
        
        static int actionId = 0;
        
        [ActionStageInstance() requestActor:[[NSString alloc] initWithFormat:@"/tg/changePeerBlockedStatus/(cb%d)", actionId++] options:@{@"peerId": @(_uid), @"block": @(blocked)} watcher:TGTelegraphInstance];
    }];
    
    [self updateUserBlocked:blocked];
}

- (void)updateUserBlocked:(bool)blocked
{
    if (_hasUnblockPanel != blocked)
    {
        _hasUnblockPanel = blocked;
        
        ASHandle *actionHandle = self.actionHandle;
        TGDispatchOnMainThread(^
        {
            _isBlocked = blocked;
            [self _createOrUpdatePrimaryTitlePanel:false];
            
            TGModernConversationController *controller = self.controller;
            if (blocked)
            {
                TGModernConversationActionInputPanel *unblockPanel = [[TGModernConversationActionInputPanel alloc] init];
                [unblockPanel setActionWithTitle:TGLocalized(@"Conversation.Unblock") action:@"unblock"];
                unblockPanel.delegate = controller;
                unblockPanel.companionHandle = actionHandle;
                [controller setCustomInputPanel:unblockPanel];
            }
            else
                [controller setCustomInputPanel:nil];
        });
    }
}

- (NSString *)_controllerInfoButtonText
{
    return TGLocalized(@"Conversation.InfoPrivate");
}

- (NSDictionary *)userActivityData
{
    NSMutableDictionary *peerDict = [[NSMutableDictionary alloc] init];
    peerDict[@"type"] = @"user";
    peerDict[@"id"] = @((int32_t)_conversationId);
    TGUser *user = [TGDatabaseInstance() loadUser:(int32_t)_conversationId];
    if (user.userName.length != 0)
        peerDict[@"username"] = user.userName;
    return @{@"user_id": @(TGTelegraphInstance.clientUserId), @"peer": peerDict};
}

#pragma mark -

- (void)actionStageActionRequested:(NSString *)action options:(id)options
{
    if ([action isEqualToString:@"actionPanelAction"])
    {
        NSString *panelAction = options[@"action"];
        if ([panelAction isEqualToString:@"unblock"])
            [self requestUserBlocked:false];
    }
    else if ([action isEqualToString:@"titlePanelAction"])
    {
        NSString *panelAction = options[@"action"];
        
        if ([panelAction isEqualToString:@"block"])
            [self requestUserBlocked:true];
        else if ([panelAction isEqualToString:@"unblock"])
            [self requestUserBlocked:false];
        else if ([panelAction isEqualToString:@"call"])
        {
            TGUser *user = [TGDatabaseInstance() loadUser:_uid];
            
            NSMutableArray *phoneNumbers = [[NSMutableArray alloc] init];
            
            if (user.phoneNumber != nil && user.phoneNumber.length != 0)
            {
                [phoneNumbers addObject:@[@"mobile", user.phoneNumber, [TGPhoneUtils formatPhone:user.phoneNumber forceInternational:true]]];
            }
            
            TGPhonebookContact *contact = [TGDatabaseInstance() phonebookContactByPhoneId:[user contactId]];
            int mainPhoneHash = phoneMatchHash(user.phoneNumber);
            for (TGPhoneNumber *number in contact.phoneNumbers)
            {
                if (number.phoneId != mainPhoneHash)
                {
                    [phoneNumbers addObject:@[number.label == nil ? @"" : number.label, number.number, [TGPhoneUtils formatPhone:number.number forceInternational:false]]];
                }
            }
            
            if (phoneNumbers.count != 0)
            {
                if (phoneNumbers.count == 1)
                {
                    NSString *telephoneScheme = @"tel:";
                    if (![[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel://"]])
                        telephoneScheme = @"facetime:";
                    
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", telephoneScheme, [TGPhoneUtils formatPhoneUrl:[[phoneNumbers objectAtIndex:0] objectAtIndex:1]]]]];
                }
                else if (phoneNumbers.count > 1)
                {
                    TGModernConversationController *controller = self.controller;
                    [controller showCallNumberMenu:phoneNumbers];
                }
            }
        }
        else if ([panelAction isEqualToString:@"edit"])
        {
            TGModernConversationController *controller = self.controller;
            [controller enterEditingMode];
        }
        else if ([panelAction isEqualToString:@"info"])
            [self _controllerAvatarPressed];
    }
    
    [super actionStageActionRequested:action options:options];
}

- (void)actionStageResourceDispatched:(NSString *)path resource:(id)resource arguments:(id)arguments
{
    if ([path isEqualToString:@"/tg/userdatachanges"] || [path isEqualToString:@"/tg/userpresencechanges"])
    {
        NSArray *users = ((SGraphObjectNode *)resource).object;
        
        for (TGUser *user in users)
        {
            if (user.uid == _uid)
            {
                bool accentColored = false;
                NSString *statusString = [self statusStringForUser:user accentColored:&accentColored];
                [self _setTitle:[self stringForTitle:user isContact:[TGDatabaseInstance() uidIsRemoteContact:_uid]] andStatus:statusString accentColored:accentColored allowAnimatioon:true];
                [self _setAvatarConversationId:_uid firstName:user.firstName lastName:user.lastName];
                [self _setAvatarUrl:user.photoUrlSmall];
                
                break;
            }
        }
    }
    else if ([path isEqualToString:@"/as/updateRelativeTimestamps"])
    {
        TGUser *user = [TGDatabaseInstance() loadUser:_uid];
        
        bool accentColored = false;
        NSString *statusString = [self statusStringForUser:user accentColored:&accentColored];
        [self _setTitle:[self stringForTitle:user isContact:[TGDatabaseInstance() uidIsRemoteContact:_uid]] andStatus:statusString accentColored:accentColored allowAnimatioon:false];
        [self _setAvatarConversationId:_uid firstName:user.firstName lastName:user.lastName];
        [self _setAvatarUrl:user.photoUrlSmall];
    }
    else if ([path isEqualToString:[[NSString alloc] initWithFormat:@"/tg/conversation/(%lld)/typing", _conversationId]])
    {
        NSDictionary *userActivities = ((SGraphObjectNode *)resource).object;
        if (userActivities.count == 0)
            [self _setTypingStatus:nil activity:0];
        else
        {
            NSString *activity = userActivities[userActivities.allKeys.firstObject];
            [self _setTypingStatus:[self stringForActivity:activity] activity:[self activityTypeForActivity:activity]];
        }
    }
    else if ([path hasPrefix:@"/tg/blockedUsers"])
    {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
    else if ([path hasPrefix:@"/tg/contactlist"])
    {
        bool isContact = [TGDatabaseInstance() uidIsRemoteContact:_uid];
        TGDispatchOnMainThread(^
        {
            if (_isContact != isContact)
            {
                _isContact = isContact;
                
                [self _createOrUpdatePrimaryTitlePanel:false];
                [self _updateContactLinkPanel];
            }
        });
    }
    else if ([path hasPrefix:@"/tg/peerSettings/"])
    {
        [self actorCompleted:ASStatusSuccess path:path result:resource];
    }
    else if ([path hasPrefix:@"/tg/userLink/"])
    {
        int userLink = [(NSNumber *)((SGraphObjectNode *)resource).object intValue];
        TGDispatchOnMainThread(^
        {
            [self _updatePhoneSharingStatusFromUserLink:userLink];
        });
    }
    
    [super actionStageResourceDispatched:path resource:resource arguments:arguments];
}

- (void)actorCompleted:(int)status path:(NSString *)path result:(id)result
{
    if ([path hasPrefix:@"/tg/blockedUsers"])
    {
        id blockedResult = ((SGraphObjectNode *)result).object;
        
        bool blocked = false;
        
        if ([blockedResult respondsToSelector:@selector(boolValue)])
            blocked = [blockedResult boolValue];
        else if ([blockedResult isKindOfClass:[NSArray class]])
        {
            for (TGUser *user in blockedResult)
            {
                if (user.uid == _uid)
                {
                    blocked = true;
                    break;
                }
            }
        }
        
        [self updateUserBlocked:blocked];
    }
    else if ([path hasPrefix:@"/tg/peerSettings/"])
    {
        bool isMuted = [[((SGraphObjectNode *)result).object objectForKey:@"muteUntil"] intValue] != 0;
        [self _updateUserMute:isMuted];
    }
    
    [super actorCompleted:status path:path result:result];
}

@end
