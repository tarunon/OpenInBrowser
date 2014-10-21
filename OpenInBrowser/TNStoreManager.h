//
//  UbiquityStoreManager.h
//  Libing
//
//  Created by tarunon on 2014/06/29.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

typedef enum : NSUInteger {
    TNStoreManagerPriorityStoreLocal,
    TNStoreManagerPriorityStoreUbiquity
} TNStoreManagerPriorityStore;

@protocol TNStoreManagerDelegate;

typedef void (^TNStoreManagerDefinePriorityBlock)(TNStoreManagerPriorityStore priorityStore);

@interface TNStoreManager : NSObject {
    NSPersistentStoreCoordinator *_coordinator;
    NSManagedObjectModel *_model;
    NSManagedObjectContext *_context;
    NSDictionary *_localStoreOptions;
    NSDictionary *_ubiquityStoreOptions;
    NSMutableDictionary *_migratedObjectIDs;
    NSURL *_localStoreURL;
    NSURL *_ubiquityStoreURL;
    dispatch_queue_t _coordinatorQueue;
    NSInteger _mergeCount;
}

@property (nonatomic, weak) id<TNStoreManagerDelegate> delegate;
@property (nonatomic) BOOL useUbiquityStore;

- (instancetype)initWithDelegate:(id<TNStoreManagerDelegate>)delegate objectModel:(NSManagedObjectModel *)model localStoreURL:(NSURL *)localStoreURL ubiquityStoreURL:(NSURL *)ubiquityStoreURL contentName:(NSString *)contentName;
- (void)save;

@end

@protocol TNStoreManagerDelegate <NSObject>

@required
- (void)manager:(TNStoreManager *)manager createdObjectContext:(NSManagedObjectContext *)context;

@optional
- (void)manager:(TNStoreManager *)manager definePriorityStore:(TNStoreManagerDefinePriorityBlock)definePriorityStore;
- (void)manager:(TNStoreManager *)manager didFailLoadWithError:(NSError *)error;
- (void)manager:(TNStoreManager *)manager didFailSaveWithError:(NSError *)error;

@end