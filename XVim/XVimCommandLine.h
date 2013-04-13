//
//  XVimCommandLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XVimCommandField.h"

@class IDEEditorArea;

static const NSInteger XVimCommandLineTag = 1337;

@interface XVimCommandLine : NSView

+ (XVimCommandLine*)associateOf:(id)object;
- (id)initWithEditorArea:(IDEEditorArea*)editorArea;
- (void)setModeString:(NSString*)string;
- (void)setArgumentString:(NSString*)string;
- (void)errorMessage:(NSString*)string Timer:(BOOL)aTimer RedColorSetting:(BOOL)aRedColorSetting;
- (void)quickFixWithString:(NSString*)string;
- (NSUInteger)quickFixColWidth;
- (void)didFrameChanged:(NSNotification*)notification;
- (void)associateWith:(id)object;

- (XVimCommandField*)commandField;
@end
