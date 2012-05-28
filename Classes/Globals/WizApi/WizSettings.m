//
//  WizSettings.m
//  Wiz
//
//  Created by 朝 董 on 12-4-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WizSettings.h"
#import "WizDbManager.h"

#define WizServerUrlString  @"WizServerUrl"
#define WizPasscode         @"WizPasscode"
#define WizPasscodeEnable   @"WizPasscodeEnable"
#define WizEraseDataEnable  @"WizEraseDataEnable"

@interface WizSettings ()
{
    MKPlacemark* currentPlaceMark;
    CLLocation* currentLocation;
    CLLocationManager* locationManager;
}
@property (atomic, retain) MKPlacemark* currentPlaceMark;
@property (atomic, retain) CLLocation* currentLocation;
@end

@implementation WizSettings
@synthesize settingsDbDelegate;
@synthesize currentLocation;
@synthesize currentPlaceMark;
//single object
static WizSettings* defaultSettings = nil;
- (void) dealloc
{
    [locationManager release];
    [currentLocation release];
    [currentPlaceMark release];
    [super dealloc];
}
+ (id) defaultSettings
{
    @synchronized(defaultSettings)
    {
        if (defaultSettings == nil) {
            defaultSettings = [[super allocWithZone:NULL] init];
        }
        return defaultSettings;
    }
}
+ (id) allocWithZone:(NSZone *)zone
{
    return [[self defaultSettings] retain];
}
- (id) retain
{
    return self;
}
- (NSUInteger) retainCount
{
    return NSUIntegerMax;
}
- (id) copyWithZone:(NSZone*)zone
{
    return self;
}
- (id) autorelease
{
    return self;
}
- (oneway void) release
{
    return;
}
// over

- (void)startedReverseGeoderWithLatitude:(double)latitude longitude:(double)longitude{
    CLLocationCoordinate2D coordinate2D;
    coordinate2D.longitude = longitude;
    coordinate2D.latitude = latitude;
    MKReverseGeocoder *geoCoder = [[MKReverseGeocoder alloc] initWithCoordinate:coordinate2D];
    geoCoder.delegate = self;
    [geoCoder start];
}
- (void) reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark *)placemark
{
    NSLog(@"city %@",placemark.locality);
    self.currentPlaceMark = placemark;
}
- (void) reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError *)error
{
    NSLog(@"failed %@",error);
}
- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [manager stopUpdatingLocation];
    self.currentLocation = newLocation;
    CLLocationDistance l = newLocation.coordinate.latitude;//得到经度
    CLLocationDistance v = newLocation.coordinate.longitude;//得到纬度
    [self startedReverseGeoderWithLatitude: l longitude: v];
}
- (MKPlacemark*) getCurrentPlaceMark
{
    return self.currentPlaceMark;
}

- (CLLocation*) getCurrentLocation
{
    return self.currentLocation;
}
- (void) startLocationReg
{

    if ([locationManager locationServicesEnabled]) {
        locationManager.delegate = self;
        locationManager.distanceFilter = 200;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];
    }
}

- (id) init
{
    self = [super init];
    if (self) {
        self.settingsDbDelegate = [WizDbManager shareDbManager];
        locationManager = [[CLLocationManager alloc] init];
        NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:600 target:self selector:@selector(startLocationReg) userInfo:nil repeats:YES];
        [timer fire];
    }
    return self;
}

