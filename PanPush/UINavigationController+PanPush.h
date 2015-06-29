//
//  UINavigationController+PanPush.h
//  PeopleDaily
//
//  Created by ~DD~ on 15/4/23.
//  Copyright (c) 2015年 people.com.cn. All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 Extension for UINavigationController,makes left pan guesture could push someone controller.
 */
@interface UINavigationController(PanPush)

/**
 @brief Enable left pan push controllers.
 */
@property (nonatomic, assign) BOOL        panPushEnable;

@end

@interface UIViewController(PanPush)
/**
 @brief Provide to subclass of UIViewController,when panPushEnable assined YES you left pan controller's view this method will be called.
 
 @return controller needs to push.
 */
- (UIViewController *)nowWillPushedViewController;

@end
