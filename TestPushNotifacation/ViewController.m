//
//  ViewController.m
//  TestPushNotifacation
//
//  Created by wangmiao on 2017/12/4.
//  Copyright © 2017年 wangmiao. All rights reserved.
//

#import "ViewController.h"
#import <TestPushExtensionKit/TestPushExtensionKit.h>
#import "IBDataBase.h"
#import "IBNewsModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}
- (IBAction)action:(id)sender {
    NSArray * main = [[IBDataBase sharedDataBase] getAllPerson];
    NSLog(@"%@", main);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
