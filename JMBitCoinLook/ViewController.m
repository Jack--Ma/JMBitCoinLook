//
//  ViewController.m
//  JMBitCoinLook
//
//  Created by JackMa on 15/11/28.
//  Copyright © 2015年 JackMa. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UILabel *priceOnDayLabel;
@property (nonatomic, weak) IBOutlet UILabel *dayLabel;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  _dateFormatter = [[NSDateFormatter alloc] init];
  [_dateFormatter setDateFormat:@"EEE M/d"];
  
  self.priceOnDayLabel.text = @"";
  self.dayLabel.text = @"";
  
  [self updateWithCurrencyData];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)updatePriceOnDayLabel:(RWTBitCoinPrice *)price {
  self.priceOnDayLabel.text = [self.dollarNumberFormatter stringFromNumber:price.value];
}
- (void)updateDayLabel:(RWTBitCoinPrice *)price {
  self.dayLabel.text = [self.dateFormatter stringFromDate:price.time];
}

#pragma mark - JBLineChartViewDataSource & JBLineChartViewDelegate
- (void)lineChartView:(JBLineChartView *)lineChartView didSelectLineAtIndex:(NSUInteger)lineIndex horizontalIndex:(NSUInteger)horizontalIndex {
  
  RWTBitCoinPrice *selectedPrice = self.prices[horizontalIndex];
  [self updatePriceOnDayLabel:selectedPrice];
  [self updateDayLabel:selectedPrice];
}

- (void)didUnselectLineInLineChartView:(JBLineChartView *)lineChartView {
  self.priceOnDayLabel.text = @"";
  self.dayLabel.text = @"";
}
@end
