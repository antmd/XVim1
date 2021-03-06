//
//  XVimWindowManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimWindowManager.h"
#import "IDESourceEditor.h"
#import "XVimGlobalMark.h"
#import "Logger.h"

#import "IDEKit.h"

static XVimWindowManager *_instance = nil;
NSInteger yContextSort(id ctx1, id ctx2, void *context);
NSInteger xContextSort(id ctx1, id ctx2, void *context);
void dumpEditorContexts(NSString*prefix, IDEEditorContext* activeContext, NSArray* editorContexts);
NSRect editorContextWindowFrame(IDEEditorContext* obj1);
NSComparisonResult invertComparisonResult(NSComparisonResult comp);

typedef bool (^XvimDecider)(id obj) ;

@interface NSArray(Xvim)
-(NSArray*)filteredArrayUsingDecider:(XvimDecider)decider ;
@end

@interface XVimWindowManager() {
    NSWindow* _editorWindow;
}
- (void)setHorizontal;
- (void)setVertical;
@property (weak) IDEWorkspaceTabController *workspaceTabController ;
@property (weak) IDEEditorArea *editorArea;
@property (weak) IDEEditorModeViewController* editorModeViewController ;
@property (weak) IDEWorkspaceWindow* workspaceWindow ;
@property (weak) IDEEditorContext* activeContext;
@property (weak) NSArray* editorContexts;
@property (weak) DVTTextDocumentLocation* currentLocation ;
@property (assign) XvimEditorMode editorMode ;
@property (assign) XvimAssistantLayoutMode assistantEditorsLayoutMode;
@property (copy,nonatomic) IDENavigableItem* currentIDELocation;
@end



@implementation XVimWindowManager
@dynamic workspaceTabController;
@dynamic editorArea;
@dynamic editorModeViewController;
@dynamic workspaceWindow;
@dynamic activeContext;
@dynamic editorContexts;
@dynamic currentLocation;
@dynamic editorMode;
@dynamic assistantEditorsLayoutMode ;
@dynamic currentIDELocation;


// 0 = horizontal, 1 = vertical
typedef enum { XVIM_HORIZONTAL_MOTION, XVIM_VERTICAL_MOTION } XvimWindowMotion ;
typedef bool DirectionDecisions[4] ;
static DirectionDecisions
    canJumpBetweenPrimaryAndSecondaryWhenMoving[] = {
        /*  Columns:
         0 = Can jump horizontally between assistant and primary,
         1 = Can jump vertically between assistant and primary,
         2 = Can move horizontally between the secondary editors,
         3 = Can move vertically between the secondary editors
         */
         
        /* 0 = XVIM_RIGHT_HORIZONTAL  */  { true,  false, false, true  }
        /* 1 = XVIM_RIGHT_VERTICAL    */, { true,  false, true,  false }
        /* 2 = UNDEFINED              */, { false, false, false, false }
        /* 3 = UNDEFINED              */, { false, false, false, false }
        /* 4 = UNDEFINED              */, { false, false, false, false }
        /* 5 = UNDEFINED              */, { false, false, false, false }
        /* 6 = XVIM_BOTTOM_HORIZONTAL */, { false, true,  false, true  }
        /* 7 = XVIM_BOTTOM_VERTICAL   */, { false, true,  true,  false }
    };

-(IDEWorkspaceTabController *) workspaceTabController { return  [self.editor workspaceTabController] ;}
-(IDEEditorArea *) editorArea { return self.workspaceTabController.editorArea; }
-(IDEEditorModeViewController*) editorModeViewController { return self.editorArea.editorModeViewController; }
-(IDEWorkspaceWindow*) workspaceWindow { return (IDEWorkspaceWindow*)[self.editor.textView window]; }
-(XvimEditorMode)editorMode { return (XvimEditorMode)self.editorArea.editorMode; }
-(XvimAssistantLayoutMode)assistantEditorsLayoutMode { return (XvimAssistantLayoutMode)self.workspaceTabController.assistantEditorsLayout; }

static NSMutableDictionary* GlobalMarks = nil;

-(NSMutableDictionary*)globalMarksDict
{
    if (GlobalMarks==nil) {
        GlobalMarks = [[ NSMutableDictionary alloc ] init];
    }
    return GlobalMarks;
}

