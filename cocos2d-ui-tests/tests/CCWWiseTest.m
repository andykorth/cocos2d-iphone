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
    [w loadBank:@"Resources-shared/WwiseContent/InteractiveMusic.bnk"];
    
    
    
}


@end

