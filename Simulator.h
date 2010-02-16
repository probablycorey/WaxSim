//
//  Simulator.h
//  Sim
//
//  Created by ProbablyInteractive on 7/28/09.
//  Copyright 2009 Probably Interactive. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "iPhoneSimulatorRemoteClient.h"

@class DTiPhoneSimulatorSystemRoot;

@interface Simulator : NSObject <DTiPhoneSimulatorSessionDelegate> {
    NSString *_appPath;
    DTiPhoneSimulatorSystemRoot *_sdk;  
    DTiPhoneSimulatorSession* _session;
	NSArray *_args;
}

@property (nonatomic, readonly) DTiPhoneSimulatorSession* session;

+ (NSArray *)availableSDKs;

- (id)initWithAppPath:(NSString *)appPath sdk:(NSString *)sdk args:(NSArray *)args;
- (int)launch;
- (void)end;

@end