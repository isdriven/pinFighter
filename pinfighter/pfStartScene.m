//
//  pfStartScene.m
//  pinfighter
//
//  Created by fs_01 on 2014/02/19.
//  Copyright (c) 2014年 solGear. All rights reserved.
//

#import "pfStartScene.h"
#import "solCommon.h"

@implementation pfStartScene
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        /* Setup your scene here */

        SKSpriteNode *back = [SKSpriteNode spriteNodeWithColor:[SKColor whiteColor] size:size];
        back.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        back.alpha = 0.0;
        
        [back runAction:[SKAction fadeAlphaBy:1.0 duration:2]];

        [self addChild:back];
        
        SKSpriteNode *title = [[solCommon grip] createSprite:@"title_logo" withName:@"title_logo"];
        title.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)+60);
        
        SKSpriteNode *button = [[solCommon grip] createSprite:@"button_play" withName:@"startButton"];
        button.position = CGPointMake(CGRectGetMidX(self.frame)-20, CGRectGetMidY(self.frame)-50);
        button.xScale = button.yScale = 0.6;
        
        [self addChild:button];
        [self addChild:title];
        
        [[solCommon grip] playBgm:@"bgm_op"];
    }
    return self;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if( [node.name isEqualToString:@"startButton"] ){
        [[solCommon grip] movePage:@"pfBattleScene"
                            parent:self
                              with:[SKTransition doorsOpenHorizontalWithDuration:0.5]];
    }
}
@end

