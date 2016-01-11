//
//  KBWindow.h
//  KBWindowDemo
//
//  Created by 樊远东 on 1/11/16.
//  Copyright © 2016 樊远东. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KBWindow : UIWindow <UIGestureRecognizerDelegate>

@property (nonatomic, assign          ) CGFloat                windowHeaderHeight;
@property (nonatomic, assign          ) BOOL                   dismissWhenOnTheBottomOfTheScreen;
@property (nonatomic, assign          ) BOOL                   tapToCloseEnabled;
@property (nonatomic, assign          ) BOOL                   tapToOpenEnabled;
@property (nonatomic, strong, readonly) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong, readonly) UITapGestureRecognizer *tapGesture;

- (void)dismissWindowAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)presentWindowAnimated:(BOOL)animated completion:(void (^)(void))completion;
- (void)showOrClose;

- (void)setPanGestureEnabled:(BOOL)enabled;
- (BOOL)isPanGestureEnabled;
- (void)setTapGestureEnabled:(BOOL)enabled;
- (BOOL)isTapGestureEnabled;

- (UIWindow *)superWindow;
- (UIWindow *)nextWindow;

+ (void)dismissAllWindows;

@end
