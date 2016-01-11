//
//  KBWindow.m
//  KBWindowDemo
//
//  Created by 樊远东 on 1/11/16.
//  Copyright © 2016 樊远东. All rights reserved.
//

#import "KBWindow.h"

#define kRecuriveAnimationEnabled NO
#define kDuration .8
#define kDamping 0.75

static CGFloat const kDefaultWindowHeaderHeight = 64.0;

@interface KBWindow ()
@property (nonatomic, assign) CGPoint origin;

@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;

@end

@implementation KBWindow

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor     = [UIColor clearColor];

        self.layer.shadowRadius  = 5.0f;
        self.layer.shadowOffset  = CGSizeZero;
        self.layer.shadowColor   = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.5f;

        self.tapToCloseEnabled   = YES;
        self.tapToOpenEnabled    = YES;
        self.windowHeaderHeight  = kDefaultWindowHeaderHeight;
        
        [self setTapGestureEnabled:YES];
        [self setPanGestureEnabled:YES];
    }
    return self;
}

- (UIWindow *)superWindow {
    NSArray *windows = [UIApplication sharedApplication].windows;
    NSInteger index  = [windows indexOfObjectIdenticalTo:self];
    if (index) {
        if (![NSStringFromClass([windows[index - 1] class]) isEqualToString:@"UITextEffectsWindow"]) {
            return windows[index - 1];
        } else if ((index - 2) >= 0) {
            return windows[index - 2];
        }
    }
    return nil;
}

- (UIWindow *)nextWindow {
    NSArray * windows   = [UIApplication sharedApplication].windows;
    NSInteger index     = [windows indexOfObjectIdenticalTo:self];
    NSInteger nextIndex = index + 1;
    if (nextIndex < windows.count) {
        return windows[nextIndex];
    }
    return nil;
}

#pragma mark - Gesture Recognizer
- (void)setPanGestureEnabled:(BOOL)enabled {
    if (!enabled && [self isPanGestureEnabled]) {
        [self removeGestureRecognizer:self.panGesture];
    } else if (enabled && ![self.gestureRecognizers containsObject:self.panGesture]) {
        [self addGestureRecognizer:self.panGesture];
    }
}

- (BOOL)isPanGestureEnabled {
    return [self.gestureRecognizers containsObject:self.panGesture];
}

- (void)setTapGestureEnabled:(BOOL)enabled {
    if (!enabled && [self isTapGestureEnabled]) {
        [self removeGestureRecognizer:self.tapGesture];
    } else if (enabled && ![self.gestureRecognizers containsObject:self.tapGesture]) {
        [self addGestureRecognizer:self.tapGesture];
    }
}

- (BOOL)isTapGestureEnabled {
    return [self.gestureRecognizers containsObject:self.tapGesture];
}

#pragma mark - Gesture Handler
- (void)onPan:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self];
    CGPoint velocity = [pan velocityInView:self];
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: {
            self.origin = self.frame.origin;
            if (velocity.y == 0 || fabs(velocity.x) > fabs(velocity.y)) {
                [pan setEnabled:NO];
            } else if (self.superWindow && self.superWindow.windowLevel < UIWindowLevelStatusBar) {
                [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
            }
            if (self.superWindow) {
                UIWindow *window = self.superWindow;
                [window addSubview:window.rootViewController.view];
            }
        }
            break;
            
        case UIGestureRecognizerStateChanged: {
            if (self.origin.y + translation.y >= 0) {
                self.transform = CGAffineTransformMakeTranslation(0, translation.y);
                CGFloat percentage = CGRectGetMinY(self.frame) /(CGRectGetHeight([UIScreen mainScreen].bounds) - self.windowHeaderHeight);
                [self updateTransitionAnimationWithPercentage:percentage];
                [self updateNextWindowTranslationIfNeeded];
            }
        }
            break;
            
        case UIGestureRecognizerStateCancelled: {
            [pan setEnabled:YES];
        }
            break;
            
        case UIGestureRecognizerStateEnded: {
            [self transitionToDown:(velocity.y >= 0)];
        }
            break;
            
        default:
            break;
    }
}

- (void)onTap:(UITapGestureRecognizer *)gesture {
    [self showOrClose:NO];
}

#pragma mark - Window Frame
- (void)updateTransitionAnimationWithPercentage:(CGFloat)percentage {
    UIWindow *window = self.superWindow;
    if (window) {
        CGFloat scale = 1.0 - .05 * (1-percentage);
        window.transform = CGAffineTransformMakeScale(scale, scale);
        window.alpha = percentage;
        if (kRecuriveAnimationEnabled && [window respondsToSelector:@selector(updateTransitionAnimationWithPercentage:)]) {
            [(KBWindow *)window updateTransitionAnimationWithPercentage:percentage];
        }
    }
}

- (void)cancelTransition {
    [self becomeKeyWindow];
    [self.rootViewController.view setUserInteractionEnabled:YES];
    UIWindow *window = self.superWindow;
    if (window) {
        window.transform = CGAffineTransformMakeScale(.95, .95);
        window.alpha = 0;
        if (kRecuriveAnimationEnabled && [window respondsToSelector:@selector(cancelTransition)]) {
            [(KBWindow *)window cancelTransition];
        }
    }
    UIWindow *nextWindow = self.nextWindow;
    if (nextWindow) {
        nextWindow.transform = CGAffineTransformIdentity;
    }
    [self updateStatusBarState];
}

