//
//  XVimWindowEvaluator.m
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimWindowEvaluator.h"
#import "XVimWindowManager.h"
#import "XVimSourceView.h"
#import "XVimWindow.h"
#import "Logger.h"

@implementation XVimWindowEvaluator

- (XVimEvaluator*)c:(XVimWindow*)window
{
    [[XVimWindowManager instance] removeCurrentEditorWindow];
    return nil;
}

- (XVimEvaluator*)j:(XVimWindow*)window
{
    [[XVimWindowManager instance] moveFocusToNextEditor];
    return nil;
}


- (XVimEvaluator*)k:(XVimWindow*)window
{
    [[XVimWindowManager instance] moveFocusToPreviousEditor];
    return nil;
}


- (XVimEvaluator*)n:(XVimWindow*)window
{
    [[XVimWindowManager instance] addNewEditorWindow];
    return nil;
}

- (XVimEvaluator*)o:(XVimWindow*)window
{
	[[XVimWindowManager instance] closeAllButCurrentWindow];
    return nil;
}

- (XVimEvaluator*)s:(XVimWindow*)window{
    [[XVimWindowManager instance] splitEditorWindow];
    return nil;
}

- (XVimEvaluator*)q:(XVimWindow*)window{
    [[XVimWindowManager instance] removeCurrentEditorWindow];
    return nil;
}

- (XVimEvaluator*)v:(XVimWindow*)window{
    [[XVimWindowManager instance] addEditorWindowVertical];
    return nil;
}

@end