-(void)_notifyGlobalMarksChanged
{
    NSMutableArray* marks = [ NSMutableArray array ];
    for (NSString* key in [self globalMarksDict]) {
        DVTTextDocumentLocation* loc = [[self globalMarksDict] objectForKey:key];
        NSString* locdesc = [ NSString stringWithFormat:@"Line: %llu", loc.startingLineNumber];
        XVimGlobalMark* gmark = [ XVimGlobalMark globalMark:key
                                                   withURL:[ loc documentURL]
                                               withLocation:locdesc];
        [ marks addObject:gmark];
    }
    NSDictionary* userInfoDict = [ NSDictionary dictionaryWithObject:marks
                                                              forKey:@"marks"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"XVimMarksChanged"
                                                        object:self
                                                      userInfo:userInfoDict ];
}


-(void)setGlobalMark:(NSString*)markName
{
    DVTTextDocumentLocation* loc = self.currentLocation;
    if (loc!=nil) {
        [[ self globalMarksDict] setObject:[[loc copy]autorelease] forKey:markName ];
        [ self _notifyGlobalMarksChanged ];
    }
}
-(void)jumpToGlobalMark:(NSString*)markName
{
    DVTTextDocumentLocation* loc = [[self globalMarksDict] objectForKey:markName];
    if (loc != nil) {
        self.currentLocation = loc;
    }
}

-(IDEEditorContext*)activeContext
{
    return [(IDESourceCodeEditor*)[(DVTSourceTextView*)[ self.workspaceWindow firstResponder ] delegate ] editorContext ];
}

-(IDESourceCodeEditor*)editor
{
    IDEWorkspaceWindowController* windowDelegate = (IDEWorkspaceWindowController*)[ _editorWindow delegate ];
    if ([windowDelegate isKindOfClass:NSClassFromString(@"IDEWorkspaceWindowController")]) {
        IDEEditorArea* editorArea = [windowDelegate editorArea];
        if ([editorArea isKindOfClass:NSClassFromString(@"IDEEditorArea")]) {
            IDEEditorContext* editorContext = [ editorArea lastActiveEditorContext ];
            if ([editorContext isKindOfClass:NSClassFromString(@"IDEEditorContext")]) {
                return (IDESourceCodeEditor*)[ editorContext editor ];
            }
        }
    }
    return nil;
}

-(NSArray*)editorContexts
{
    NSArray* contexts = nil;
    if ( self.editorModeViewController != nil && self.editorMode == XVIM_EDITOR_MODE_GENIUS )
    {
        contexts = [ self.editorModeViewController editorContexts ];
    }
    else if (self.activeContext)
    {
        contexts = [ NSArray arrayWithObject:self.activeContext ];
    }
    return contexts;
}


-(IDENavigableItem*)currentIDELocation
{
    IDENavigableItem* currentLocation = (self.editorMode==XVIM_EDITOR_MODE_STANDARD)?self.editor.editorContext.navigableItem: self.activeContext.navigableItem;
    return currentLocation;
}

-(void)setCurrentIDELocation:(IDENavigableItem *)IDELocation
{
    self.activeContext.navigableItem = IDELocation;
}

-(DVTTextDocumentLocation*)locationForEditor:(IDEEditor*)editor
{
    DVTTextDocumentLocation* loc = nil;
    if (editor != nil
        && (self.editorMode == XVIM_EDITOR_MODE_GENIUS || self.editorMode == XVIM_EDITOR_MODE_STANDARD) ) {
        NSArray* currentLocations = [ editor currentSelectedDocumentLocations ];
        if (currentLocations && [ currentLocations count ] > 0)
        {
            loc = [ currentLocations objectAtIndex:0 ];
        }
    }
    return loc;
}


-(DVTTextDocumentLocation*)currentLocation
{
    return [ self locationForEditor:self.activeContext.editor ];
}


-(void)setCurrentLocation:(DVTTextDocumentLocation *)currentLocation
{
    if (currentLocation)
    {
        IDEDocumentController* docController = [ NSDocumentController sharedDocumentController ];
        [ docController openDocumentLocation:currentLocation error:nil ];
    }
}

+ (void)createWithEditor:(IDESourceCodeEditor*)editor
{
    XVimWindowManager *instance = [[self alloc] initWithEditor:editor ];
    _instance = instance;
}

+ (XVimWindowManager*)instance
{
	return _instance;
}

- (id)initWithEditor:(IDESourceCodeEditor*)editor
{
    self = [super init];
    if (self) {
        _editorWindow = [[ editor view ] window];
        }
    return self;
}

