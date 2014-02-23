//
//  pfBattleScene.m
//  pinfighter
//
//  Created by fs_01 on 2014/02/19.
//  Copyright (c) 2014年 solGear. All rights reserved.
//

static inline CGPoint rwAdd( CGPoint a , CGPoint b ){
    return CGPointMake(a.x+b.x,a.y+b.y);
}

static inline CGPoint rwSub( CGPoint a , CGPoint b ){
    return CGPointMake( a.x - b.x , a.y - b.y );
}

static inline CGPoint rwMult( CGPoint a , float b ){
    return CGPointMake( a.x * b , a.y * b );
}

static inline float rwLength( CGPoint a ){
    return sqrtf(a.x*a.x+a.y*a.y);
}

static inline CGPoint rwNormalize( CGPoint a ){
    float length = rwLength(a);
    return CGPointMake( a.x / length , a.y / length );
}

#import "pfBattleScene.h"
#import "solCommon.h"
#import "YMCPhysicsDebugger.h"

static const uint32_t col_category_world = 0x1 << 0 ;
static const uint32_t col_category_hero = 0x1 << 1 ;
static const uint32_t col_category_foe = 0x1 << 2 ;
static const uint32_t col_category_base = 0x1 << 3;

@interface pfBattleScene()
@property (nonatomic) NSDictionary *config;
@property (nonatomic) NSDictionary *levelMap;
@property (nonatomic) CGPoint touchPoint;
@property (nonatomic) CGPoint heroPoint;
@property (nonatomic) SKSpriteNode *hero;
@property (nonatomic) NSMutableDictionary *emitters;
@property (nonatomic) NSMutableArray *font;
@property (nonatomic) int level;
@property (nonatomic) int remainFoeCount;
@property (nonatomic) int score;
@property (nonatomic) int highScore;
@property (nonatomic) SKLabelNode *scoreLabel;
@property (nonatomic) SKLabelNode *levelLabel;
@property (nonatomic) bool gameCleard;
@property (nonatomic) bool isRetry;
@end

@implementation pfBattleScene

# pragma mark 基本的なメソッド

// 初期化
-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        // ここで初期化メソッドをコール。
        //[YMCPhysicsDebugger init];
        self.isRetry = NO;
        NSLog(@"Frame Size is %f,%f",size.width,size.height);
        [self setUp];
        //[self drawPhysicsBodies];
        
    }
    return self;
}

-(void)didMoveToView:(SKView *)view{
    // ジェスチャーの追加をここで行う
    /* LongPress
    UILongPressGestureRecognizer *longPressGesture =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [view addGestureRecognizer:longPressGesture];
    */
    
    /* SwipeUp
    UISwipeGestureRecognizer* swipeUpGesture =
    [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeUp:)];
    swipeUpGesture.direction = UISwipeGestureRecognizerDirectionUp;
    [view addGestureRecognizer:swipeUpGesture];
     */
}

# pragma mark 検知系メソッド

-(void)didBeginContact:(SKPhysicsContact *)contact{
   
    if( !self.hero ){
        return;
    }

    SKPhysicsBody *firstBody, *secondBody;
    
    if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask) {
        firstBody = contact.bodyA;
        secondBody = contact.bodyB;
    } else {
        firstBody = contact.bodyB;
        secondBody = contact.bodyA;
    }
    
    if( (firstBody.categoryBitMask & col_category_world) != 0 ){
        // contact with wall
        [[solCommon grip] playSe:@"se_pon.wav" on:self];
        self.score += 1;
        [self updateScore];
        
    }else if(  (firstBody.categoryBitMask & col_category_hero) != 0 &&
             (secondBody.categoryBitMask & col_category_foe) != 0 ){
        
        [[solCommon grip] playSe:@"se_slash.wav" on:self];
        
        [self fireEmitter:@"explode1" at:contact.contactPoint];
        
        int power = [self.hero.userData[@"power"] intValue];
        self.hero.userData[@"power"] = @(power-20);
        
        self.score += power;
        [self updateScore];
        
        [self popNumbers:@(power) at:contact.contactPoint];
        [self damage:secondBody.node damage:@(power)];
        
        
        // もし敵が残っていない場合
        if( self.remainFoeCount == 0 ){
            self.level++;
            [self createLevel];
        }
    }else if(  (firstBody.categoryBitMask & col_category_foe) != 0 &&
             (secondBody.categoryBitMask & col_category_base) != 0 ){
        // 下に接触してゲームオーバー
        [self fireEmitter:@"explode1" at:contact.contactPoint];
        [self gameOver];
        [firstBody.node removeFromParent];
    }

}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    if( !self.hero ){
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    
    CGPoint dest = rwSub(location ,self.hero.position);
    dest = rwNormalize(dest);
    dest = rwMult(dest, 15 );
    
    int power = rwLength(dest);
    self.hero.userData[@"power"] = @(10+arc4random()%power);
    
    dest = rwAdd(CGPointMake(self.hero.physicsBody.velocity.dx,self.hero.physicsBody.velocity.dy),dest);
    
    self.hero.physicsBody.velocity = CGVectorMake(dest.x,dest.y);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if( !self.hero ){
        return;
    }
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if( self.gameCleard == YES && [node.name isEqualToString:@"retryButton"] ){
        [self retryEverything];
    }else{
        self.hero.physicsBody.velocity = CGVectorMake(0, 0);
    }
}

