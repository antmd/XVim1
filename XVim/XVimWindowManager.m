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
#import "XVim.h"

static NSArray *_instances = nil;
static XVimWindowManager *_currentInstance = nil;

@interface XVimWindowManager() {
    NSArray *_editors;
	IDESourceCodeEditor *_baseEditor;
	IDESourceCodeEditor *_currentEditor;
}
- (NSArray*)editors;
- (void)setHorizontal;
- (void)setVertical;
- (BOOL)hasEditorView:(NSView*)view;
- (IDESourceCodeEditorContainerView*)getEditorView:(NSView*)view;
- (DVTAutoLayoutView*)editorAreaAutoLayoutView;
- (void)addEditorWindowWithDocument:(IDESourceCodeDocument*)document;
- (void)removeEditorWindow:(IDESourceCodeEditor*)editor;
@end

@implementation XVimWindowManager

@synthesize currentEditor = _currentEditor;

+ (void)createWithEditor:(IDESourceCodeEditor*)editor
{
    // Set up the array of instances
    if (_instances == nil)
    {
        _instances = [NSArray array];
    }

    // See if the editor already has a window manager
    NSUInteger index = [_instances indexOfObjectPassingTest:^BOOL(XVimWindowManager *manager, NSUInteger idx, BOOL *stop){
        *stop = (manager->_baseEditor == editor) || [[manager editors] containsObject:editor];
        return *stop;
    }];

    if (index == NSNotFound) {
        // Create the window manager for this new editor
        XVimWindowManager *instance = [[self alloc] init];
        _instances = [_instances arrayByAddingObject:instance];
        _currentInstance = instance;

        instance->_currentEditor = editor;
        _currentInstance->_baseEditor = editor;
        instance->_editors = [NSArray arrayWithObject:editor];
    } else {
        // Set the window manager for this editor
        _currentInstance = [_instances objectAtIndex:index];
    }
}

+ (XVimWindowManager*)instance
{
	return _currentInstance;
}

- (NSArray*)editors
{
    return _editors;
}

- (IDESourceCodeEditor*)baseEditor
{
    return _baseEditor;
}

- (void)addEditorWindow
{
    IDESourceCodeEditor *editor = _baseEditor;
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
    IDESourceCodeEditor *editor = _baseEditor;
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
    IDESourceCodeEditor *editor = _baseEditor;
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
    IDESourceCodeEditor *editor = _baseEditor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BH:self];
}

- (void)setVertical
{
    IDESourceCodeEditor *editor = _baseEditor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BV:self];
}

- (DVTAutoLayoutView*)editorAreaAutoLayoutView
{
    IDESourceCodeEditor *editor = _baseEditor;
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];

    DVTAutoLayoutView* layoutView;
    object_getInstanceVariable(editorArea, "_editorAreaAutoLayoutView", (void**)&layoutView); // The view contains editors and border view
    
    return layoutView;
}

- (void)defaultLayoutAllWindows
{
    DVTAutoLayoutView *layoutView = [self editorAreaAutoLayoutView];
    [layoutView setPostsFrameChangedNotifications:YES];
    
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
        IDESourceCodeEditor* containedEditor = nil;
        IDESourceCodeEditorContainerView *containerView = [self getEditorView:view];
        object_getInstanceVariable(containerView, "_editor", (void**)&containedEditor);
    
        CGFloat index = [_editors indexOfObjectPassingTest:^BOOL(IDESourceCodeEditor *editor, NSUInteger i, BOOL *stop){
            *stop = (containedEditor == editor);
            return *stop;
        }];

        NSRect newFrame;
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

- (void)addEditorWindowWithDocument:(IDESourceCodeDocument*)document
{
    NSBundle *bundle = [NSBundle bundleWithPath:@"/Applications/Xcode.app/Contents/Plugins/IDESourceEditor.ideplugin"];
    [bundle load];

    IDESourceCodeEditor *editor = [[NSClassFromString(@"IDESourceCodeEditor") alloc] initWithNibName:@"IDESourceCodeEditor" bundle:bundle document:document];
    editor.fileTextSettings = [[NSClassFromString(@"IDEFileTextSettings") alloc] init];
    _editors = [_editors arrayByAddingObject:editor]; // Must do this before calling loadView

    [editor loadView];
    [[self editorAreaAutoLayoutView] addSubview:editor.containerView];
    [editor didSetupEditor];
    [editor takeFocus];

    [self defaultLayoutAllWindows];
}

- (void)addNewEditorWindow
{
    IDESourceCodeDocument *document = [_currentEditor.sourceCodeDocument emptyPrivateCopy];
    document.fileURL = [_currentEditor.sourceCodeDocument.fileURL URLByDeletingLastPathComponent];

    [self addEditorWindowWithDocument:document];
}

- (void)splitEditorWindow
{
    [self addEditorWindowWithDocument:_currentEditor.sourceCodeDocument];
}

- (void)removeCurrentEditorWindow
{
    [self removeEditorWindow:_currentEditor];
}

- (void)removeEditorWindow:(IDESourceCodeEditor*)editorToRemove
{
    // Cannot remove the base editor
    if (editorToRemove == _baseEditor)
    {
        [[XVim instance] errorMessage:@"Cannot remove this editor." ringBell:TRUE];
        return;
    }

    [editorToRemove.containerView removeFromSuperview];
    NSUInteger index = [_editors indexOfObject:editorToRemove];
    _editors = [_editors filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IDESourceCodeEditor *editor, NSDictionary *bindings){
        return editor != editorToRemove;
    }]];

    // Let the next editor take focus.
    [[_editors objectAtIndex:MIN(index, [_editors count] - 1)] takeFocus];
    [self defaultLayoutAllWindows];
}