- (void)addEditorWindow
{
    IDESourceCodeEditor *editor = self.editor;
    if (self.editor == nil) { return; }
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDENavigableItem* currentLocation = (self.editorMode==XVIM_EDITOR_MODE_STANDARD)?self.editor.editorContext.navigableItem: self.activeContext.navigableItem;
    
    if (self.editorMode != XVIM_EDITOR_MODE_GENIUS){
        TRACE_LOG(@"Opening in adjacent window with alternate");
        [ NSApp sendAction:@selector(openInAdjacentEditorWithAlternate:) to:nil from:self ];
    }else {
        TRACE_LOG(@"Adding assistant editor");
        [workspaceTabController addAssistantEditor:self];
        ((IDEEditorContext*)[ self.editorContexts lastObject ]).navigableItem =currentLocation; // Focus on just-opened editor
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
    IDESourceCodeEditor *editor = self.editor;
    if (editor == nil) { return; }
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    IDEEditorArea *editorArea = [workspaceTabController editorArea];
    if (self.editorMode != XVIM_EDITOR_MODE_GENIUS){
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
    DVTTextDocumentLocation* currentLocation = self.currentLocation;
    if (self.editorMode == XVIM_EDITOR_MODE_GENIUS)
    {
        while ([[self.editorModeViewController editorContexts] count ] > 2) {
            [ self.editorModeViewController removeAssistantEditor ];
        }
        [ NSApp sendAction:@selector(changeToStandardEditor:) to:nil from:self];
    }
    
self.currentLocation = currentLocation;
}

- (void)setHorizontal
{
    IDESourceCodeEditor *editor = self.editor;
    if (editor == nil ) { return; }
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_BH:self];
}

- (void)setVertical
{
    IDESourceCodeEditor *editor = self.editor;
    if (editor == nil ) { return; }
    IDEWorkspaceTabController *workspaceTabController = [editor workspaceTabController];
    [workspaceTabController changeToAssistantLayout_RV:self];
}


// To do: this only jumps to the next editor in the set of editors. Need to generalise this to allow backward motion, and motion in a direction
-(void)jumpToOtherEditor
{
    NSArray* editorContexts = self.editorContexts;
    if (editorContexts) {
        NSUInteger idxOfActiveContext = [ editorContexts indexOfObject:self.activeContext ];
        IDEEditorContext* nextContext = [ editorContexts objectAtIndex:((idxOfActiveContext + 1) % [editorContexts count] )] ;
        [ nextContext takeFocus ];
    }
}
-(IDEEditorContext*)downEditorContext
{
    IDEEditorContext* context = nil;
    if (self.editorContexts)
    {
        bool canJumpBetweenAssistantAndPrimary = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_VERTICAL_MOTION];
        bool canJumpVerticallyInSecondaryEditors = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_VERTICAL_MOTION+2];
        
        if (!canJumpBetweenAssistantAndPrimary && self.activeContext.isPrimaryEditorContext) {
            return nil;
        }
        if (!canJumpVerticallyInSecondaryEditors && !self.activeContext.isPrimaryEditorContext) {
            return nil;
        }
        NSArray* sortedEditorContexts = [ self.editorContexts sortedArrayUsingFunction:yContextSort context:self.activeContext ] ;
    
        if (!self.activeContext.isPrimaryEditorContext && !canJumpBetweenAssistantAndPrimary)
        {
            sortedEditorContexts = [ sortedEditorContexts filteredArrayUsingDecider:^bool(id obj) {
                return ![(IDEEditorContext*)obj isPrimaryEditorContext];
            } ];
        }
        NSUInteger idxOfActiveContext = [ sortedEditorContexts indexOfObject:self.activeContext ];
        if (idxOfActiveContext != NSNotFound && idxOfActiveContext > 0)
        {
            context = [ sortedEditorContexts objectAtIndex:(idxOfActiveContext - 1) ] ;
        }
    }
    return context;
    
}
-(void)jumpToEditorDown
{
    [ [ self downEditorContext ] takeFocus ];
    [ self.editor jumpToSelection:self ];

}
-(IDEEditorContext*)upEditorContext
{
    IDEEditorContext* context = nil;
    if (self.editorContexts)
    {
        bool canJumpBetweenAssistantAndPrimary = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_VERTICAL_MOTION];
        bool canJumpVerticallyInSecondaryEditors = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_VERTICAL_MOTION+2];
        
        if (!canJumpBetweenAssistantAndPrimary && self.activeContext.isPrimaryEditorContext) {
            return nil;
        }
        if (!canJumpVerticallyInSecondaryEditors
            && !self.activeContext.isPrimaryEditorContext
            && !canJumpBetweenAssistantAndPrimary) {
            return nil;
        }
        if (canJumpBetweenAssistantAndPrimary
            && !self.activeContext.isPrimaryEditorContext
            && !canJumpVerticallyInSecondaryEditors)
        {
            [ self.editorModeViewController.primaryEditorContext takeFocus];
            return nil;
        }
        NSArray* sortedEditorContexts = [ self.editorContexts sortedArrayUsingFunction:yContextSort context:self.activeContext ] ;
    
        if (!self.activeContext.isPrimaryEditorContext && !canJumpBetweenAssistantAndPrimary)
        {
            sortedEditorContexts = [ sortedEditorContexts filteredArrayUsingDecider:^bool(id obj) {
            return ![(IDEEditorContext*)obj isPrimaryEditorContext];
            } ];
        }
        NSUInteger idxOfActiveContext = [ sortedEditorContexts indexOfObject:self.activeContext ];
        if ( idxOfActiveContext != NSNotFound && idxOfActiveContext < ([sortedEditorContexts count]-1))
        {
            context = [ sortedEditorContexts objectAtIndex:(idxOfActiveContext + 1) ] ;
        }
    }
    return context;
}

