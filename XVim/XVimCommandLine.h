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

@interface XVimCommandLine : NSView

- (id)initWithEditorArea:(IDEEditorArea*)editorArea;
- (void)setModeString:(NSString*)string;
- (void)setArgumentString:(NSString*)string;
- (void)errorMessage:(NSString*)string;
- (void)quickFixWithString:(NSString*)string;
- (NSUInteger)quickFixColWidth;
- (void)didFrameChanged:(NSNotification*)notification;

- (XVimCommandField*)commandField;
@end
