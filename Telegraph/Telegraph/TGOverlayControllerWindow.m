/*
 * This is the source code of Telegram for iOS v. 1.1
 * It is licensed under GNU GPL v. 2 or later.
 * You should have received a copy of the license in this archive (see LICENSE).
 *
 * Copyright Peter Iakovlev, 2013.
 */

#import "TGOverlayControllerWindow.h"

#import "TGViewController.h"
#import "TGOverlayController.h"

@interface TGOverlayControllerWindow ()
{
    __weak TGViewController *_parentController;
}

@end

@implementation TGOverlayControllerWindow

- (instancetype)initWithParentController:(TGViewController *)parentController contentController:(TGOverlayController *)contentController
{
    self = [super initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self != nil)
    {
        self.windowLevel = UIWindowLevelStatusBar - 0.01f;
        
        _parentController = parentController;
        [parentController.associatedWindowStack addObject:self];
        
        contentController.overlayWindow = self;
        self.rootViewController = contentController;
    }
    return self;
}

- (void)dealloc
{
    [self.rootViewController viewWillDisappear:false];
    [self.rootViewController viewDidDisappear:false];
}

- (void)dismiss
{
    TGViewController *parentController = _parentController;
    [parentController.associatedWindowStack removeObject:self];
    self.hidden = true;
}

@end