-(void)jumpToEditorUp
{
    [ [self upEditorContext] takeFocus ];
    [ self.editor jumpToSelection:self ];

}

-(IDEEditorContext*)leftEditorContext
{
    IDEEditorContext* context = nil;
    if (self.editorContexts)
    {
        bool canJumpBetweenAssistantAndPrimary = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_HORIZONTAL_MOTION];
        bool canJumpHorizontallyInSecondaryEditors = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_HORIZONTAL_MOTION+2];
        
        if (!canJumpBetweenAssistantAndPrimary && self.activeContext.isPrimaryEditorContext) {
            return nil;
        }
        
        if (!canJumpHorizontallyInSecondaryEditors
            && !self.activeContext.isPrimaryEditorContext
            && !canJumpBetweenAssistantAndPrimary)
        {
            return nil;
        }
        if (canJumpBetweenAssistantAndPrimary
            && !self.activeContext.isPrimaryEditorContext
            && !canJumpHorizontallyInSecondaryEditors)
        {
            [ self.editorModeViewController.primaryEditorContext takeFocus];
            return nil;
        }
        NSArray* sortedEditorContexts = [ self.editorContexts sortedArrayUsingFunction:xContextSort context:self.activeContext ] ;
    
        if (!self.activeContext.isPrimaryEditorContext && !canJumpBetweenAssistantAndPrimary)
        {
            sortedEditorContexts = [ sortedEditorContexts filteredArrayUsingDecider:^bool(id obj) {
            return ![(IDEEditorContext*)obj isPrimaryEditorContext];
            } ];
        }
        NSUInteger idxOfActiveContext = [ sortedEditorContexts indexOfObject:self.activeContext ];
        if (idxOfActiveContext != NSNotFound && idxOfActiveContext > 0)
        {
            context = [ sortedEditorContexts objectAtIndex:((idxOfActiveContext - 1) % [sortedEditorContexts count] )] ;
        }
    }
    return context;
}
-(BOOL)jumpToEditorLeft
{
    IDEEditorContext* leftContext = [ self leftEditorContext ];
    if (leftContext) {
        [ leftContext takeFocus ];
        [ self.editor jumpToSelection:self ];
        return YES;
    }
    return NO;

}
-(void)moveEditorLeft
{
    if ([ self jumpToEditorLeft]) {
        [ self moveEditorRightTakingSelection:NO ];
    }
}
-(IDEEditorContext*)rightEditorContext
{
    IDEEditorContext* context = nil;
    if (self.editorContexts)
    {
        bool canJumpBetweenAssistantAndPrimary = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_HORIZONTAL_MOTION];
        bool canJumpHorizontallyInSecondaryEditors = canJumpBetweenPrimaryAndSecondaryWhenMoving[self.assistantEditorsLayoutMode][XVIM_HORIZONTAL_MOTION+2];
        
        if (!canJumpBetweenAssistantAndPrimary && self.activeContext.isPrimaryEditorContext) {
            return nil;
        }
        if (!canJumpHorizontallyInSecondaryEditors && !self.activeContext.isPrimaryEditorContext) {
            return nil;
        }
        NSArray* sortedEditorContexts = [ self.editorContexts sortedArrayUsingFunction:xContextSort context:self.activeContext ] ;
    
        if (!self.activeContext.isPrimaryEditorContext && !canJumpBetweenAssistantAndPrimary)
        {
            sortedEditorContexts = [ sortedEditorContexts filteredArrayUsingDecider:^bool(id obj) {
            return ![(IDEEditorContext*)obj isPrimaryEditorContext];
            } ];
        }
        NSUInteger idxOfActiveContext = [ sortedEditorContexts indexOfObject:self.activeContext ];
        if ( idxOfActiveContext != NSNotFound && idxOfActiveContext < ([sortedEditorContexts count]-1))
        {
            context = [ sortedEditorContexts objectAtIndex:((idxOfActiveContext + 1) % [sortedEditorContexts count] )] ;
        }
    }
    return context;
}

