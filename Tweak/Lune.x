#import "Lune.h"

SBFLockScreenDateView* timeDateView = nil;
CSCoverSheetView* coverSheet = nil;

%group Lune

%hook SBFLockScreenDateView

%property(nonatomic, retain)UIImageView* luneView;

- (id)initWithFrame:(CGRect)frame {

	id orig = %orig;
	timeDateView = self;

	return orig;

}

- (void)didMoveToWindow { // add lune

	%orig;

	if ([self luneView]) return;
	self.luneView = [[UIImageView alloc] initWithFrame:CGRectMake([xPositionValue doubleValue], [yPositionValue doubleValue], [sizeValue doubleValue], [sizeValue doubleValue])];
	[[self luneView] setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/Library/PreferenceBundles/LunePrefs.bundle/icon%d.png", [iconValue intValue]]]];
	self.luneView.image = [self.luneView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[[self luneView] setContentMode:UIViewContentModeScaleAspectFill];
	[[self luneView] setAlpha:0.0];

	// color
	if (!useCustomColorSwitch) [[self luneView] setTintColor:[UIColor whiteColor]];
	else if (useCustomColorSwitch) [[self luneView] setTintColor:[SparkColourPickerUtils colourWithString:[preferencesDictionary objectForKey:@"customColor"] withFallback:@"#FFFFFF"]];

	// glow
	if (glowSwitch) {
		if (!useCustomGlowColorSwitch) [[[self luneView] layer] setShadowColor:[[UIColor whiteColor] CGColor]];
		else if (useCustomGlowColorSwitch) [[[self luneView] layer] setShadowColor:[[SparkColourPickerUtils colourWithString:[preferencesDictionary objectForKey:@"customGlowColor"] withFallback:@"#FFFFFF"] CGColor]];
		[[[self luneView] layer] setShadowOffset:CGSizeZero];
		[[[self luneView] layer] setShadowRadius:[glowRadiusValue doubleValue]];
		[[[self luneView] layer] setShadowOpacity:[glowAlphaValue doubleValue]];
	}
	
	[self addSubview:[self luneView]];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleLuneVisibility:) name:@"toggleLuneVisibleNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleLuneVisibility:) name:@"toggleLuneInvisibleNotification" object:nil];

}

%new
- (void)toggleLuneVisibility:(NSNotification *)notification { // toggle visibility

	if ([notification.name isEqual:@"toggleLuneVisibleNotification"]) {
		[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[[self luneView] setAlpha:1.0];
			if (!alwaysDarkenBackgroundSwitch) [[coverSheet luneDimView] setAlpha:[darkeningAmountValue doubleValue]];
		} completion:nil];
	} else if ([notification.name isEqual:@"toggleLuneInvisibleNotification"]) {
		[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
			[[self luneView] setAlpha:0.0];
			if (!alwaysDarkenBackgroundSwitch) [[coverSheet luneDimView] setAlpha:0.0];
		} completion:nil];
	}

}

%end

%hook CSCoverSheetView

%property(nonatomic, retain)UIView* luneDimView;

- (id)initWithFrame:(CGRect)frame {

	id orig = %orig;
	coverSheet = self;

	return orig;

}

- (void)didMoveToWindow { // add dim view

	%orig;

	if (!darkenBackgroundSwitch || [self luneDimView]) return;
	self.luneDimView = [[UIView alloc] initWithFrame:[self bounds]];
	[[self luneDimView] setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[[self luneDimView] setBackgroundColor:[UIColor blackColor]];
	if (!alwaysDarkenBackgroundSwitch) [[self luneDimView] setAlpha:0.0];
	else [[self luneDimView] setAlpha:[darkeningAmountValue doubleValue]];
	[[self luneDimView] setClipsToBounds:YES];
	[self insertSubview:[self luneDimView] atIndex:0];

}

- (void)viewWillAppear:(BOOL)animated { // update lune state when lockscreen appears

	%orig;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"luneRefreshState" object:nil];

}

%end

%hook DNDNotificationsService

- (void)_queue_postOrRemoveNotificationWithUpdatedBehavior:(BOOL)arg1 significantTimeChange:(BOOL)arg2 { // hide dnd banner

	if (hideDNDBannerSwitch)
		return;
	else
		%orig;

}

%end

%hook DNDState

- (id)initWithCoder:(id)arg1 { // add notification observer

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isActive) name:@"luneRefreshState" object:nil];

	return %orig;

}

