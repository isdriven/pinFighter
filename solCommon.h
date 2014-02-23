//
//  solCommon.h
//
//  Created by solgear on 2014/02/03.
//  Copyright (c) 2014年 solgear. All rights reserved.
//
//  Common functions for iphone games

#import <Foundation/Foundation.h>
#import <SpriteKit/SpriteKit.h>
@import AVFoundation;

@interface solCommon : NSObject

@property (nonatomic) NSMutableDictionary *bgms;
@property (nonatomic) NSMutableDictionary *userDefaultsSaves;

+(solCommon *)grip;

#pragma mark Sprite Kit Sprites and Emitters

-(SKSpriteNode *)createSprite:(NSString *)imageName withName:(NSString *)name;
-(SKSpriteNode *)createSpriteFlipped:(NSString *)imageName withName:(NSString *)name;
-(SKLabelNode *)createLabel:(NSString *)caption withName:(NSString *)name withColor:(SKColor *)color withFont:(NSString *)font withSize:(float)size at:(CGPoint)point;
-(SKEmitterNode *)createEmitter:(NSString *)name;

-(NSMutableArray *)explodeAtlas:(NSString *)imageName xFrame:(NSNumber *)xFrame yFrame:(NSNumber *)yFrame;
-(NSMutableArray *)explodeNumbers:(NSNumber *)number;

#pragma mark Sprite Kit other functions

-(void)movePage:(NSString *)name parent:(SKScene *)parent with:(SKTransition *)transition;

#pragma mark BGMs and SEs

-(void)playBgm:(NSString *)name;
-(void)playSe:(NSString *)name on:(SKScene *)scene;

# pragma mark data management

-(NSDictionary *)dataFromJson:(NSString *)name;

-(void)saveToUserDefaults:(id)object forKey:(NSString *)key;

-(id)loadFromUserDefaults:(NSString *)key;

@end
