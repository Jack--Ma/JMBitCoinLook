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


#import "RWTBitCoinService.h"
#import "RWTBitCoinStats.h"
#import "RWTBitCoinPrice.h"
#import "NSDate+Utilities.h"

NSString * const kRWTBitCoinServiceStatsCacheKey = @"kRWTBitCoinServiceStatsCacheKey";
NSString * const kRWTBitCoinServiceStatsCachedDateKey = @"kRWTBitCoinServiceStatsCachedDateKey";

NSString * const kRWTBitCoinServicePriceHistoryCacheKey = @"kRWTBitCoinServicePriceHistoryCacheKey";
NSString * const kRWTBitCoinServicePriceHistoryCachedDateKey = @"kRWTBitCoinServicePriceHistoryCachedDateKey";

@interface RWTBitCoinService ()

@property (strong, nonatomic) NSURLSession *session;

@end

@implementation RWTBitCoinService

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    return self;
}

- (void)getStats:(RWTBitCoinServiceStatsCompletion)completion {
    RWTBitCoinStats *cachedStats = [self getCachedStats];
    if (cachedStats) {
        completion(cachedStats, nil);
    }
    
    NSURL *statsUrl = [NSURL URLWithString:@"https://blockchain.info/stats?format=json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:statsUrl];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (!error) {
            NSError *jsonError = nil;
            NSDictionary *statsDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
            if (!jsonError) {
                RWTBitCoinStats *stats = [[RWTBitCoinStats alloc] initWithDictionary:statsDictionary];
                [self cacheStats:stats];
                completion(stats, nil);
            } else {
                NSLog(@"Error parsing stats JSON: %@", jsonError);
                completion(nil, jsonError);
            }
        } else {
            NSLog(@"Error loading stats: %@", error);
            completion(nil, error);
        }
    }];
    
    [task resume];
}

- (void)getMarketPriceInUSDForPast30Days:(RWTBitCoinServiceMarketPriceCompletion)completion {
    NSArray *cachedPrices = [self getCachedPriceHistory];
    if (cachedPrices) {
        completion(cachedPrices, nil);
    }
    
    NSURL *pricesUrl = [NSURL URLWithString:@"https://blockchain.info/charts/market-price?timespan=30days&format=json"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pricesUrl];
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
          if (!error) {
              NSError *jsonError = nil;
              NSDictionary *pricesDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonError];
              if (!jsonError) {
                  NSArray *priceValues = pricesDictionary[@"values"];
                  NSMutableArray *prices = [NSMutableArray array];
                  for (NSDictionary *priceDictionary in priceValues) {
                      RWTBitCoinPrice *price = [[RWTBitCoinPrice alloc] initWithDictionary:priceDictionary];
                      [prices addObject:price];
                  }
                  [self cachePriceHistory:prices];
                  completion(prices, nil);
                  
              } else {
                  NSLog(@"Error parsing stats JSON: %@", jsonError);
                  completion(nil, jsonError);
              }
          } else {
              NSLog(@"Error loading stats: %@", error);
              completion(nil, error);
          }
      }];

    [task resume];
    
}

- (NSNumber *)yesterdaysPriceUsingPriceHistory:(NSArray *)priceHistory {
    __block RWTBitCoinPrice *yesterdaysPrice = nil;
    [priceHistory enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(RWTBitCoinPrice *price, NSUInteger idx, BOOL *stop) {
        if ([price.time isYesterday]) {
            yesterdaysPrice = price;
            *stop = YES;
        }
    }];
    
    return yesterdaysPrice.value;
}

#pragma mark - Private Methods

- (id)loadCachedDataForKey:(NSString *)key cachedDateKey:(NSString *)cachedDateKey {
    NSDate *cachedDate = [[NSUserDefaults standardUserDefaults] valueForKey:cachedDateKey];
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:cachedDate];
    
    id cachedValue = nil;
    
    if (timeInterval < 60*5) { // 5mins
        NSData *cachedData = [[NSUserDefaults standardUserDefaults] valueForKey:key];
        
        if (cachedData) {
            cachedValue = [NSKeyedUnarchiver unarchiveObjectWithData:cachedData];
        }
    }
    
    return cachedValue;
}

- (RWTBitCoinStats *)getCachedStats {
    RWTBitCoinStats *stats = [self loadCachedDataForKey:kRWTBitCoinServiceStatsCacheKey
                                          cachedDateKey:kRWTBitCoinServiceStatsCachedDateKey];
    return stats;
}

- (NSArray *)getCachedPriceHistory {
    NSArray *prices = [self loadCachedDataForKey:kRWTBitCoinServicePriceHistoryCacheKey
                                   cachedDateKey:kRWTBitCoinServicePriceHistoryCachedDateKey];
    return prices;
}

- (void)cacheStats:(RWTBitCoinStats *)stats {
    NSData *statsData = [NSKeyedArchiver archivedDataWithRootObject:stats];
    
    [[NSUserDefaults standardUserDefaults] setValue:statsData forKey:kRWTBitCoinServiceStatsCacheKey];
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kRWTBitCoinServiceStatsCachedDateKey];
}

- (void)cachePriceHistory:(NSArray *)history {
    NSData *priceData = [NSKeyedArchiver archivedDataWithRootObject:history];
    
    [[NSUserDefaults standardUserDefaults] setValue:priceData forKey:kRWTBitCoinServicePriceHistoryCacheKey];
    [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:kRWTBitCoinServicePriceHistoryCachedDateKey];
}

@end