- (int64_t) wizDataBaseVersion
{
    return [self.settingsDbDelegate wizDataBaseVersion];
}
- (BOOL) setWizDataBaseVersion:(int64_t)ver
{
    return [self.settingsDbDelegate setWizDataBaseVersion:ver];
}
//settings
- (int64_t) imageQualityValue
{
    return [self.settingsDbDelegate imageQualityValue];
}
- (BOOL) setImageQualityValue:(int64_t)value
{
    return [self.settingsDbDelegate setImageQualityValue:value];
}
//
- (BOOL) connectOnlyViaWifi
{
    return [self.settingsDbDelegate connectOnlyViaWifi];
}
- (BOOL) setConnectOnlyViaWifi:(BOOL)wifi
{
    return [self.settingsDbDelegate setConnectOnlyViaWifi:wifi];
}
//
- (BOOL) setUserTableListViewOption:(int64_t)option
{
    return [self.settingsDbDelegate setUserTableListViewOption:option];
}
- (int64_t) userTablelistViewOption
{
    int64_t ret = [self.settingsDbDelegate userTablelistViewOption];
    if (ret < 1) {
        [self setUserTableListViewOption:2];
    }
    return [self.settingsDbDelegate userTablelistViewOption];
}
//
- (int) webFontSize
{
    return [self.settingsDbDelegate webFontSize];
}
- (BOOL) setWebFontSize:(int)fontsize
{
    return [self.settingsDbDelegate setWebFontSize:fontsize];
}
//
- (NSString*) wizUpgradeAppVersion
{
    return [self.settingsDbDelegate wizUpgradeAppVersion];
}
- (BOOL) setWizUpgradeAppVersion:(NSString*)ver
{
    return [self.settingsDbDelegate setWizUpgradeAppVersion:ver];
}
- (int64_t) durationForDownloadDocument
{
    return [self.settingsDbDelegate durationForDownloadDocument];
}
- (NSString*) durationForDownloadDocumentString
{
    return [self.settingsDbDelegate durationForDownloadDocumentString];
}
- (BOOL) setDurationForDownloadDocument:(int64_t)duration
{
    return [self.settingsDbDelegate setDurationForDownloadDocument:duration];
}
- (BOOL) isMoblieView
{
    return [self.settingsDbDelegate isMoblieView];
}
- (BOOL) isFirstLog
{
    return [self.settingsDbDelegate isFirstLog];
}
- (BOOL) setFirstLog:(BOOL)first
{
    return [self.settingsDbDelegate setFirstLog:first];
}
- (BOOL) setDocumentMoblleView:(BOOL)mobileView
{
    return [self.settingsDbDelegate setDocumentMoblleView:mobileView];
}
- (int64_t) userTrafficLimit
{
    return [self.settingsDbDelegate userTrafficLimit];
}
- (BOOL) setUserTrafficLimit:(int64_t)ver
{
    return [self.settingsDbDelegate setUserTrafficLimit:ver];
}
- (NSString*) userTrafficLimitString
{
    return [self.settingsDbDelegate userTrafficLimitString];
}
//
- (int64_t) userTrafficUsage
{
    return [self.settingsDbDelegate userTrafficUsage];
}
- (NSString*) userTrafficUsageString
{
    return [self.settingsDbDelegate userTrafficUsageString];
}
- (BOOL) setuserTrafficUsage:(int64_t)ver
{
    return [self.settingsDbDelegate setuserTrafficUsage:ver];
}
//
- (BOOL) setUserLevel:(int)ver
{
    return [self.settingsDbDelegate setUserLevel:ver];
}
- (int) userLevel
{
    return [self.settingsDbDelegate userLevel];
}
//
- (BOOL) setUserLevelName:(NSString*)levelName
{
    return [self.settingsDbDelegate setUserLevelName:levelName];
}
- (NSString*) userLevelName
{
    return [self.settingsDbDelegate userLevelName];
}
//
- (BOOL) setUserType:(NSString*)userType
{
    return [self.settingsDbDelegate setUserType:userType];
}
- (NSString*) userType
{
    return [self.settingsDbDelegate userType];
}
//
- (BOOL) setUserPoints:(int64_t)ver
{
    return [self.settingsDbDelegate setUserPoints:ver];
}
- (int64_t) userPoints
{
    return [self.settingsDbDelegate userPoints];
}
- (NSString*) userPointsString
{
    return [self.settingsDbDelegate userPointsString];
}
- (NSURL*) wizServerUrl
{
    return [[[NSURL alloc] initWithString:@"http://service.wiz.cn/wizkm/xmlrpc"] autorelease];
//    return [[NSURL alloc] initWithString:@"http://192.168.1.155:8800/wiz/xmlrpc"];
}
//
- (BOOL) setAutomicSync:(BOOL)automic
{
    return [self.settingsDbDelegate setAutomicSync:automic];
}
- (BOOL) isAutomicSync
{
    return [self.settingsDbDelegate isAutomicSync];
}
//
- (void) setPasscode:(NSString*)passcode
{
    [[NSUserDefaults standardUserDefaults] setObject:passcode forKey:WizPasscode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString*) passCode
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:WizPasscode];
}

- (void) setPasscodeEnable:(BOOL) enable
{
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:WizPasscodeEnable];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) isPasscodeEnable
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:WizPasscodeEnable];
}

- (void) setEraseDataEnable:(BOOL)enable
{
    [[NSUserDefaults standardUserDefaults] setBool:enable forKey:WizEraseDataEnable];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
- (BOOL) isEraseDataEnable
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:WizEraseDataEnable];
}
//
- (BOOL) setLastSynchronizedDate:(NSDate*)lastDate
{
    return [self.settingsDbDelegate setLastSynchronizedDate:lastDate];
}

- (NSDate*) lastSynchronizeDate
{
    return [self.settingsDbDelegate lastSynchronizedDate];
}


@end
