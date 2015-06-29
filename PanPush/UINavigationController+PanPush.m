//
//  UINavigationController+PanPush.m
//  PeopleDaily
//
//  Created by ~DD~ on 15/4/23.
//  Copyright (c) 2015年 people.com.cn. All rights reserved.
//

#import "UINavigationController+PanPush.h"
#import <sys/utsname.h>
#import <objc/runtime.h>

NSString *const UINavigationControllerPanPushEnableAssocationKey = @"UINavigationControllerPanPushEnableAssocationKey";
NSString *const UINavigationControllerPanRecognizerAssocationKey = @"UINavigationControllerPanRecognizerAssocationKey";

@implementation UINavigationController(PanPush)

- (void)setPanPushEnable:(BOOL)panPushEnable
{
    if (panPushEnable){
        UIPanGestureRecognizer *panRecognizer = objc_getAssociatedObject(self, &UINavigationControllerPanRecognizerAssocationKey);
        if (!panRecognizer){
            panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                    action:@selector(viewIsPaned:)];
            [self.view addGestureRecognizer:panRecognizer];
            
            if ([self respondsToSelector:@selector(interactivePopGestureRecognizer)]){
                [panRecognizer performSelector:@selector(requireGestureRecognizerToFail:)
                                    withObject:self.interactivePopGestureRecognizer];
            }
            objc_setAssociatedObject(self, &UINavigationControllerPanRecognizerAssocationKey, panRecognizer, OBJC_ASSOCIATION_RETAIN);
        }
    }else{
        //assign recognizer nil.
        UIPanGestureRecognizer *panRecognizer = objc_getAssociatedObject(self, &UINavigationControllerPanRecognizerAssocationKey);
        if (panRecognizer){
            [self.view removeGestureRecognizer:panRecognizer];
            [panRecognizer removeTarget:nil
                                 action:NULL];
        }
        objc_setAssociatedObject(self, &UINavigationControllerPanRecognizerAssocationKey, nil, OBJC_ASSOCIATION_RETAIN);
    }
    objc_setAssociatedObject(self, &UINavigationControllerPanPushEnableAssocationKey, [NSNumber numberWithBool:panPushEnable], OBJC_ASSOCIATION_COPY);
}

- (BOOL)panPushEnable
{
    NSNumber *enableNumber = objc_getAssociatedObject(self, &UINavigationControllerPanPushEnableAssocationKey);

    if (enableNumber){
        return [enableNumber boolValue];
    }
    
    return NO;
}

#pragma mark- Private methods

- (void)resetParentControllerViewPosition:(UIViewController *)controller
{
    controller.view.frame = CGRectMake(0,
                                       CGRectGetMinY(controller.view.frame),
                                       CGRectGetWidth(controller.view.frame),
                                       CGRectGetHeight(controller.view.frame));
}

/**
 Check whether to push or not,start point must in range (4/5.0,1.0) of view's width.
 */
- (BOOL)isValidStartPoint:(CGPoint)point
{
    if (point.x < 4/5.0 * CGRectGetWidth(self.view.bounds)){
        return NO;
    }
    
    return YES;
}

/**
 Finish move,adjust view's position
 */
- (void)moveEndAdjustViewPosition
{
    UINavigationController *__weak weakSelf = self;
    UIViewController *parentController = [self.viewControllers lastObject];
    
    CGRect newRect = nextController.view.frame;
    CGRect pNewRect = parentController.view.frame;
    CGFloat originXDelta = 0;
    if (newRect.origin.x < CGRectGetWidth(self.view.bounds)/2 ){
        //Success,makes it become last one in viewControllers
        newRect.origin.x = 0;
        originXDelta = abs(CGRectGetMinX(nextController.view.frame));
        pNewRect.origin.x = - CGRectGetWidth(self.view.bounds)*0.3;
        
        [UIView animateWithDuration:1*originXDelta/CGRectGetWidth(self.view.bounds)  animations:^{
            nextController.view.frame = newRect;
            parentController.view.frame = pNewRect;
        } completion:^(BOOL finished) {
            if (finished){
                NSMutableArray *controllers = [NSMutableArray arrayWithArray:weakSelf.viewControllers];
                [controllers addObject:nextController];
                weakSelf.viewControllers = controllers;
                nextController = nil;
                [weakSelf performSelector:@selector(resetParentControllerViewPosition:)
                               withObject:parentController
                               afterDelay:0.1];
            }
        }];
    }else{
        //Failure, back to origin
        newRect.origin.x = CGRectGetWidth(self.view.bounds);
        originXDelta = abs(CGRectGetWidth(self.view.bounds) - CGRectGetMinX(nextController.view.frame));
        pNewRect.origin.x = 0;
        CGFloat duration = 1*originXDelta/CGRectGetWidth(self.view.bounds);
        
        [UIView animateWithDuration:duration animations:^{
            nextController.view.frame = newRect;
            parentController.view.frame = pNewRect;
        } completion:^(BOOL finished) {
            if (finished){
                [nextController.view removeFromSuperview];
                nextController = nil;
                [weakSelf performSelector:@selector(resetParentControllerViewPosition:)
                               withObject:parentController
                               afterDelay:0.1];
            }
        }];
    }
}

static UIViewController *nextController;

- (void)viewIsPaned:(UIPanGestureRecognizer *)sender
{
    if (!self.viewControllers.count){
        return;
    }
    
    if (sender.state == UIGestureRecognizerStateCancelled |
        sender.state == UIGestureRecognizerStateEnded |
        sender.state == UIGestureRecognizerStateFailed |
        sender.state == UIGestureRecognizerStateRecognized){
        
        //Finish moving
        if (!nextController){
            return;
        }
        
        [self moveEndAdjustViewPosition];
    }else if (sender.state == UIGestureRecognizerStateBegan){
        
        CGPoint originPoint = [sender locationInView:self.view];
        if (![self isValidStartPoint:originPoint]){
            return;
        }
        
        UIViewController *parentController = [self.viewControllers lastObject];
        nextController = [parentController nowWillPushedViewController];
        
        if (!nextController){
            return;
        }else{
            CGRect newRect = nextController.view.frame;
            newRect.origin.x = CGRectGetWidth(self.view.bounds);
            nextController.view.frame = newRect;
            
            [self.view insertSubview:nextController.view
                        aboveSubview:self.navigationBar];
        }
    }else{
        if (!nextController){
            return;
        }
        
        //Now is moving
        CGRect newRect = nextController.view.frame;
        newRect.origin.x = [sender locationInView:self.view].x;
        nextController.view.frame = newRect;
        
        UIViewController *parentController = [self.viewControllers lastObject];
        CGRect pNewRect = parentController.view.frame;
        pNewRect.origin.x = -(CGRectGetWidth(self.view.bounds)  - newRect.origin.x)*0.3;
        parentController.view.frame = pNewRect;
    }
}

@end

@implementation UIViewController(PanPush)

- (UIViewController *)nowWillPushedViewController
{
    return nil;
}

@end