#pragma mark メイン機能メソッド

-(void)damage:(SKNode *)foe damage:(NSNumber *)damage{
    int hp = [foe.userData[@"hp"] intValue];
    hp -= [damage intValue];
    if( hp <= 0 ){
        [foe removeFromParent];
        [self fireEmitter:@"explode2" at:foe.position];
        self.remainFoeCount--;
    }else{
        foe.userData[@"hp"] = @(hp);
    }
}

-(void)setUp{
    
    if( self.isRetry == NO){
        // 一回目の読み込み時のみ、各種テクスチャとデータをロード
        
        // 使用する素材関連のテクスチャを作成
        self.emitters = @{}.mutableCopy;
        
        NSMutableArray *explode1 = [[solCommon grip] explodeAtlas:@"y_exp" xFrame:@5 yFrame:@2];
        self.emitters[@"explode1"] = explode1;
        
        NSMutableArray *explode2 = [[solCommon grip] explodeAtlas:@"wave" xFrame:@5 yFrame:@2];
        self.emitters[@"explode2"] = explode2;
        
        NSMutableArray *font = [[solCommon grip] explodeAtlas:@"font" xFrame:@10 yFrame:@1];
        self.font = font;
        
        // 各種値を初期化
        self.touchPoint = CGPointMake(0, 0);
        self.heroPoint = CGPointMake(0, 0);
        
       // json データロード
        NSDictionary *config = [[solCommon grip] dataFromJson:@"config"];
        self.config = config;
        //NSLog(@"%@",config);
    }
    
    // 初期値設定
    self.level = 1;
    self.remainFoeCount = 0;
    self.gameCleard = NO;

    // 物理世界追加
    [self setUpField];

    [self addHero];
    
    // データが存在すれば、ゲーム構築開始
    if( [self.config valueForKey:@"levelMap"]){
        self.levelMap = [self.config valueForKey:@"levelMap"];
        [self createLevel];
    }
    
    // BGM再生
    [[solCommon grip] playBgm:@"bgm_battle"];
}

-(void)updateScore{
    if( self.gameCleard == NO ){
        self.scoreLabel.text = [NSString stringWithFormat:@"%d",self.score];
    }
}

