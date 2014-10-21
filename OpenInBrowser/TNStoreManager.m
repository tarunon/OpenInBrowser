//
//  UbiquityStoreManager.m
//  Libing
//
//  Created by tarunon on 2014/06/29.
//  Copyright (c) 2014年 tarunon. All rights reserved.
//

#import "TNStoreManager.h"

@implementation TNStoreManager

+ (void)initialize
{
    if (self != [TNStoreManager class]) {
        return;
    }
}

- (instancetype)initWithDelegate:(id<TNStoreManagerDelegate>)delegate objectModel:(NSManagedObjectModel *)model localStoreURL:(NSURL *)localStoreURL ubiquityStoreURL:(NSURL *)ubiquityStoreURL contentName:(NSString *)contentName
{
    if (self = [super init]) {
        _delegate = delegate;
        _localStoreURL = localStoreURL;
        _localStoreOptions = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES, NSPersistentStoreRemoveUbiquitousMetadataOption: @YES};
        _ubiquityStoreURL = ubiquityStoreURL;
        _model = model;
        _coordinatorQueue = dispatch_queue_create("TNStoreManagerQueue", DISPATCH_QUEUE_PRIORITY_DEFAULT);
        dispatch_async(_coordinatorQueue, ^{
            _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
            _useUbiquityStore = _ubiquityStoreURL && [[NSFileManager defaultManager] fileExistsAtPath:_ubiquityStoreURL.path] && ![[NSFileManager defaultManager] fileExistsAtPath:_localStoreURL.path];
            if (_ubiquityStoreURL) {
                _ubiquityStoreOptions = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES, NSPersistentStoreUbiquitousContentNameKey: contentName, NSPersistentStoreUbiquitousContentURLKey: _ubiquityStoreURL};
            }
            if (_useUbiquityStore) {
                [self loadUbiquityStore];
            } else {
                [self loadLocalStore];
            }
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChangesFromUbiquity:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:nil];
            [_delegate manager:self createdObjectContext:[self contextFromCoordinator:_coordinator]];
        });
    }
    return self;
}

- (NSManagedObjectContext *)contextFromCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.persistentStoreCoordinator = coordinator;
    privateContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _context.parentContext = privateContext;
    _context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    return _context;
}

- (NSURL *)ubiquityLocalCacheURL
{
    return [[_localStoreURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"CoreDataUbiquitySupport" isDirectory:YES];
}

- (NSString *)ubiquityStoreID
{
    NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self ubiquityLocalCacheURL].path error:nil];
    return paths.firstObject;
}

- (NSURL *)ubiquityUniqueStoreURL
{
    NSString *storeID = [self ubiquityStoreID];
    return storeID ? [_ubiquityStoreURL URLByAppendingPathComponent:storeID isDirectory:YES] : nil;
}

- (NSURL *)baseLineURL
{
    return [_ubiquityStoreURL URLByAppendingPathComponent:@".baseline" isDirectory:YES];
}

- (void)loadLocalStore
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:_localStoreURL.path]) {
        [self copyUbiquityStoreToLocalStore];
    }
    if (_coordinator.persistentStores.count) {
        [_coordinator removePersistentStore:_coordinator.persistentStores.firstObject error:nil];
    }
    NSError *error;
    [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_localStoreURL options:_localStoreOptions error:&error];
    [self failLoadWithError:error];
}

- (void)loadUbiquityStore
{
    if (_coordinator.persistentStores.count) {
        [_coordinator removePersistentStore:_coordinator.persistentStores.firstObject error:nil];
    }
    NSError *error;
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self ubiquityLocalCacheURL].path]) {
        [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_localStoreURL options:_ubiquityStoreOptions error:&error];
    } else {
        [[NSFileManager defaultManager] evictUbiquitousItemAtURL:_ubiquityStoreURL error:nil];
        NSMutableDictionary *downloadStoreOptions = _ubiquityStoreOptions.mutableCopy;
        downloadStoreOptions[NSPersistentStoreRebuildFromUbiquitousContentOption] = @YES;
        [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_localStoreURL options:downloadStoreOptions error:&error];
    }
    [self failLoadWithError:error];
}

- (void)copyUbiquityStoreToLocalStore
{
    NSArray *subpaths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_localStoreURL.URLByDeletingLastPathComponent.path error:nil];
    for (NSString *path in [subpaths filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH %@", _localStoreURL.lastPathComponent]]) {
        [[NSFileManager defaultManager] removeItemAtURL:[_localStoreURL.URLByDeletingLastPathComponent URLByAppendingPathComponent:path] error:nil];
    }
    NSPersistentStoreCoordinator *movedCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
    NSError *error;
    [movedCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_localStoreURL options:_localStoreOptions error:&error];
    [self failLoadWithError:error];
    NSManagedObjectContext *movedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    movedContext.persistentStoreCoordinator = movedCoordinator;
    [self moveContext:_context toContext:movedContext];
    [movedContext save:nil];
    _coordinator = movedCoordinator;
}

- (void)moveLocalStoreToUbiquityStore
{
    [[NSFileManager defaultManager] removeItemAtURL:[self ubiquityLocalCacheURL] error:nil];
    [[NSFileManager defaultManager] removeItemAtURL:_ubiquityStoreURL error:nil];
    NSPersistentStoreCoordinator *movedCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:_model];
    NSError *error;
    [movedCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:_localStoreURL options:_ubiquityStoreOptions error:&error];
    [self failLoadWithError:error];
    NSManagedObjectContext *movedContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    movedContext.persistentStoreCoordinator = movedCoordinator;
    [self moveContext:_context toContext:movedContext];
    [movedContext save:nil];
    _coordinator = movedCoordinator;
}

