//
//  RNBranch.m
//  RNBranch
//
//  Created by Kevin Stumpf on 1/28/16.
//

#import "RNBranch.h"
#import "RCTBridgeModule.h"
#import "RCTBridge.h"
#import "RCTEventDispatcher.h"
#import <Branch/Branch.h>
#import "BranchLinkProperties.h"
#import "BranchUniversalObject.h"

@implementation RNBranch

NSString * const initSessionWithLaunchOptionsFinishedEventName = @"initSessionWithLaunchOptionsFinished";
static NSDictionary* initSessionWithLaunchOptionsResult;

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

//Called by AppDelegate.m -- stores initSession result in static variables and raises initSessionFinished event that's captured by the RNBranch instance to emit it to React Native
+ (void)initSessionWithLaunchOptions:(NSDictionary *)launchOptions isReferrable:(BOOL)isReferrable {
  [[Branch getInstance] initSessionWithLaunchOptions:launchOptions isReferrable:isReferrable andRegisterDeepLinkHandler:^(NSDictionary *params, NSError *error) {
    initSessionWithLaunchOptionsResult = @{@"params": params ? params : [NSNull null], @"error": error ? error : [NSNull null]};
    if ([initSessionWithLaunchOptionsResult[@"error"] respondsToSelector:@selector(localizedDescription)]) {
      initSessionWithLaunchOptionsResult[@"error"] = [notificationObject[@"error"] localizedDescription];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:initSessionWithLaunchOptionsFinishedEventName object:initSessionWithLaunchOptionsResult];
  }];
}

+ (BOOL)handleDeepLink:(NSURL *)url {
  return [[Branch getInstance] handleDeepLink:url];
}

+ (BOOL)continueUserActivity:(NSUserActivity *)userActivity {
  return [[Branch getInstance] continueUserActivity:userActivity];
}

- (id)init {
  self = [super init];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onInitSessionFinished:) name:initSessionWithLaunchOptionsFinishedEventName object:nil];

  return self;
}

- (void) dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) onInitSessionFinished:(NSNotification*) notification {
  id notificationObject = notification.object;

  // If there is an error, try to parse a useful message and fire error event
  if (notificationObject[@"error"] != [NSNull null]) {
    if ([notificationObject[@"error"] respondsToSelector:@selector(localizedDescription)]) {
      notificationObject[@"error"] = [notificationObject[@"error"] localizedDescription];
    }
    [self.bridge.eventDispatcher sendAppEventWithName:@"RNBranch.initSessionError" body:notificationObject];
  }
  // otherwise notify the session is finished
  else {
    [self.bridge.eventDispatcher sendAppEventWithName:@"RNBranch.initSessionSuccess" body:notificationObject];
  }
}

- (BranchUniversalObject) createBranchUniversalObject:(NSDictionary *)branchUniversalObjectMap
{
  BranchUniversalObject *branchUniversalObject = [[BranchUniversalObject alloc] initWithCanonicalIdentifier:[branchUniversalObjectMap objectForKey:@"canonicalIdentifier"]];
  branchUniversalObject.title = [branchUniversalObjectMap objectForKey:@"contentTitle"];
  branchUniversalObject.contentDescription = [branchUniversalObjectMap objectForKey:@"contentDescription"];
  branchUniversalObject.imageUrl = [branchUniversalObjectMap objectForKey:@"contentImageUrl"];

  NSDictionary* metaData = [branchUniversalObjectMap objectForKey:@"metadata"];
  if(metaData) {
    NSEnumerator *enumerator = [metaData keyEnumerator];
    id metaDataKey;
    while((metaDataKey = [enumerator nextObject])) {
      [branchUniversalObject addMetadataKey:metaDataKey value:[metaData objectForKey:metaDataKey]];
    }
  }

  return branchUniversalObject
}


RCT_EXPORT_METHOD(getInitSessionResult:(RCTPromiseResolveBlock)resolve
                  rejecter:(__unused RCTPromiseRejectBlock)reject)
{
  resolve(initSessionWithLaunchOptionsResult ? initSessionWithLaunchOptionsResult : [NSNull null]);
}

RCT_EXPORT_METHOD(setDebug) {
  Branch *branch = [Branch getInstance];
  [branch setDebug];
}

RCT_EXPORT_METHOD(getLatestReferringParams:(RCTPromiseResolveBlock)resolve
                  rejecter:(__unused RCTPromiseRejectBlock)reject)
{
  Branch *branch = [Branch getInstance];
  resolve([branch getLatestReferringParams]);
}

RCT_EXPORT_METHOD(getFirstReferringParams:(RCTPromiseResolveBlock)resolve
                  rejecter:(__unused RCTPromiseRejectBlock)reject)
{
  Branch *branch = [Branch getInstance];
  resolve([branch getFirstReferringParams]);
}

