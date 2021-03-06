//
//  TopPanelViewController.m
//  DanMuPlayer
//
//  Created by zfu on 2019/3/16.
//  Copyright © 2019 zfu. All rights reserved.
//

#import "TopPanelViewController.h"
#import "InfoPanelViewController.h"
#import "AudioInfoViewController.h"
#import "PlayerControlViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "TabBarTransitionAnimator.h"
#import "PopUPAnimator.h"

@interface TopPanelViewController () {
    InfoPanelViewController *infovc;
    CurrentMediaInfo *currentMediaInfo;
    DMPlaylist *playlist;
    UITapGestureRecognizer *tapGestureRecognizer;
    UISwipeGestureRecognizer *swipeGestureRecognizer;
    BOOL dissmissed;
    UITabBarController *tabBarController;
    clickCallBack buttonCallback;
    NSInteger focusIndex;
    BOOL canDissmiss;
    BOOL willDissmiss;
}
@end

@implementation TopPanelViewController
@synthesize delegate;
@synthesize controlData;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    tabBarController = [[UITabBarController alloc] init];
//    UITabBar *tabBar = tabBarController.tabBar;
//    tabBar.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    //info
    NSMutableArray<UIViewController*> *vcs = [NSMutableArray array];
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.fuzhuo.DanMuPlayer"];
    infovc = [[InfoPanelViewController alloc] initWithNibName:@"InfoPanelViewController" bundle:bundle];
    infovc.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"信息" image:nil tag:0];
    [infovc updateMediaInfo:currentMediaInfo];
    [vcs addObject:infovc];
    
    //control
    PlayerControlViewController *controlVC = [[PlayerControlViewController alloc] initWithNibName:@"PlayerControlViewController"
                                                                                           bundle:bundle];
    controlVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"控制" image:nil tag:0];
    controlVC.delegate = self.delegate;
    controlVC.controlData = self.controlData;
    [vcs addObject:controlVC];
    
    if (playlist && playlist.items.count>0) {
        EpisodeViewController *episodeVC = [[EpisodeViewController alloc] initWithNibName:@"EpisodeViewController" bundle:bundle];
        [episodeVC setupPlayList:playlist clickCallBack:buttonCallback focusIndex:focusIndex];
        episodeVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"选集" image:nil tag:0];
        [vcs addObject:episodeVC];
        [tabBarController setSelectedIndex:vcs.count-1];
    }
    
    //audio
    AudioInfoViewController *audioVC = [[AudioInfoViewController alloc] initWithNibName:@"AudioInfoViewController" bundle:bundle];
    audioVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"音频" image:nil tag:0];
    audioVC.view.frame = CGRectMake(0, 0, self.view.frame.size.width, 600);
    [vcs addObject:audioVC];

    tabBarController.viewControllers = vcs;
    [self addChildViewController:tabBarController];
    [self.view addSubview:tabBarController.view];
    [tabBarController didMoveToParentViewController:self];
    [self changeBarBackground:tabBarController];

    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapKey:)];
    tapGestureRecognizer.allowedPressTypes = @[
                                               @(UIPressTypeUpArrow),
                                               @(UIPressTypeMenu),
                                               ];
    [self.view addGestureRecognizer:tapGestureRecognizer];

    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipUp:)];
    [swipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionUp];
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    
    tabBarController.delegate = self;
    dissmissed = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view removeGestureRecognizer:tapGestureRecognizer];
    [self.view removeGestureRecognizer:swipeGestureRecognizer];
}

- (void)swipUp:(UISwipeGestureRecognizer*)sender {
    NSLog(@"swipUp");
    if (canDissmiss) {
        [self dissmiss];
    }
}

- (void)tapKey:(UITapGestureRecognizer*)sender {
    if (willDissmiss && canDissmiss) {
        [self dissmiss];
    }
    if (canDissmiss) {
        willDissmiss = YES;
    }
}

- (void)dissmiss {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(swipUp:) object:self.presentationController];
    if (!dissmissed) {
        dissmissed = YES;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [tabBarController setSelectedIndex:controlData.focusedIndex];
}

- (void)changeBarBackground:(UITabBarController*)tabController {
    //repalce backgroundView of tabBar
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    UIVisualEffectView *bgView = [[UIVisualEffectView alloc] initWithEffect:effect];
    UITabBar *tabBar = tabController.tabBar;
    NSString *name = @"groundView:_setBack";
    NSString *final = [NSString stringWithFormat:@"%@%@", [name substringFromIndex:11], [name substringToIndex:11]];
    SEL bgsel = NSSelectorFromString(final);
    if ([tabBar respondsToSelector:bgsel]) {
        ((void (*)(id, SEL, id))objc_msgSend)(tabBar, bgsel, bgView);
    }
    
    UIVibrancyEffect *vibEffect = [UIVibrancyEffect effectForBlurEffect:effect];
    UIVisualEffectView *seperater = [[UIVisualEffectView alloc] initWithEffect:vibEffect];
    seperater.frame = CGRectMake(0, 140, self.view.frame.size.width, 1);
    [self.view addSubview:seperater];
    
    UIView *lineview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    lineview.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.3];
    [seperater.contentView addSubview:lineview];
}

- (void)setCurrentMediaInfo:(CurrentMediaInfo*)mediaInfo {
    currentMediaInfo = [[CurrentMediaInfo alloc] initWithMediaInfo:mediaInfo];
}

- (id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController animationControllerForTransitionFromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    NSInteger fromIdx = -1;
    NSInteger toIdx = -1;
    NSInteger idx = 0;
    for (UIViewController *vc in tabBarController.viewControllers) {
        if (vc==fromVC) fromIdx = idx;
        if (vc==toVC) toIdx = idx;
        idx++;
    }
    BOOL rightDirection = toIdx > fromIdx;
    TabBarTransitionAnimator *animator = [[TabBarTransitionAnimator alloc] initWithFromViewController:fromVC
                                                                                     toViewController:toVC
                                                                                             duration:0.3
                                                                                          rightToLeft:rightDirection];
    return animator;
}

- (void)setupPlayList:(DMPlaylist*)playlist_ clickCallBack:(clickCallBack)callback_ focusIndex:(NSInteger)focusIndex_ {
    playlist = playlist_;
    buttonCallback = callback_;
    focusIndex = focusIndex_;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    NSLog(@"tabBar did select view controller %@", viewController);
    controlData.focusedIndex = tabBarController.selectedIndex;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator {
//    NSLog(@"didUpdateFocusInContext %@", context);
    willDissmiss = NO;
    if ([context.nextFocusedItem isKindOfClass:NSClassFromString(@"UITabBarButton")]) {
        canDissmiss = YES;
        if ([context.previouslyFocusedItem isKindOfClass:NSClassFromString(@"UITabBarButton")]
            || context.previouslyFocusedItem == nil) {
            willDissmiss = YES;
        }
    } else {
        canDissmiss = NO;
    }
}
@end

