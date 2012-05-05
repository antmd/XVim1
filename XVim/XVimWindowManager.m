//
//  XVimWindowManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimWindowManager.h"

#import "IDEKit.h"
#import "IDESourceEditor.h"
#import "DVTAutoLayoutView.h"
#import "XVimSourceView.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "Hooker.h"

static XVimWindowManager *_instance = nil;

@interface XVimWindowManager() {
	IDESourceCodeEditor *_editor;
}
- (void)setHorizontal;
- (void)setVertical;
- (DVTAutoLayoutView*)getLayoutView;
- (void)addEditorWindowWithTextStorage:(id)textStorage;
- (BOOL)hasEditorView:(NSView*)view;
@end

@implementation XVimWindowManager

+ (void)createWithEditor:(IDESourceCodeEditor*)editor
{
    if (_instance == nil) {
        XVimWindowManager *instance = [[self alloc] init];
        instance->_editor = editor;
        _instance = instance;
    }
}

+ (XVimWindowManager*)instance
{
	return _instance;
}

- (void)addEditorWindow
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }else {
        [workspaceTabController addAssistantEditor:self];
    }
}

- (void)addEditorWindowVertical
{
	[self addEditorWindow];
	[self setVertical];
}

- (void)addEditorWindowHorizontal
{
	[self addEditorWindow];
	[self setHorizontal];
}

- (void)removeEditorWindow
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }
    
    IDEEditorGeniusMode *geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
    if ([geniusMode canRemoveAssistantEditor] == NO){
        [workspaceTabController changeToStandardEditor:self];
    }else {
        [workspaceTabController removeAssistantEditor:self];
    }
}

- (void)closeAllButActive 
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];
    if ([editorArea editorMode] != 1){
        [workspaceTabController changeToGeniusEditor:self];
    }

    IDEEditorGeniusMode *geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
    IDEEditorMultipleContext *multipleContext = [geniusMode alternateEditorMultipleContext];
    if ([multipleContext canCloseEditorContexts]){
        [multipleContext closeAllEditorContextsKeeping:[multipleContext selectedEditorContext]];
    }
}

- (void)setHorizontal
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BH:self];
}

- (void)setVertical
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BV:self];
}

- (DVTAutoLayoutView*)getLayoutView
{
    IDESourceCodeEditor *editor = _editor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];

    DVTAutoLayoutView* layoutView;
    object_getInstanceVariable(editorArea, "_editorAreaAutoLayoutView", (void**)&layoutView); // The view contains editors and border view
    
    return layoutView;
}

- (void)defaultLayoutAllWindows
{
    DVTAutoLayoutView *layoutView = [self getLayoutView];
 //   [layoutView layoutTopDown];

    NSRect frame = [layoutView frame];
    NSRect bounds = [layoutView bounds];
    NSArray *subviews = [layoutView subviews];
    
    NSMutableArray *editorViews = [NSMutableArray arrayWithCapacity:[subviews count]];
    [subviews enumerateObjectsUsingBlock:^(NSView *view, NSUInteger idx, BOOL *stop)
    {
        if ([self hasEditorView:view]) {
            [editorViews addObject:view];
        }
    }];

    CGFloat count = [editorViews count];
    NSSize newFrameSize = NSMakeSize(frame.size.width, frame.size.height/count);
    NSSize newBoundsSize = NSMakeSize(bounds.size.width, bounds.size.height/count);
    [editorViews enumerateObjectsUsingBlock:^(NSView *view, NSUInteger idx, BOOL *stop){
         NSRect newFrame;
         CGFloat index = idx;
         newFrame.size = newFrameSize;
         newFrame.origin.x = frame.origin.x;
         newFrame.origin.y = frame.origin.y + index * newFrame.size.height;
         [view setFrame:newFrame];
         
         NSRect newBounds;
         newBounds.origin.x = bounds.origin.x;
         newBounds.origin.y = bounds.origin.y;
         newBounds.size = newBoundsSize;
         [view setBounds:newBounds];
     }];
}

- (void)addEditorWindowWithTextStorage:(id)textStorage
{
    id document = [[NSClassFromString(@"IDESourceCodeDocument") alloc] init];
    NSBundle *bundle = [NSBundle bundleWithPath:@"/Applications/Xcode.app/Contents/Plugins/IDESourceEditor.ideplugin"];
    [bundle load];

    IDESourceCodeEditor *editor = [[NSClassFromString(@"IDESourceCodeEditor") alloc] initWithNibName:@"IDESourceCodeEditor" bundle:bundle document:document];
    [editor loadView];
    
    editor.fileTextSettings = [[NSClassFromString(@"IDEFileTextSettings") alloc] init];
    
    [[self getLayoutView] addSubview:editor.containerView];
    [self defaultLayoutAllWindows];
}

- (void)addNewEditorWindow
{
    Class realStorageClass = NSClassFromString(@"DVTTextStorage");
    id realStorage = [[realStorageClass alloc] initWithString:@""];

    Class foldingStorageClass = NSClassFromString(@"DVTFoldingTextStorage");
    id foldingStorage = [[foldingStorageClass alloc] initWithTextStorage:realStorage]; 

    [self addEditorWindowWithTextStorage:foldingStorage];
}

- (void)splitEditorWindow:(XVimWindow*)window
{
    id view = [window.sourceView view];
    [self addEditorWindowWithTextStorage:[view textStorage]];
}

- (BOOL)hasEditorView:(NSView*)view
{
    if ([view isKindOfClass:NSClassFromString(@"IDESourceCodeEditorContainerView")]) {
        return TRUE;
    }

    BOOL __block found = FALSE;
    NSArray *subviews = [view subviews];
    [subviews enumerateObjectsUsingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop){
        if ([self hasEditorView:subview]) {
            *stop = TRUE;
            found = TRUE;
        }
    }];
    
    return found;
}

@end