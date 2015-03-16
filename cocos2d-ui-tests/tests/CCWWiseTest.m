#import "TestBase.h"
#import "CCTextureCache.h"
#import "CCNodeColor.h"
#import "CCWwise.h"


@interface CCWWiseTest : TestBase @end
@implementation CCWWiseTest


-(void)setupInteractiveMusicTest
{
	self.subTitle =	@"WWise integration. Interactive music demo.";
    
    CCWwise *w = [CCWwise sharedManager];
    [w loadBank:@"Init.bnk"];
    [w loadBank:@"InteractiveMusic.bnk"];
    
    [w registerGameObject:self];

    [w postEvent:@"IM_START" forGameObject:self];
    //
    
    [self addButton:@"Explore" withEvent:@"IM_EXPLORE" at:0.8];
    [self addButton:@"Begin communication" withEvent:@"IM_COMMUNICATION_BEGIN" at:0.7];
    [self addButton:@"Hostile Enemies" withEvent:@"IM_THEYAREHOSTILE" at:0.6];
    [self addButton:@"Fighting Enemy" withEvent:@"IM_1_ONE_ENEMY_WANTS_TO_FIGHT" at:0.5];
    [self addButton:@"Many Enemies" withEvent:@"IM_3_SURRONDED_BY_ENEMIES" at:0.4];
    [self addButton:@"Game Over" withEvent:@"IM_GAMEOVER" at:0.3];
    [self addButton:@"Win the fight" withEvent:@"IM_WINTHEFIGHT" at:0.2];

}

-(void) addButton:(NSString *)title withEvent:(NSString *) event at:(float) p
{
    CCButton *b = [CCButton buttonWithTitle:title];
    b.positionType = CCPositionTypeNormalized;
    b.position = ccp(0.5, p);
    [b setBlock:^(id d){
        [[CCWwise sharedManager] postEvent:event forGameObject:self];
    }];
    [self.contentNode addChild:b];
}


-(void)update:(CCTime)delta
{
    [[CCWwise sharedManager] RenderAudio];
}

-(void) onExit
{
    [[CCWwise sharedManager] terminate];
    [super onExit];
}

@end