- (void)moveContext:(NSManagedObjectContext *)fromContext toContext:(NSManagedObjectContext *)toContext
{
    _migratedObjectIDs = @{}.mutableCopy;
    for (NSEntityDescription *entity in _model.entities) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entity.name];
        for (NSManagedObject *fromObject in [fromContext executeFetchRequest:fetchRequest error:nil]) {
            [self moveObject:fromObject toContext:toContext];
        }
    }
    _migratedObjectIDs = nil;
}

- (NSManagedObject *)moveObject:(NSManagedObject *)fromObject toContext:(NSManagedObjectContext *)toContext
{
    if (!fromObject) {
        return nil;
    }
    NSManagedObjectID *migratedObjectID = _migratedObjectIDs[fromObject.objectID];
    if (migratedObjectID) {
        return [toContext objectWithID:migratedObjectID];
    }
    @autoreleasepool {
        NSManagedObject *toObject = [NSEntityDescription insertNewObjectForEntityForName:fromObject.entity.name inManagedObjectContext:toContext];
        _migratedObjectIDs[fromObject.objectID] = toObject.objectID;
        [toObject setValuesForKeysWithDictionary:[fromObject dictionaryWithValuesForKeys:fromObject.entity.attributesByName.allKeys]];
        for (NSRelationshipDescription *relationship in fromObject.entity.relationshipsByName.allValues) {
            if (relationship.isToMany) {
                NSMutableSet *set = [[toObject primitiveValueForKey:relationship.name] mutableCopy];
                for (NSManagedObject *object in [fromObject primitiveValueForKey:relationship.name]) {
                    [set addObject:[self moveObject:object toContext:toContext]];
                }
                [toObject setPrimitiveValue:set forKey:relationship.name];
            } else {
                [toObject setPrimitiveValue:[self moveObject:[fromObject primitiveValueForKey:relationship.name] toContext:toContext] forKey:relationship.name];
            }
        }
        return toObject;
    }
}

- (void)save
{
    if (_mergeCount) {
        NSLog(@"Now Merging with iCloud");
        return;
    }
    [_context performBlockAndWait:^{
        NSError *error;
        [_context save:&error];
        [self failSaveWithError:error];
        [_context.parentContext performBlock:^{
            NSError *error;
            [_context.parentContext save:&error];
            [self failSaveWithError:error];
        }];
    }];
}

- (void)failLoadWithError:(NSError *)error
{
    if (error && [_delegate respondsToSelector:@selector(manager:didFailLoadWithError:)]) {
        [_delegate manager:self didFailLoadWithError:error];
    }
}

- (void)failSaveWithError:(NSError *)error
{
    if (error && [_delegate respondsToSelector:@selector(manager:didFailSaveWithError:)]) {
        [_delegate manager:self didFailSaveWithError:error];
    }
}

- (void)mergeChangesFromUbiquity:(NSNotification *)note
{
    NSLog(@"Merge ubiquity store");
    dispatch_async(_coordinatorQueue, ^{
        _mergeCount++;
    });
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSThread sleepForTimeInterval:0.5];
        dispatch_async(_coordinatorQueue, ^{
            _mergeCount--;
            if (!_mergeCount) {
                [_delegate manager:self createdObjectContext:[self contextFromCoordinator:_coordinator]];
            }
        });
    });
}

- (void)setuseUbiquityStore:(BOOL)useUbiquityStore
{
    if (_useUbiquityStore ^ useUbiquityStore) {
        _useUbiquityStore = useUbiquityStore;
        void (^moveBlock)(TNStoreManagerPriorityStore);
        if (_useUbiquityStore) {
            if (!_ubiquityStoreURL) {
#ifndef EXTENSION
                [[[UIAlertView alloc] initWithTitle:@"Disable iCloud" message:@"Please open Settings App, and enable iCloud options." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
#endif
                _useUbiquityStore = NO;
                return;
            }
            moveBlock = ^(TNStoreManagerPriorityStore priorityStore) {
                if (priorityStore == TNStoreManagerPriorityStoreLocal) {
                    [self moveLocalStoreToUbiquityStore];
                } else {
                    dispatch_sync(_coordinatorQueue, ^{
                        [[NSFileManager defaultManager] removeItemAtURL:[self ubiquityLocalCacheURL] error:nil];
                        [self loadUbiquityStore];
                    });
                }
                [[NSFileManager defaultManager] removeItemAtURL:_localStoreURL error:nil];
                _useUbiquityStore = YES;
                [_delegate manager:self createdObjectContext:[self contextFromCoordinator:_coordinator]];
            };
        } else {
            moveBlock = ^(TNStoreManagerPriorityStore priorityStore) {
                if (priorityStore == TNStoreManagerPriorityStoreUbiquity) {
                    [self copyUbiquityStoreToLocalStore];
                } else {
                    dispatch_sync(_coordinatorQueue, ^{
                        [self loadLocalStore];
                    });
                }
                _useUbiquityStore = NO;
                [_delegate manager:self createdObjectContext:[self contextFromCoordinator:_coordinator]];
            };
        }
        if (_useUbiquityStore ? [[NSFileManager defaultManager] fileExistsAtPath:_ubiquityStoreURL.path] : [[NSFileManager defaultManager] fileExistsAtPath:_localStoreURL.path]) {
            if ([_delegate respondsToSelector:@selector(manager:definePriorityStore:)]) {
                [_delegate manager:self definePriorityStore:moveBlock];
                return;
            }
        }
        moveBlock(TNStoreManagerPriorityStoreUbiquity);
    }
}

@end