-(void)jumpToEditorRight
{
    [ [self rightEditorContext] takeFocus ];
    [ self.editor jumpToSelection:self ];
}
-(void)moveEditorRightTakingSelection:(BOOL)takeSelection
{
    IDEEditorGeniusMode *geniusMode = (IDEEditorGeniusMode*)[self.editorArea editorModeViewController];
    IDEEditorContext* rightContext = [ self rightEditorContext ];
    if (rightContext) {
        id currentPosition = [ self.currentIDELocation archivableRepresentation ];
        self.currentIDELocation = rightContext.navigableItem;
        rightContext.navigableItem = [ geniusMode editorContext:rightContext
              navigableItemForEditingFromArchivedRepresentation:currentPosition
                                                          error:nil ];
        if (takeSelection) {
            [ rightContext takeFocus ];
            [ self.editor performSelector:@selector(jumpToSelection:)
                               withObject:self
                               afterDelay:0. ];
        }
    }
}
-(void)moveEditorRight
{
    [ self moveEditorRightTakingSelection:YES ];
    
}

-(void)changeToIssuesNavigator
{
    [self.workspaceTabController changeToIssuesNavigator:self ];
}
-(void)selectNextIssue
{
    [ self.activeContext jumpToNextIssue:self];
}
-(void)selectPreviousIssue
{
    [ self.activeContext jumpToPreviousIssue:self];
}
@end


/////////////////////////////////////////////////// End of Implementation //////////////////////////////////////////////////////////





NSInteger yContextSort(id ctx1, id ctx2, void *context)
{
    NSPoint o1 = editorContextWindowFrame((IDEEditorContext*)ctx1).origin;
    NSPoint o2 = editorContextWindowFrame((IDEEditorContext*)ctx2).origin;
    return (o1.y < o2.y) ? NSOrderedAscending
    : ( (o1.y > o2.y) ? NSOrderedDescending
       : ((context == NULL) ? NSOrderedSame
          : invertComparisonResult( xContextSort(ctx1, ctx2, NULL ) ) ) );
}


NSInteger xContextSort(id ctx1, id ctx2, void *context)
{
    NSPoint o1 = editorContextWindowFrame((IDEEditorContext*)ctx1).origin;
    NSPoint o2 = editorContextWindowFrame((IDEEditorContext*)ctx2).origin;
    return (o1.x < o2.x) ? NSOrderedAscending
    : ( (o1.x > o2.x) ? NSOrderedDescending
       : (( context == NULL) ? NSOrderedSame
          : invertComparisonResult( yContextSort(ctx1, ctx2, NULL) ) ) );
}

NSComparisonResult invertComparisonResult(NSComparisonResult comp)
{
    return ( comp == NSOrderedAscending ) ? NSOrderedDescending : ( ( comp == NSOrderedDescending ) ? NSOrderedAscending : NSOrderedSame ) ;
}

NSRect editorContextWindowFrame(IDEEditorContext* obj1)
{
    NSView* view1 = ((IDEEditorContext*)obj1).view;
    NSRect view1Frame = [ view1 convertRect:[view1 frame] toView:nil ];
    return view1Frame;
}

@implementation NSArray(Xvim)

-(NSArray*)filteredArrayUsingDecider:(XvimDecider)decider
{
    NSMutableArray* filtered = [NSMutableArray array];
    for (id item in self)
    {
        if (decider(item))
        {
            [filtered addObject:item];
        }
    }
    return filtered;
    
}

@end