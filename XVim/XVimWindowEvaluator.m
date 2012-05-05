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

- (XVimEvaluator*)n:(XVimWindow*)window
{
    [[XVimWindowManager instance] addNewEditorWindow];
    return nil;
}

- (XVimEvaluator*)o:(XVimWindow*)window
{
	[[XVimWindowManager instance] closeAllButActive];
    return nil;
}

- (XVimEvaluator*)s:(XVimWindow*)window{
    [[XVimWindowManager instance] splitEditorWindow:window];
    return nil;
}

- (XVimEvaluator*)q:(XVimWindow*)window{
    [[XVimWindowManager instance] removeEditorWindow];
    return nil;
}

- (XVimEvaluator*)v:(XVimWindow*)window{
    [[XVimWindowManager instance] addEditorWindowVertical];
    return nil;
}

@end