- (void)completeTransition {
    [self.rootViewController.view setUserInteractionEnabled:NO];
    UIWindow *window = self.superWindow;
    if (window) {
        [window becomeKeyWindow];
        window.transform = CGAffineTransformIdentity;
        window.frame = [UIScreen mainScreen].bounds;
        window.alpha = 1;
        if (kRecuriveAnimationEnabled && [window respondsToSelector:@selector(completeTransition)]) {
            [(KBWindow *)window completeTransition];
        }
    }
    [self completeNextWindowTranslation];
}

- (void)updateNextWindowTranslationIfNeeded {
    UIWindow *nextWindow = self.nextWindow;
    if (nextWindow) {
        CGFloat diffY = fabs(CGRectGetMinY(nextWindow.frame) - CGRectGetMinY(self.frame));
        if (diffY < self.windowHeaderHeight) {
            nextWindow.transform = CGAffineTransformMakeTranslation(0, self.windowHeaderHeight-diffY);
        }
    }
}

- (void)completeNextWindowTranslation {
    UIWindow *nextWindow = self.nextWindow;
    if (nextWindow) {
        nextWindow.transform = CGAffineTransformMakeTranslation(0, self.windowHeaderHeight);
    }
}

- (void)dismissWindowAnimated:(BOOL)animated completion:(void (^)(void))completion {
    void (^transitionOperations)() = ^{
        [self updateTransitionAnimationWithPercentage:1.0];
        CGRect f = self.frame;
        f.origin.y = [UIScreen mainScreen].bounds.size.height;
        self.frame = f;
    };
    
    if (animated) {
        [UIView animateWithDuration:kDuration delay:0.0 usingSpringWithDamping:kDamping initialSpringVelocity:1  options:UIViewAnimationOptionCurveEaseOut animations:^{
            transitionOperations();
        } completion:^(BOOL finished) {
            [self resignKeyWindow];
            [self removeFromSuperview];
            if (completion) {
                completion();
            }
        }];
    } else {
        transitionOperations();
        [self resignKeyWindow];
        [self removeFromSuperview];
        if (completion) {
            completion();
        }
    }
}

- (void)updateStatusBarState {
    if ([[UIApplication sharedApplication] keyWindow].windowLevel >= UIWindowLevelStatusBar) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
    }
}

- (void)presentWindowAnimated:(BOOL)animated completion:(void (^)(void))completion {
    void (^transitionOperations)() = ^{
        [self updateTransitionAnimationWithPercentage:0.0];
        self.frame = [UIScreen mainScreen].bounds;
    };
    
    if (animated) {
        [UIView animateWithDuration:kDuration delay:0.0 usingSpringWithDamping:kDamping initialSpringVelocity:1  options:UIViewAnimationOptionCurveEaseOut animations:^{
            transitionOperations();
        } completion:^(BOOL finished) {
            [self cancelTransition];
            if (completion) {
                completion();
            }
        }];
    } else {
        transitionOperations();
        [self cancelTransition];
        if (completion) {
            completion();
        }
    }
}

#pragma mark - Tap Gesture
- (void)showOrClose {
    [self showOrClose:YES];
}

- (void)showOrClose:(BOOL)force {
    BOOL shouldGoDown = (self.frame.origin.y == 0);
    if (shouldGoDown && (self.tapToOpenEnabled || force)) {
        if (self.superWindow && self.superWindow.windowLevel < UIWindowLevelStatusBar) {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        }
    }
    if (!shouldGoDown && (self.tapToCloseEnabled || force)) {
        [self transitionToDown:shouldGoDown];
    }
}

#pragma mark - Animated Transition
- (void)transitionToDown:(BOOL)shouldGoDown {
    CGPoint finalOrigin = CGPointZero;
    if (shouldGoDown) {
        finalOrigin.y = CGRectGetHeight([UIScreen mainScreen].bounds) - self.windowHeaderHeight;
    }
    CGRect f = self.frame;
    f.origin = finalOrigin;
    [UIView animateWithDuration:kDuration delay:0.0 usingSpringWithDamping:kDamping initialSpringVelocity:1  options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.transform = CGAffineTransformIdentity;
        self.frame = f;
        if (shouldGoDown) {
            [self completeTransition];
        } else {
            [self cancelTransition];
        }
    } completion:^(BOOL finished) {
        if (shouldGoDown && _dismissWhenOnTheBottomOfTheScreen) {
            [self dismissWindowAnimated:NO completion:nil];
        }
    }];
    
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    return ![self isTapGestureEnabled];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if (gestureRecognizer == self.panGesture) {
        if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
            UIScrollView *tableView = (UIScrollView *)otherGestureRecognizer.view;
            return tableView.contentOffset.y > 0;
        }
    }
    if (gestureRecognizer == self.tapGesture) {
        return YES;
    }
    return NO;
}

+ (void)dismissAllWindows {
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if ([window isKindOfClass:[KBWindow class]]) {
            [(KBWindow *)window dismissWindowAnimated:YES completion:nil];
        }
    }
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    window.frame = [UIScreen mainScreen].bounds;
}

#pragma mark - Getter/Setter
- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPan:)];
        _panGesture.delegate = self;
    }
    return _panGesture;
}

- (UITapGestureRecognizer *)tapGesture {
    if (!_panGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        _tapGesture.delegate = self;
    }
    return _tapGesture;
}

@end
