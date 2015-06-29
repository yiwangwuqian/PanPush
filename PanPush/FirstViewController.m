//
//  FirstViewController.m
//  PanPush
//
//  Created by ~DD~ on 15/6/29.
//  Copyright (c) 2015年 ~DD~. All rights reserved.
//

#import "FirstViewController.h"
#import "UINavigationController+PanPush.h"
#import "NextViewController.h"

@interface FirstViewController ()

@end

@implementation FirstViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.navigationController.panPushEnable = YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIViewController *)nowWillPushedViewController
{
    NextViewController *nextViewController = [[NextViewController alloc] initWithNibName:@"NextViewController" bundle:nil];
    return nextViewController;
}

@end
