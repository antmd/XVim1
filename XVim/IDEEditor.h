//
//  IDEEditorArea.h
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DVTFindBar;
@class IDEEditorContext;
@class IDEEditorDocument;
@class IDEFileTextSettings;
@class DVTScopeBarsManager;

@interface IDEEditor : NSViewController
{
    IDEEditorDocument *_document;
    IDEEditorDocument *_documentForNavBarStructure;
    IDEEditorContext *_editorContext;
    DVTFindBar *_findBar;
    id _documentForwarder;
//    id <DVTTextFindable> _findableObject;
    id _documentDidChangeNotificationToken;
    id _documentForNavBarStructureDidChangeNotificationToken;
    IDEFileTextSettings *_fileTextSettings;
//    id <IDEEditorDelegate> _delegate;
    BOOL _discardsFindResultsWhenContentChanges;
}

+ (BOOL)canProvideCurrentSelectedItems;
//@property id <IDEEditorDelegate> delegate; // @synthesize delegate=_delegate;
@property(assign) IDEFileTextSettings *fileTextSettings; // @synthesize fileTextSettings=_fileTextSettings;
//@property id <DVTTextFindable> findableObject; // @synthesize findableObject=_findableObject;
@property(assign) IDEEditorContext *editorContext; // @synthesize editorContext=_editorContext;
@property(assign) IDEEditorDocument *documentForNavBarStructure; // @synthesize documentForNavBarStructure=_documentForNavBarStructure;
@property BOOL discardsFindResultsWhenContentChanges; // @synthesize discardsFindResultsWhenContentChanges=_discardsFindResultsWhenContentChanges;
- (id)relatedMenuItemsForNavItem:(id)arg1;
- (void)didSetupEditor;
- (void)navigateToAnnotationWithRepresentedObject:(id)arg1 wantsIndicatorAnimation:(BOOL)arg2 exploreAnnotationRepresentedObject:(id)arg3;
- (void)selectDocumentLocations:(id)arg1;
- (id)currentSelectedDocumentLocations;
- (id)currentSelectedItems;
- (void)invalidate;
- (void)setNextResponder:(id)arg1;
- (id)documentForwarder;
@property(readonly) NSScrollView *mainScrollView;
@property(readonly) DVTScopeBarsManager *scopeBarsManager;
@property(readonly, getter=isPrimaryEditor) BOOL primaryEditor;
- (void)setupContextMenuWithMenu:(id)arg1 withContext:(id)arg2;
- (void)takeFocus;
@property(readonly) DVTFindBar *findBar; // @synthesize findBar=_findBar;
- (void)editorContextDidHideFindBar;
- (id)createFindBar;
@property(readonly) BOOL findBarSupported;
- (id)_getUndoManager:(BOOL)arg1;
- (id)undoManager;
@property(readonly) IDEEditorDocument *document; // @synthesize document=_document;
- (id)initWithNibName:(id)arg1 bundle:(id)arg2 document:(id)arg3;
- (id)_initWithNibName:(id)arg1 bundle:(id)arg2;
- (id)initWithNibName:(id)arg1 bundle:(id)arg2;
- (id)initUsingDefaultNib;

@end