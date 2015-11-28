//
//  TodayViewController.m
//  JMBit Widget
//
//  Created by JackMa on 15/11/28.
//  Copyright © 2015年 JackMa. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

@interface TodayViewController () <NCWidgetProviding>

@property (nonatomic, weak) IBOutlet UIButton *toggleGrapButton;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *lineChartHeightContraint;

@property (assign, nonatomic) BOOL graphVisible;

@end

@implementation TodayViewController

- (IBAction)toggleGraph:(id)sender {

  if (self.graphVisible) {
    self.lineChartHeightContraint.constant = 0;
    self.toggleGrapButton.transform = CGAffineTransformIdentity;
    [self setPreferredContentSize:CGSizeMake(0, 40)];
    self.graphVisible = NO;
  } else {
    self.lineChartHeightContraint.constant = 98;
    self.toggleGrapButton.transform = CGAffineTransformMakeRotation(M_PI);
    [self setPreferredContentSize:CGSizeMake(0, 150)];
    self.graphVisible = YES;
  }
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  [self updateWithCurrencyData];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setPreferredContentSize:CGSizeMake(0, 40)];
  self.lineChartHeightContraint.constant = 0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - widget
//使左侧默认留白区域被填充
- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
  return UIEdgeInsetsZero;
}
- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    
    // If an error is encountered, use NCUpdateResultFailed
    // If there's no update required, use NCUpdateResultNoData
    // If there's an update, use NCUpdateResultNewData
  [self updateWithCurrencyData];
    completionHandler(NCUpdateResultNewData);
}

#pragma mark - JBLineChartViewDataSource & JBLineChartViewDelegate

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex {
  return [UIColor colorWithRed:0.17 green:0.49 blue:0.82 alpha:1.0];
}
@end