- (void)closeAllButCurrentWindow
{
    NSArray *editorsCopy = [NSArray arrayWithArray:_editors];
    [editorsCopy enumerateObjectsUsingBlock:^(IDESourceCodeEditor *editor, NSUInteger index, BOOL *stop){
        if (editor != _currentEditor){
            [self removeEditorWindow:editor];
        }
    }];
}

- (void)moveFocusToNextEditor
{
    NSUInteger index = [_editors indexOfObject:_currentEditor];
    if (index == NSNotFound || index <= 0){
        [[XVim instance] ringBell];
        return;
    }

    IDESourceCodeEditor *editor = [_editors objectAtIndex:index - 1];
    [editor takeFocus];
}

- (void)moveFocusToPreviousEditor
{
    NSUInteger index = [_editors indexOfObject:_currentEditor];
    if (index == NSNotFound || (index + 1 >= ([_editors count]))){
        [[XVim instance] ringBell];
        return;
    }

    IDESourceCodeEditor *editor = [_editors objectAtIndex:index + 1];
    [editor takeFocus];
}

- (void)moveFocusToTopEditor
{
    IDESourceCodeEditor *editor = [_editors objectAtIndex:[_editors count] - 1];
    [editor takeFocus];
}

- (void)moveFocusToBotomEditor
{
    IDESourceCodeEditor *editor = [_editors objectAtIndex:0];
    [editor takeFocus];
}

- (void)moveCurrentWindowToTop
{
    TRACE_LOG(@"_editors: %@", _editors);
    _editors = [_editors filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IDESourceCodeEditor *editor, NSDictionary *bindings){
        return editor != _currentEditor;
    }]];
    
    TRACE_LOG(@"_editors: %@", _editors);
    _editors = [_editors arrayByAddingObject:_currentEditor];

    TRACE_LOG(@"_editors: %@", _editors);
    [self defaultLayoutAllWindows];
}

- (void)moveCurrentWindowToBottom
{
    TRACE_LOG(@"_editors: %@", _editors);
    _editors = [_editors filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IDESourceCodeEditor *editor, NSDictionary *bindings){
        return editor != _currentEditor;
    }]];
    
    TRACE_LOG(@"_editors: %@", _editors);
    _editors = [[NSArray arrayWithObject:_currentEditor] arrayByAddingObjectsFromArray:_editors];

    TRACE_LOG(@"_editors: %@", _editors);
    [self defaultLayoutAllWindows];
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

- (IDESourceCodeEditorContainerView*)getEditorView:(NSView*)view
{
    if ([view isKindOfClass:NSClassFromString(@"IDESourceCodeEditorContainerView")]) {
        return (IDESourceCodeEditorContainerView*)view;
    }

    NSArray *subviews = [view subviews];
    IDESourceCodeEditorContainerView __block *containerView = nil;
    [subviews enumerateObjectsUsingBlock:^(NSView *subview, NSUInteger idx, BOOL *stop){
        containerView = [self getEditorView:subview];
        *stop = containerView != nil;
    }];
    
    return containerView;
}

- (void)saveCurrentWindow
{
    NSNumber *isDirectory;
    NSSaveOperationType saveType = NSSaveOperation;
    IDESourceCodeDocument *document = self.currentEditor.sourceCodeDocument;
    [document.fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    if (document.fileURL.isFileURL && ![isDirectory boolValue]){
        [document saveToURL:document.fileURL ofType:document.fileType forSaveOperation:saveType error:nil];
    }else {
        [[XVim instance] errorMessage:@"Path is not valid!" ringBell:TRUE];
    }
}

- (void)saveCurrentWindowTo:(NSString*)relativePath
{
    NSNumber *isDirectory;
    NSSaveOperationType saveType = NSSaveToOperation;
    IDESourceCodeDocument *document = self.currentEditor.sourceCodeDocument;
    NSURL *url = [NSURL URLWithString:relativePath relativeToURL:document.fileURL];
    [url getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
    if (document.fileURL.isFileURL && ![isDirectory boolValue]){
        [document saveToURL:url ofType:document.fileType forSaveOperation:saveType error:nil];
    }else {
        [[XVim instance] errorMessage:@"Path is not valid!" ringBell:TRUE];
    }
}

@end