-(void)setUpField{
 
    // 全体世界を設定
    self.physicsWorld.gravity = CGVectorMake(0,-1);
    self.physicsWorld.contactDelegate = self;
    self.physicsBody.categoryBitMask = col_category_world;

    // ゲームフィールド追加
    int fieldWidth = self.frame.size.width - 40;
    int fieldHeight = self.frame.size.height -130;
    int fieldCenter =CGRectGetMidX(self.frame);
    SKSpriteNode *field = [[solCommon grip] createSprite:@"bg_1" withName:@"bg_1"];
    field.size = CGSizeMake(fieldWidth, fieldHeight);
    field.position = CGPointMake(fieldCenter, CGRectGetMidY(self.frame)+30);
    [self addChild:field];

    SKSpriteNode *city = [[solCommon grip] createSprite:@"city" withName:@"city"];
    city.position = CGPointMake(fieldCenter, 150);
    city.xScale = city.yScale = 0.5;
    [self addChild:city];
    
    
    // ゲームフィールドの基本wall追加
    SKSpriteNode *bottomWall = [self addWall:CGSizeMake(fieldWidth,1) at:CGPointMake(field.position.x, field.position.y - fieldHeight/2)];
    bottomWall.physicsBody.categoryBitMask = col_category_base;
    
    [self addWall:CGSizeMake(fieldWidth,1) at:CGPointMake(field.position.x, field.position.y + fieldHeight/2)];
    [self addWall:CGSizeMake(1,fieldHeight) at:CGPointMake(field.position.x - fieldWidth/2 , field.position.y)];
    [self addWall:CGSizeMake(1,fieldHeight) at:CGPointMake(field.position.x + fieldWidth/2 , field.position.y)];
    
    // スコア表示
    self.score = 0;
    SKLabelNode *scoreLabel = [[solCommon grip] createLabel:[NSString stringWithFormat:@"%d",self.score] withName:@"score" withColor:[SKColor whiteColor] withFont:@"Baskerville-BoldItalic" withSize:22 at:CGPointMake(self.frame.size.width-20 , 60 )];
    scoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    self.scoreLabel = scoreLabel;
    [self addChild: scoreLabel];
    
    SKLabelNode *scoreLabelName = [[solCommon grip] createLabel:@"Score:" withName:@"scoreName" withColor:[SKColor whiteColor] withFont:@"Baskerville-BoldItalic" withSize:10 at:CGPointMake( 20 , 60 )];
    scoreLabelName.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    [self addChild: scoreLabelName];
    
    // ハイスコア表示
    NSNumber *highScore = (NSNumber *)[[solCommon grip] loadFromUserDefaults:@"highScore"];
    if( highScore == nil ){
        self.highScore = 0;
    }else{
        self.highScore = [highScore intValue];
    }
    
    SKLabelNode *highScoreLabel = [[solCommon grip] createLabel:[NSString stringWithFormat:@"%d",self.highScore] withName:@"highScore" withColor:[SKColor whiteColor] withFont:@"Baskerville-BoldItalic" withSize:22 at:CGPointMake(self.frame.size.width - 20 , 30 )];
    highScoreLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    [self addChild: highScoreLabel];
    
    SKLabelNode *highScoreLabelName = [[solCommon grip] createLabel:@"High Score:" withName:@"highScoreName" withColor:[SKColor whiteColor] withFont:@"Baskerville-BoldItalic" withSize:10 at:CGPointMake( 20 , 30 )];
    highScoreLabelName.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    [self addChild: highScoreLabelName];
    
    // レベル表示
    SKLabelNode *levelLabel = [[solCommon grip] createLabel:[NSString stringWithFormat:@"Level:%d",self.level] withName:@"level" withColor:[SKColor whiteColor] withFont:@"Baskerville-BoldItalic" withSize:22 at:CGPointMake( 20 , self.frame.size.height - 30 )];
    levelLabel.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeLeft;
    self.levelLabel = levelLabel;
    [self addChild:levelLabel];
                                 
}

-(SKSpriteNode *)addWall:(CGSize)size at:(CGPoint)point{
    SKSpriteNode *wall = [SKSpriteNode spriteNodeWithColor:[SKColor clearColor] size:size];
    wall.position = point;
    wall.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:wall.size];
    wall.physicsBody.dynamic = NO;
    wall.physicsBody.categoryBitMask = col_category_world;
    [self addChild:wall];
    return wall;
}

-(void)createLevel{
    
    // 敵が残っているときは、ステージ生成しない
    if( self.remainFoeCount > 0 ){
        return;
    }
    
    // 現在レベルのlevelMap確認
    NSDictionary *currentMap = [self.levelMap valueForKey:[NSString stringWithFormat:@"level%d",self.level]];

    // レベルがもう存在しない = クリア
    if( currentMap == nil ){
        [self gameClear];
    }
    
    self.levelLabel.text = [NSString stringWithFormat:@"Level:%d",self.level];
    
    // ここで待たないとspritekitが処理しきれず駒落ちするため、durationをもうけること
    [self runAction:[SKAction sequence:@[[SKAction waitForDuration:1],
                                         [SKAction runBlock:^{
        for( NSDictionary *data in currentMap ){
            [self addFoe:data];
        }
    }]]]];
    
   self.remainFoeCount = [currentMap count];
}

-(void)gameClear{
    
    // save High Score
    if( self.score > self.highScore ){
        [[solCommon grip] saveToUserDefaults:@(self.score) forKey:@"highScore"];
    }
    
    self.gameCleard = YES;
    SKSpriteNode *clearTitle = [[solCommon grip] createSprite:@"clear" withName:@"clear"];
    clearTitle.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)+30);
    clearTitle.xScale = clearTitle.yScale = 2;
    clearTitle.alpha = 0;

    SKSpriteNode *retryButton = [[solCommon grip] createSprite:@"retry" withName:@"retryButton"];
    retryButton.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)-30);
    retryButton.xScale = retryButton.yScale = 0.5;
    
    [self addChild: clearTitle];

    [clearTitle runAction:[SKAction sequence:@[
                                            [SKAction group:@[[SKAction fadeAlphaTo:1.0 duration:2],
                                                              [SKAction scaleTo:1.0 duration:2],
                                                              [SKAction rotateByAngle:18.3 duration:1]]],
                                            [SKAction runBlock:^{
        [self addChild:retryButton];
    }]]]];

}