RCT_EXPORT_METHOD(setIdentity:(NSString *)identity)
{
  Branch *branch = [Branch getInstance];
  [branch setIdentity:identity];
}

RCT_EXPORT_METHOD(logout)
{
  Branch *branch = [Branch getInstance];
  [branch logout];
}

RCT_EXPORT_METHOD(userCompletedAction:(NSString *)event withState:(NSDictionary *)appState)
{
  Branch *branch = [Branch getInstance];
  [branch userCompletedAction:event withState:appState];
}

RCT_EXPORT_METHOD(showShareSheet:(NSDictionary *)branchUniversalObjectMap
                  withShareOptions:(NSDictionary *)shareOptionsMap
                  withLinkProperties:(NSDictionary *)linkPropertiesMap
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(__unused RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^(void){
    BranchUniversalObject branchUniversalObject = [self createBranchUniversalObject:branchUniversalObjectMap];

    BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
    linkProperties.channel = [linkPropertiesMap objectForKey:@"channel"];
    linkProperties.feature = [linkPropertiesMap objectForKey:@"feature"];

    [branchUniversalObject showShareSheetWithLinkProperties:linkProperties
                                             andShareText:[shareOptionsMap objectForKey:@"messageBody"]
                                             fromViewController:nil
                                              completion:^(NSString *activityType, BOOL completed){
      NSDictionary *result = @{
        @"channel" : activityType ? activityType : [NSNull null],
        @"completed" : [NSNumber numberWithBool:completed],
        @"error" : [NSNull null]
      };

      resolve(@[result]);
    }];
  });
}

RCT_EXPORT_METHOD(registerView:(NSDictionary *)branchUniversalObjectMap
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  BranchUniversalObject branchUniversalObject = [self makeBranchUniversalObject:branchUniversalObjectMap];
  [branchUniversalObject registerViewWithCallback:^(NSDictionary *params, NSError *error) {
    CDVPluginResult *pluginResult = nil;
    if (!error) {
      resolve(params);
    } else {
      reject(error);
    }
  }];
}

RCT_EXPORT_METHOD(generateShortUrl:(NSDictionary *)branchUniversalObjectMap
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  BranchUniversalObject branchUniversalObject = [self makeBranchUniversalObject:branchUniversalObjectMap];

  BranchLinkProperties *linkProperties = [[BranchLinkProperties alloc] init];
  linkProperties.channel = [linkPropertiesMap objectForKey:@"channel"];
  linkProperties.feature = [linkPropertiesMap objectForKey:@"feature"];

  [branchUniversalObject getShortUrlWithLinkProperties:linkProperties andCallback:^(NSString *url, NSError *error) {
    CDVPluginResult* pluginResult = nil;
    if (!error) {
      NSError *err;
      NSDictionary *jsonObj = [[NSDictionary alloc] initWithObjectsAndKeys:url, @"url", 0, @"options", &err, @"error", nil];

      if (err) {
        NSLog(@"Parsing Error: %@", [err localizedDescription]);
        reject(err);
      } else {
        NSLog(@"RNBranch Success");
        resolve(jsonObj);
      }
    } else {
      reject(error);
    }
  }];
}

RCT_EXPORT_METHOD(listOnSpotlight:(NSDictionary *)branchUniversalObjectMap
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  BranchUniversalObject branchUniversalObject = [self makeBranchUniversalObject:branchUniversalObjectMap];
  [branchUniversalObj listOnSpotlightWithCallback:^(NSString *string, NSError *error) {
    if (!error) {
      NSError *err;
      NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@{@"result":string}
                                                         options:0
                                                           error:&err];
      if (err) {
        reject(err);
      } else {
        resolve(jsonData);
      }
    }
    else {
      reject(error);
    }
  }];
}

RCT_EXPORT_METHOD(getShortUrl:(NSDictionary *)linkPropertiesMap
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *feature = [linkPropertiesMap objectForKey:@"feature"];
  NSString *channel = [linkPropertiesMap objectForKey:@"channel"];
  NSString *stage = [linkPropertiesMap objectForKey:@"stage"];
  NSArray *tags = [linkPropertiesMap objectForKey:@"tags"];

  [[Branch getInstance] getShortURLWithParams:linkPropertiesMap
                                      andTags:tags
                                   andChannel:channel
                                   andFeature:feature
                                     andStage:stage
                                  andCallback:^(NSString *url, NSError *error) {
                                      if (error) {
                                          NSLog(@"RNBranch::Error: %@", error.localizedDescription);
                                          reject(@"RNBranch::Error", @"getShortURLWithParams", error);
                                      }
                                      resolve(url);
                                  }];
}

@end