- (BOOL)isActive { // get do not disturb state

	isDNDActive = %orig;

	if (isDNDActive) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"toggleLuneVisibleNotification" object:nil];
		});
	} else if (!isDNDActive) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"toggleLuneInvisibleNotification" object:nil];
		});
	}

	return isDNDActive;

}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)arg1 { // hide/unhide lune after a respring & reload data

	%orig;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"luneRefreshState" object:nil];
	if (useArtworkBasedColorSwitch) [[%c(SBMediaController) sharedInstance] setNowPlayingInfo:0];

}

%end

%end

%group LuneData

%hook SBMediaController

- (void)setNowPlayingInfo:(id)arg1 { // set artwork based color

    %orig;

    MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef information) {
        if (information) {
            NSDictionary* dict = (__bridge NSDictionary *)information;

            currentArtwork = [UIImage imageWithData:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]]; // set artwork

            if (dict) {
				if (![lastArtworkData isEqual:[dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData]]) {
					// get artwork based color
					backgroundArtworkColor = [libKitten backgroundColor:currentArtwork];

					// set artwork based color
					[[timeDateView luneView] setTintColor:backgroundArtworkColor];
					[[[timeDateView luneView] layer] setShadowColor:[backgroundArtworkColor CGColor]];
				}

				lastArtworkData = [dict objectForKey:(__bridge NSString*)kMRMediaRemoteNowPlayingInfoArtworkData];
            }
        } else { // reset color if not playing
            if (!useCustomColorSwitch) {
				[[timeDateView luneView] setTintColor:[UIColor whiteColor]];
				[[[timeDateView luneView] layer] setShadowColor:[[UIColor whiteColor] CGColor]];
			} else if (useCustomColorSwitch) {
				[[timeDateView luneView] setTintColor:[SparkColourPickerUtils colourWithString:[preferencesDictionary objectForKey:@"customColor"] withFallback:@"#FFFFFF"]];
				if (!useCustomGlowColorSwitch) [[[timeDateView luneView] layer] setShadowColor:[[UIColor whiteColor] CGColor]];
				else if (useCustomGlowColorSwitch) [[[timeDateView luneView] layer] setShadowColor:[[SparkColourPickerUtils colourWithString:[preferencesDictionary objectForKey:@"customGlowColor"] withFallback:@"#FFFFFF"] CGColor]];
			}
        }
  	});
    
}

%end

%end

%ctor {

	preferences = [[HBPreferences alloc] initWithIdentifier:@"love.litten.lunepreferences"];
	preferencesDictionary = [NSDictionary dictionaryWithContentsOfFile: @"/var/mobile/Library/Preferences/love.litten.lune.colorspreferences.plist"];
	
	[preferences registerBool:&enabled default:NO forKey:@"Enabled"];
	if (!enabled) return;

	// icon
	[preferences registerObject:&xPositionValue default:@"150.0" forKey:@"xPosition"];
	[preferences registerObject:&yPositionValue default:@"100.0" forKey:@"yPosition"];
	[preferences registerObject:&sizeValue default:@"50.0" forKey:@"size"];
	[preferences registerObject:&iconValue default:@"0" forKey:@"icon"];

	// glow
	[preferences registerBool:&glowSwitch default:YES forKey:@"glow"];
	if (glowSwitch) {
		[preferences registerBool:&useCustomGlowColorSwitch default:NO forKey:@"useCustomGlowColor"];
		[preferences registerObject:&glowRadiusValue default:@"10.0" forKey:@"glowRadius"];
		[preferences registerObject:&glowAlphaValue default:@"1.0" forKey:@"glowAlpha"];
	}

	// colors
	[preferences registerBool:&useCustomColorSwitch default:NO forKey:@"useCustomColor"];
	[preferences registerBool:&useArtworkBasedColorSwitch default:YES forKey:@"useArtworkBasedColor"];

	// background
	[preferences registerBool:&darkenBackgroundSwitch default:YES forKey:@"darkenBackground"];
	if (darkenBackgroundSwitch) {
		[preferences registerBool:&alwaysDarkenBackgroundSwitch default:NO forKey:@"alwaysDarkenBackground"];
		[preferences registerObject:&darkeningAmountValue default:@"0.5" forKey:@"darkeningAmount"];
	}

	// miscellaneous
	[preferences registerBool:&hideDNDBannerSwitch default:NO forKey:@"hideDNDBanner"];

	%init(Lune);
	if (useArtworkBasedColorSwitch) %init(LuneData);

}