-(void)gameOver{
    
    // save High Score
    if( self.score > self.highScore ){
        [[solCommon grip] saveToUserDefaults:@(self.score) forKey:@"highScore"];
    }
    
    self.gameCleard = YES;
    SKSpriteNode *clearTitle = [[solCommon grip] createSprite:@"gameover" withName:@"gameover"];
    clearTitle.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)+30);
    clearTitle.xScale = clearTitle.yScale = 2;
    clearTitle.alpha = 0;
    
    SKSpriteNode *retryButton = [[solCommon grip] createSprite:@"retry" withName:@"retryButton"];
    retryButton.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame)-50);
    retryButton.xScale = retryButton.yScale = 0.5;
    
    [self addChild: clearTitle];
    
    [clearTitle runAction:[SKAction sequence:@[
                                               [SKAction group:@[[SKAction fadeAlphaTo:1.0 duration:2],
                                                                 [SKAction scaleTo:1.0 duration:2],
                                                                 [SKAction rotateByAngle:18.3 duration:1]]],
                                               [SKAction runBlock:^{
        [self addChild:retryButton];
    }]]]];
    
}

-(void)retryEverything{
    [self removeAllChildren];
    [self removeAllActions];
    self.isRetry = YES;
    [self setUp];
}

// add hero
-(void)addHero{
    SKSpriteNode *hero = [[solCommon grip] createSprite:@"ghost" withName:@"ghost"];
    hero.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:CGSizeMake(40,40)];
    hero.physicsBody.categoryBitMask = col_category_hero;
    hero.physicsBody.contactTestBitMask = col_category_foe|col_category_world;
    hero.physicsBody.dynamic = NO;
    hero.position = CGPointMake(CGRectGetMidX(self.frame), 120);
    hero.physicsBody.mass = 2;
    
    hero.userData = [@{@"hp": @2,@"power":@"10"} mutableCopy];
    
    [self addChild: hero];
    
    [hero runAction:[SKAction sequence:@[
                                         [SKAction moveTo:CGPointMake(CGRectGetMidX(self.frame), 170) duration:1],
                                         [SKAction runBlock:^{
        self.hero = hero;
        self.hero.physicsBody.dynamic = YES;
    }]]]];
}

// add foe
-(void)addFoe:(NSDictionary *)data{
    SKSpriteNode *foe = [[solCommon grip] createSprite:data[@"type"] withName:data[@"type"]];

    foe.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:20];
    //foe.physicsBody.affectedByGravity = YES;
    foe.physicsBody.restitution = 1.0f;
    foe.physicsBody.linearDamping = 1;
    foe.physicsBody.friction = 1;
    foe.physicsBody.usesPreciseCollisionDetection = YES;
    foe.physicsBody.categoryBitMask = col_category_foe;
    foe.physicsBody.contactTestBitMask = col_category_foe | col_category_hero | col_category_base;
    foe.physicsBody.mass = [(NSString *)data[@"mass"] intValue];
    
    //[self addChild:foe];
    
    foe.userData = [@{@"hp":@([(NSString *)data[@"hp"] intValue])} mutableCopy];

    CGPoint pos = CGPointMake(CGRectGetMidX(self.frame)+[(NSString *)data[@"x"] intValue],
                              CGRectGetMidY(self.frame)+[(NSString *)data[@"y"] intValue]);

    foe.position = pos;

    [self addChild: foe];
}


# pragma mark 汎用パーツメソッド
-(void)popNumbers:(NSNumber *)number at:(CGPoint)pointAt{
    NSMutableArray *stringNumbers = [[solCommon grip] explodeNumbers:number];
    int degits = (int)[stringNumbers count];
    
    if( self.font ){
        int textureWidth = ((SKTexture *)self.font[0]).size.width;
        textureWidth /=2;

        SKAction *fontAction = [SKAction sequence:@[[SKAction moveByX:0 y:5 duration:0.2],
                                                    [SKAction moveByX:0 y:-10 duration:1],
                                                    [SKAction removeFromParent]]];
        
        int index = 0;
        for( NSString *value in stringNumbers){
            SKSpriteNode *font = [SKSpriteNode spriteNodeWithTexture:self.font[[value intValue]]];
            font.position = CGPointMake(((pointAt.x-(degits*(textureWidth/2)))+(index*textureWidth)), pointAt.y);
            [self addChild:font];
            [font runAction:fontAction];
            index++;
        }
    }
}

-(void)fireEmitter:(NSString *)name at:(CGPoint)point{
    if( [self.emitters valueForKey:name] ){
        NSMutableArray *textures = self.emitters[name];
        SKSpriteNode *emitter = [SKSpriteNode spriteNodeWithTexture:textures[0]];
        emitter.position = point;
        [self addChild:emitter];
        [emitter runAction:[SKAction sequence:@[[SKAction animateWithTextures:textures timePerFrame:0.05f],
                                                [SKAction removeFromParent]]]];
        
    }
}


@end
