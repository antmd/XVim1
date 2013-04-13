//
//  IDEEditorArea+XVim.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <objc/runtime.h>
#import "IDEEditorArea+XVim.h"
#import "Logger.h"

@implementation IDEEditorArea (XVim)

- (NSView*)textViewArea{
    NSView* layoutView;
    object_getInstanceVariable(self, "_editorAreaAutoLayoutView", (void**)&layoutView); // The view contains editors and border view
    return layoutView;
}

- (DVTBorderedView*)debuggerBarBorderedView{
    DVTBorderedView* border;
    object_getInstanceVariable(self, "_debuggerBarBorderedView", (void**)&border); // The view contains editors and border view
    return border;
}

- (void)setupCommandLine{
    NSView* layoutView = [self textViewArea];
    // Check if we already have command line in the _editorAreaAutoLayoutView.
    if( nil == [self commandLine] ){
        XVimCommandLine *cmd = [[[XVimCommandLine alloc] initWithEditorArea:self ] autorelease];
        [ cmd associateWith:self ];
        [layoutView addSubview:cmd];
        
        // This notification is to resize command line view according to the editor area size.
        [[NSNotificationCenter defaultCenter] addObserver:cmd
                                                 selector:@selector(didFrameChanged:)
                                                     name:NSViewFrameDidChangeNotification
                                                   object:layoutView];
        if ([[layoutView subviews] count] > 0) {
            DVTBorderedView* border = [self debuggerBarBorderedView];
            // We need to know if border view is hidden or not to place editors and command line correctly.
            [border addObserver:cmd forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew context:nil];
            //NSView* view = [[layoutView subviews] objectAtIndex:0];
            
        }
    }
    
}

- (void)teardownCommandLine
{
    XVimCommandLine *cmd = [self commandLine];
    DVTBorderedView *border = [self debuggerBarBorderedView];
    [border removeObserver:cmd forKeyPath:@"hidden"];
    [[NSNotificationCenter defaultCenter] removeObserver:cmd];
}

- (XVimCommandLine*)commandLine{
    return [ XVimCommandLine associateOf:self ];
}
@end
