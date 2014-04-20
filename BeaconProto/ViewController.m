//
//  ViewController.m
//  BeaconProto
//
//  Created by 片山 和 on 2014/04/17.
//  Copyright (c) 2014年 gtlab. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController (){
    
    CLLocationManager   *locationManager;
    CLBeaconRegion      *beaconRegion;
    NSUUID              *proximityUUID;
    CBPeripheralManager *peripheralManager;
    
    BOOL beaconFlg;
    NSString *lastMajorId;
    
    NSDictionary *msgDic;
    NSDictionary *seDic;
    AVAudioPlayer* avap;
    
}

@end

@implementation ViewController

- (void)viewDidLoad{
    
    [super viewDidLoad];
    [self startLocationManager];
    
    _beerImage.hidden = YES;
}


////////////////////////////////////////////////////////////////////////

#pragma mark -
#pragma mark ビーコン関連

//ビーコン受信開始
- (void)startLocationManager{
    
    beaconFlg   = NO;
    lastMajorId = @"";
    
    msgDic = @{@"major_7":@"Enter Beacon 7",@"major_49":@"Enter Beacon 49",@"major_343":@"Enter Beacon 343",@"major_2401":@"Enter Beacon 2401"};
    
    
    proximityUUID = [[NSUUID alloc] initWithUUIDString:@"552FD535-F9D6-4B23-B862-CB4BACEA02DE"];
    
    
    //ビーコン受信設定
    if ([CLLocationManager isMonitoringAvailableForClass:[CLBeaconRegion class]]) {
        
        //デリゲートを設定
        locationManager          = [CLLocationManager new];
        locationManager.delegate = self;
        
        //CLBeaconRegionを作成
        beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:@"jp.gtlab.BeaconProto"];
        beaconRegion.notifyEntryStateOnDisplay = YES;
        
        //モニタリング開始
        [locationManager startMonitoringForRegion:beaconRegion];
        
    } else {
        NSLog(@"お使いの端末ではiBeaconを利用できません。");
    }
    
}


//モニタリング開始
- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region{
    
    NSLog(@"didStartMonitoringForRegion:");
    [locationManager requestStateForRegion:beaconRegion];
    
}


//ステータスの監視
- (void)locationManager:(CLLocationManager *)manager didDetermineState:(CLRegionState)state forRegion:(CLRegion *)region{
    
    NSLog(@"didDetermineState:");
    
    switch (state) {
        case CLRegionStateInside:
            NSLog(@"CLRegionStateInside");
            if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
                [locationManager startRangingBeaconsInRegion:beaconRegion];
            }
            break;
        case CLRegionStateOutside:
        case CLRegionStateUnknown:
        default:
            NSLog(@"BREAK!!");
            break;
    }
    
}


//境界に入った瞬間の処理
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region{
    
    beaconFlg   = YES;
    lastMajorId = @"";
    
    //なにか通知するのであれば
    //[self sendLocalNotificationRequest:@{@"mode":@"enter",@"range":@"0",@"major":@"0",@"minor":@"0"}];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
}


//境界から出た瞬間の処理
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region{
    
    beaconFlg   = NO;
    lastMajorId = @"";
    
    //なにか通知するのであれば
    //[self sendLocalNotificationRequest:@{@"mode":@"exit",@"range":@"0",@"major":@"0",@"minor":@"0"}];
    
    if ([region isMemberOfClass:[CLBeaconRegion class]] && [CLLocationManager isRangingAvailable]) {
        [locationManager startRangingBeaconsInRegion:(CLBeaconRegion *)region];
    }
    
}


//受信している各ビーコンとの距離を測定する
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region{
    
    if ([beacons count] < 1) {
        return;
    }
    
    //一番近いビーコン情報を取得する
    //同時に受信しているビーコンは配列beaconsに入っている
    CLBeacon *firstBeacon = beacons.firstObject;
    NSString *major       = [NSString stringWithFormat:@"%@",firstBeacon.major];
    NSString *minor       = [NSString stringWithFormat:@"%@",firstBeacon.minor];
    
    //1だと近い、3だと遠い
    int range = firstBeacon.proximity;
    
    //同じMajorなら通知しない
    if ([lastMajorId intValue] == [major intValue]) {
        return;
    }
    
    lastMajorId = major;
    
    
    //ローカル通知
    [self sendLocalNotificationRequest:@{@"mode":@"range",@"range":[NSString stringWithFormat:@"%d",range],@"major":major,@"minor":minor}];
    
}


//ローカル通知処理
- (void)sendLocalNotificationRequest:(NSDictionary *)items{
    
    NSString *mode  = [items objectForKey:@"mode"];
    
    int range = [[items objectForKey:@"range"] intValue];
    int major = [[items objectForKey:@"major"] intValue];
    int minor = [[items objectForKey:@"minor"] intValue];
    
    
    UILocalNotification *localNotification = [UILocalNotification new];
    
    localNotification.fireDate = [NSDate date];
    localNotification.soundName = UILocalNotificationDefaultSoundName;
    
    
    //境界に入った時の処理
    if ([mode isEqualToString:@"enter"]) {
        
        localNotification.alertBody = @"Mode : Enter";
        
    //境界から出た時の処理
    }else if ([mode isEqualToString:@"exit"]) {
        
        localNotification.alertBody = @"Mode : Exit";
        
    //距離測定時
    }else if ([mode isEqualToString:@"range"]) {
        
        localNotification.alertBody = [msgDic objectForKey:[NSString stringWithFormat:@"major_%d", major]];
        localNotification.soundName = [NSString stringWithFormat:@"se_%d.wav", major];
        
    }
    
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    
    
    NSLog(@"Mode : %@ / Major : %d / Range : %d", mode, major, range);
    //画面にも出力
    bool voice = false;
    switch( major ) {
        case 7:
            [_textView setText:@"This is the azalea.Because Takao Unlike the artificial forest of peripheral, natural forest remains widely, many trees are lush and dense but very 599 meters above sea level.Under these wonderful environment, through the four seasons, and wild birds, insects, animals will inhabit many."];
            voice = true;
            break;
        case 49:
            [_textView setText:@"You will arrive to Yakuoin and walk about 10 minutes to go the way of the left."];
            voice = true;
            break;
        case 343:
            [_textView setText:@"Was cheers for good work. There are benefits and Deals shop recommended. Why do not you go after this?"];
            break;
        case 2401:
            [_textView setText:@"Get Beer!!Please show it to the clerk."];
            voice = true;
            _beerImage.hidden = NO;
            break;

    
    }
    
    
    // 音声案内
    if( voice ) {
        NSBundle* bundle = [NSBundle mainBundle];
        NSString* path = [bundle pathForResource:[NSString stringWithFormat:@"voice_%d", major] ofType:@"m4a"];
        NSURL* url = [NSURL fileURLWithPath:path];
        avap = [ [AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        [avap play];
    }
}





- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
