//
//  KSLocalDbManagerBase.h
//  MoneySpace
//
//  Created by Sergey on 1/21/16.
//  Copyright © 2016 MKGroup. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObjectContext;
@interface KSLocalDbManagerBase : NSObject
@property (nonatomic, weak, readonly) NSManagedObjectContext *managedObjectContext;
#pragma mark - Overrides
-(NSURL*)modelUrl;
-(NSURL*)storeUrl;
- (BOOL)saveManagedObjectContext;
@end
