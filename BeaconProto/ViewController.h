//
//  ViewController.h
//  BeaconProto
//
//  Created by 片山 和 on 2014/04/17.
//  Copyright (c) 2014年 gtlab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface ViewController : UIViewController<CLLocationManagerDelegate, UITabBarControllerDelegate>


@property (strong, nonatomic) IBOutlet UITextView *textView;

@end
