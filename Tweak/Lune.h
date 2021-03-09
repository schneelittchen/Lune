#import <MediaRemote/MediaRemote.h>
#import <Kitten/libKitten.h>
#import "SparkColourPickerUtils.h"
#import <Cephei/HBPreferences.h>

HBPreferences* preferences = nil;
NSDictionary* preferencesDictionary = nil;

BOOL enabled = NO;

BOOL isDNDActive = NO;
UIImage* currentArtwork = nil;
NSData* lastArtworkData = nil;
UIColor* backgroundArtworkColor = nil;

// icon
NSString* xPositionValue = @"150.0";
NSString* yPositionValue = @"100.0";
NSString* sizeValue = @"50.0";
NSString* iconValue = @"0";

// glow
BOOL glowSwitch = YES;
BOOL useCustomGlowColorSwitch = NO;
NSString* glowRadiusValue = @"10.0";
NSString* glowAlphaValue = @"1.0";

// color
BOOL useCustomColorSwitch = NO;
BOOL useArtworkBasedColorSwitch = YES;

// background
BOOL darkenBackgroundSwitch = YES;
BOOL alwaysDarkenBackgroundSwitch = NO;
NSString* darkeningAmountValue = @"0.5";

// miscellaneous
BOOL hideDNDBannerSwitch = NO;

@interface SBFLockScreenDateView : UIView
@property(nonatomic, retain)UIImageView* luneView;
@end

@interface CSCoverSheetView : UIView
@property(nonatomic, retain)UIView* luneDimView;
@end

@interface SBMediaController : NSObject
+ (id)sharedInstance;
- (void)setNowPlayingInfo:(id)arg1;
@end