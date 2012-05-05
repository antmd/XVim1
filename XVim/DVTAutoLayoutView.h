//
//  DVTAutoLayoutView.h
//  XVim
//
//  Created by Nader Akoury on 4/29/2012
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@interface DVTAutoLayoutView : NSView
{
    NSMutableDictionary *invalidationTokens;
    BOOL _layoutNeeded;
    BOOL _implementsLayoutCompletionCallback;
}

+ (void)_layoutWindow:(id)arg1;
+ (void)_recursivelyLayoutSubviewsOfView:(id)arg1 populatingSetWithLaidOutViews:(id)arg2;
+ (void)scheduleWindowForLayout:(id)arg1;
+ (id)alreadyLaidOutViewsForCurrentDisplayPassOfWindow:(id)arg1;
+ (id)validatorForWindow:(id)arg1;
@property(getter=isLayoutNeeded) BOOL layoutNeeded; // @synthesize layoutNeeded=_layoutNeeded;
- (void)stopInvalidatingLayoutWithChangesToKeyPath:(id)arg1 ofObject:(id)arg2;
- (void)invalidateLayoutWithChangesToKeyPath:(id)arg1 ofObject:(id)arg2;
- (void)_autoLayoutViewViewFrameDidChange:(id)arg1;
- (void)stopInvalidatingLayoutWithFrameChangesToView:(id)arg1;
- (void)invalidateLayoutWithFrameChangesToView:(id)arg1;
- (void)setFrameSize:(struct CGSize)arg1;
- (void)didCompleteLayout;
- (void)layoutBottomUp;
- (void)layoutTopDown;
- (void)layoutIfNeeded;
- (void)didLayoutSubview:(id)arg1;
- (id)subviewsOrderedForLayout;
- (void)viewWillDraw;
- (void)_reallyLayoutIfNeededBottomUp;
- (void)_reallyLayoutIfNeededTopDown;
- (void)invalidateLayout;
- (void)viewDidMoveToWindow;
- (id)initWithCoder:(id)arg1;
- (id)initWithFrame:(struct CGRect)arg1;
- (void)_DVTAutoLayoutViewSharedInit;

@end