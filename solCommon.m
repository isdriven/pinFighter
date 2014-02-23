//
//  solCommon.m
//  
//
//  Created by solgear on 2014/02/03.
//  Copyright (c) 2014年 solgear. All rights reserved.
//
// common functions for iphone games
//
// type:singleton
//

#import <SpriteKit/SpriteKit.h>
#import "solCommon.h"


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


@implementation solCommon
+(solCommon *) grip{
    static solCommon *_ins;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,^{
        _ins = [[solCommon alloc] initMe];
    });
    return _ins;
}
-(id)initMe{
    if( self = [super init] ){
        // create bgm fields
        self.bgms = [NSMutableDictionary dictionary];

        
    }
    return self;
}
-(id)init{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

// sprite kit

-(SKSpriteNode *)createSprite:(NSString *)imageName withName:(NSString *)name{
    SKSpriteNode *node = [SKSpriteNode spriteNodeWithImageNamed:imageName];
    node.name = name;
    return node;
}

-(SKSpriteNode *)createSpriteFlipped:(NSString *)imageName withName:(NSString *)name{
    UIImage *_c = [UIImage imageNamed:[NSString stringWithFormat:@"%@",imageName]];
    
    CGImageRef inner = _c.CGImage;
    
    CGContextRef ref = CGBitmapContextCreate(NULL, CGImageGetWidth(inner), CGImageGetHeight(inner), CGImageGetBitsPerComponent(inner), CGImageGetBytesPerRow(inner), CGImageGetColorSpace(inner), CGImageGetBitmapInfo(inner));
    
    CGRect rect = CGRectMake(0, 0, _c.size.width, _c.size.height);

    CGAffineTransform transform = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
    transform = CGAffineTransformScale(transform, -1, 1);

    CGContextConcatCTM(ref, transform);
    
    CGContextDrawImage( ref, rect, inner);

    UIImage *ret = [UIImage imageWithCGImage:CGBitmapContextCreateImage(ref)];

    SKSpriteNode *node = [SKSpriteNode spriteNodeWithTexture:[SKTexture textureWithImage:ret]];
    return node;
}

// imageをxFrameとyFrameで切り出す
-(NSMutableArray *)explodeAtlas:(NSString *)imageName xFrame:(NSNumber *)xFrame yFrame:(NSNumber *)yFrame{
    UIImage *_c = [UIImage imageNamed:imageName];
    
    CGImageRef inner = _c.CGImage;
    int xFrameInt = [xFrame intValue];
    int yFrameInt = [yFrame intValue];
    
    int width = _c.size.width/xFrameInt;
    int height = _c.size.height/yFrameInt;
    float scale = _c.scale;
    
    NSMutableArray *ret = [@[] mutableCopy];
    
    for( int i = 0 ; i < yFrameInt; i++){
        for( int i2 = 0 ; i2 < xFrameInt ; i2++){
            CGRect rect = CGRectMake(
                                     0+(i2*width)*scale,
                                     0+(i*height)*scale,
                                     width*scale,
                                     height*scale);
            CGImageRef ref = CGImageCreateWithImageInRect(inner, rect);
            UIImage *rev = [UIImage imageWithCGImage:ref];
            [ret addObject:[SKTexture textureWithImage:rev]];
            CGImageRelease(ref);
        }
    }
    
    return ret;
}

-(NSMutableArray *)explodeNumbers:(NSNumber *)number{
    int degits = (int)log10([number doubleValue])+1;
    NSString *stringNumbers = [NSString stringWithFormat:@"%d" , [number intValue]];
    
    NSMutableArray *ret = @[].mutableCopy;
    
    for( int i = 0 ; i < degits ; i++ ){
        [ret addObject:[stringNumbers substringWithRange:NSMakeRange(i, 1)]];
    }
    
    return ret;
}

-(SKLabelNode *)createLabel:(NSString *)caption withName:(NSString *)name withColor:(SKColor *)color withFont:(NSString *)font withSize:(float)size at:(CGPoint)point{
    SKLabelNode *myLabel = [SKLabelNode labelNodeWithFontNamed:font];
    
    myLabel.text = caption;
    myLabel.fontSize = size;
    myLabel.position = point;
    return myLabel;
}

-(SKEmitterNode *)createEmitter:(NSString *)name{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"sks"];
    return [NSKeyedUnarchiver unarchiveObjectWithFile:path];
}

-(void)movePage:(NSString *)name parent:(SKScene *)parent with:(SKTransition *)transition{
    SKScene *scene = [[NSClassFromString(name) alloc] initWithSize:parent.size ];
    [parent.view presentScene:scene transition:transition];
}

//before playBgm, stop everything.
-(void)stopBgm{
    if( [self.bgms count] > 0 ){
        for( NSString * key in self.bgms){
            AVAudioPlayer *value = self.bgms[key];
            if( value.playing ){
                [value stop];
            }
        }
    }
}

-(void)playBgm:(NSString *)name{
    [self stopBgm];
    if( !self.bgms[name] ){
        NSError *error;
        NSURL *backgroundMusicUrl = [[NSBundle mainBundle] URLForResource:name withExtension:@"mp3"];
        AVAudioPlayer *backgroundMusicPlayer;
        backgroundMusicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:backgroundMusicUrl error:&error];
        backgroundMusicPlayer.numberOfLoops = -1;
        [backgroundMusicPlayer prepareToPlay];
        self.bgms[name] = backgroundMusicPlayer;
    }
    if( self.bgms[name] ){
        [(AVAudioPlayer *)[self.bgms objectForKey:name] play];
    }
}

-(void)playSe:(NSString *)name on:(SKScene *)scene{
    [scene runAction:[SKAction playSoundFileNamed:name waitForCompletion:NO]];
}

-(NSDictionary *)dataFromJson:(NSString *)name{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *ret = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    return ret;
}

-(void)setUpUserDefaultsSaves{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSDictionary *saves = [ud dictionaryForKey:@"solCommonSaves"];
    
    if( saves == nil ){
        self.userDefaultsSaves = @{}.mutableCopy;
    }else{
        self.userDefaultsSaves = saves.mutableCopy;
    }
}

-(void)saveToUserDefaults:(id)object forKey:(NSString *)key{
    [self setUpUserDefaultsSaves];
    self.userDefaultsSaves[key] = object;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:self.userDefaultsSaves forKey:@"solCommonSaves"];
    [ud synchronize];
}

-(id)loadFromUserDefaults:(NSString *)key{
    [self setUpUserDefaultsSaves];
    return [self.userDefaultsSaves valueForKey:key];
}


@end
