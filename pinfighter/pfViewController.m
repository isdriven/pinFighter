//
//  pfViewController.m
//  pinfighter
//
//  Created by fs_01 on 2014/02/19.
//  Copyright (c) 2014年 solGear. All rights reserved.
//

#import "pfViewController.h"
#import "pfStartScene.h"


@implementation pfViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    
    SKView *skView = (SKView *)self.view;
    if( !skView.scene){
        skView.showsFPS = YES;
        skView.showsNodeCount = YES;
        
        SKScene * scene = [pfStartScene sceneWithSize:skView.bounds.size];
        scene.scaleMode = SKSceneScaleModeAspectFill;
        [skView presentScene:scene];
    }
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    } else {
        return UIInterfaceOrientationMaskAll;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
