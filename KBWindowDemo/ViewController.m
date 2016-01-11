//
//  ViewController.m
//  KBWindowDemo
//
//  Created by 樊远东 on 1/11/16.
//  Copyright © 2016 樊远东. All rights reserved.
//

#import "ViewController.h"
#import "KBWindow.h"

@interface ViewController ()
@property (nonatomic, strong) KBWindow *window;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIButton *pushButton = [[UIButton alloc] init];
    pushButton.bounds = CGRectMake(0.0, 0.0, 100, 60);
    pushButton.center = self.view.center;
    [pushButton addTarget:self action:@selector(push) forControlEvents:UIControlEventTouchUpInside];
    [pushButton setTitle:@"push" forState:UIControlStateNormal];
    [pushButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:pushButton];
    
    UIButton *dismissButton = [[UIButton alloc] init];
    dismissButton.bounds = CGRectMake(0.0, 0.0, 100, 60);
    dismissButton.center = CGPointMake(self.view.center.x, self.view.center.y + 60.0);
    [dismissButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [dismissButton setTitle:@"dismiss" forState:UIControlStateNormal];
    [dismissButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:dismissButton];
    
    UIButton *presentButton = [[UIButton alloc] init];
    presentButton.frame = CGRectMake(0.0, 00.0, 100, 60);
    [presentButton addTarget:self action:@selector(present) forControlEvents:UIControlEventTouchUpInside];
    [presentButton setTitle:@"present" forState:UIControlStateNormal];
    [presentButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.view addSubview:presentButton];
}

- (void)push {
    CGRect frame = [UIScreen mainScreen].bounds;
    frame.origin.y = CGRectGetHeight([UIScreen mainScreen].bounds);
    self.window = [[KBWindow alloc] initWithFrame:frame];
    self.window.rootViewController = [[ViewController alloc] init];
    self.window.rootViewController.view.backgroundColor = [UIColor greenColor];
    [self.window makeKeyAndVisible];
    [self present];
}

- (void)dismiss {
    [self.window dismissWindowAnimated:YES completion:^{
        NSLog(@"windows = %ld", (long)[UIApplication sharedApplication].windows.count);
    }];
}

- (void)present {
    [self.window presentWindowAnimated:YES completion:^{
        NSLog(@"windows = %ld", (long)[UIApplication sharedApplication].windows.count);
    }];
}

@end
