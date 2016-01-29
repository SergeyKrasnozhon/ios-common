//
//  KSLocalDbManagerBase.m
//  MoneySpace
//
//  Created by Sergey on 1/21/16.
//  Copyright © 2016 MKGroup. All rights reserved.
//
#import <CoreData/CoreData.h>
#import "KSLocalDbManagerBase.h"

@interface KSLocalDbManagerBase ()
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext *mainManagedObjectContext;
@end

@implementation KSLocalDbManagerBase

#pragma mark - Overrides
-(NSURL*)modelUrl{
    NSAssert(0, @"%@:%@ should be overrided", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

-(NSURL*)storeUrl{
    NSAssert(0, @"%@:%@ should be overrided", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

#pragma mark Helper Methods
- (BOOL)saveManagedObjectContext {
    NSError *error = nil;
    
    if (![self.managedObjectContext save:&error]) {
        if (error) {
            NSLog(@"Unable to save changes.");
            NSLog(@"%@, %@", error, error.localizedDescription);
        }
        return NO;
    }
    
    __block BOOL result = NO;
    [self.mainManagedObjectContext performBlockAndWait:^{
        NSError *error = nil;
        if(![self.mainManagedObjectContext save:&error]){
            if (error) {
                NSLog(@"Unable to save changes.");
                NSLog(@"%@, %@", error, error.localizedDescription);
            }
        }else result = YES;
    }];
    return result;
}

#pragma mark - Accessors
-(NSManagedObjectContext *)managedObjectContext{
    NSThread *currentThread = [NSThread currentThread];
    NSManagedObjectContext *privateContext = [[currentThread threadDictionary] objectForKey:@"managedObjectContext"];
    if(privateContext) return privateContext;
    if([currentThread isMainThread]) return self.mainManagedObjectContext;
    
    privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [privateContext setParentContext:self.mainManagedObjectContext];
    [[currentThread threadDictionary] setObject:privateContext forKey:@"managedObjectContext"];
    return privateContext;
}

#pragma mark - Core Data Stack
- (NSManagedObjectModel *)managedObjectModel
{
    if(nil != _managedObjectModel)
        return _managedObjectModel;
    
    NSURL *modelURL = [self modelUrl];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if(nil != _persistentStoreCoordinator)
        return _persistentStoreCoordinator;
    
    NSURL *storeURL = [self storeUrl];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if(![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]){
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)mainManagedObjectContext
{
    if(nil != _mainManagedObjectContext)
        return _mainManagedObjectContext;
    void(^initializeContext)() = ^{
        NSPersistentStoreCoordinator *store = self.persistentStoreCoordinator;
        if(nil != store){
            _mainManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [_mainManagedObjectContext setPersistentStoreCoordinator:store];
        }
    };
    if(![[NSThread currentThread] isMainThread]){
        dispatch_sync(dispatch_get_main_queue(), ^{
            initializeContext();
        });
    }
    else initializeContext();
    return _mainManagedObjectContext;
}

@end





