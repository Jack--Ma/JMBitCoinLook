/*
 * Copyright (c) 2014 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */


#import "RWTCurrencyDataViewController.h"

#import "RWTBitCoinService.h"
#import "RWTBitCoinPrice.h"
#import "RWTBitCoinStats.h"

#import "JBLineChartView.h"

@interface RWTCurrencyDataViewController () <JBLineChartViewDataSource, JBLineChartViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *priceLabel;
@property (weak, nonatomic) IBOutlet UILabel *priceChangeLabel;

@property (strong, nonatomic) IBOutlet JBLineChartView *priceLineChartView;

@property (strong, nonatomic) RWTBitCoinService *bitCoinService;

@property (strong, nonatomic) NSNumberFormatter *dollarNumberFormatter;
@property (strong, nonatomic) NSNumberFormatter *prefixedDollarNumberFormatter;

@end

@implementation RWTCurrencyDataViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.dollarNumberFormatter = [[NSNumberFormatter alloc] init];
    [self.dollarNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [self.dollarNumberFormatter setPositiveFormat:@""];
    
    self.prefixedDollarNumberFormatter = [[NSNumberFormatter alloc] init];
    [self.prefixedDollarNumberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
    [self.prefixedDollarNumberFormatter setPositivePrefix:@"+"];
    [self.prefixedDollarNumberFormatter setNegativeFormat:@"-"];
    
    self.priceLineChartView.delegate = self;
    self.priceLineChartView.dataSource = self;
        
    self.bitCoinService = [[RWTBitCoinService alloc] init];

}

- (void)updateWithCurrencyData {
    [self.bitCoinService getStats:^(RWTBitCoinStats *stats, NSError *error) {
        [self.bitCoinService getMarketPriceInUSDForPast30Days:^(NSArray *prices, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.prices = prices;
                self.stats = stats;
                
                self.priceLabel.text = [self.dollarNumberFormatter stringFromNumber:self.stats.marketPriceUSD];
                
                [self updatePriceHistoryGraph];
                [self updatePriceChangeLabel];
            });
        }];
    }];
}

- (void)updatePriceHistoryGraph
{
    NSNumber *maxPrice = [self.prices valueForKeyPath:@"@max.value"];
    self.priceLineChartView.maximumValue = [maxPrice floatValue] * 1.02;
    [self.priceLineChartView reloadData];
}

- (void)updatePriceChangeLabel
{
    NSNumber *yesterdaysPrice = [self.bitCoinService yesterdaysPriceUsingPriceHistory:self.prices];
    NSNumber *priceDifference = [NSNumber numberWithFloat:(self.stats.marketPriceUSD.floatValue - yesterdaysPrice.floatValue)];
    
    if (priceDifference.floatValue > 0) {
        self.priceChangeLabel.textColor = [UIColor greenColor];
    } else {
        self.priceChangeLabel.textColor = [UIColor redColor];
    }
    
    self.priceChangeLabel.text = [self.prefixedDollarNumberFormatter stringFromNumber:priceDifference];
}

#pragma mark - JBLineChartViewDataSource & JBLineChartViewDelegate

- (NSUInteger)numberOfLinesInLineChartView:(JBLineChartView *)lineChartView {
    return 1;
}

- (NSUInteger)lineChartView:(JBLineChartView *)lineChartView numberOfVerticalValuesAtLineIndex:(NSUInteger)lineIndex {
    return self.prices.count;
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView verticalValueForHorizontalIndex:(NSUInteger)horizontalIndex atLineIndex:(NSUInteger)lineIndex {
    RWTBitCoinPrice *price = self.prices[horizontalIndex];
    return [price.value floatValue];
}

- (CGFloat)lineChartView:(JBLineChartView *)lineChartView widthForLineAtLineIndex:(NSUInteger)lineIndex {
    return 2.0;
}

- (UIColor *)lineChartView:(JBLineChartView *)lineChartView colorForLineAtLineIndex:(NSUInteger)lineIndex {
    return [UIColor whiteColor];
}

- (CGFloat)verticalSelectionWidthForLineChartView:(JBLineChartView *)lineChartView {
    return 1.0;
}

@end
