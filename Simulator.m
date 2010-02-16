//
//   
//  Sim
//
//  Created by ProbablyInteractive on 7/28/09.
//  Copyright 2009 Probably Interactive. All rights reserved.
//

#import "Simulator.h"

#include <sys/param.h>
#include <objc/runtime.h>

#define WaxLog(format, args...) \
    printf("%s\n", [[NSString stringWithFormat:(format), ## args] UTF8String])

@implementation Simulator

@synthesize session=_session;

- (id)initWithAppPath:(NSString *)appPath sdk:(NSString *)sdk args:(NSArray *)args {
    self = [super init];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![appPath isAbsolutePath]) {        
        appPath = [[fileManager currentDirectoryPath] stringByAppendingPathComponent:appPath];
    }   
    
    _appPath = [appPath retain];

    if (![fileManager fileExistsAtPath:_appPath]) {
        WaxLog(@"App path '%@' does not exist!", _appPath);
        exit(EXIT_FAILURE);
    }

    if (!sdk) _sdk = [[DTiPhoneSimulatorSystemRoot defaultRoot] retain];
    else {
        _sdk = [[DTiPhoneSimulatorSystemRoot rootWithSDKVersion:sdk] retain];
    }
    
    if (!_sdk) {
        WaxLog(@"Unknown sdk '%@'", sdk);
        WaxLog(@"Available sdks are...");
        for (id root in [DTiPhoneSimulatorSystemRoot knownRoots]) {
            WaxLog(@"  %@", [root sdkVersion]);
        }
        
        exit(EXIT_FAILURE);
    }
	
	_args = [args retain];

    return self;
}

+ (NSArray *)availableSDKs {
    NSMutableArray *sdks = [NSMutableArray array];
    for (id root in [DTiPhoneSimulatorSystemRoot knownRoots]) {
        [sdks addObject:[root sdkVersion]];
    }
    
    return sdks;
}

- (int)launch {
    WaxLog(@"Launching '%@' on'%@'", _appPath, [_sdk sdkDisplayName]);
    
    DTiPhoneSimulatorApplicationSpecifier *appSpec = [DTiPhoneSimulatorApplicationSpecifier specifierWithApplicationPath:_appPath];
    if (!appSpec) {
        WaxLog(@"Could not load application specifier for '%@'", _appPath);
        return EXIT_FAILURE;
    }
    
    DTiPhoneSimulatorSystemRoot *sdkRoot = [DTiPhoneSimulatorSystemRoot defaultRoot];
    
    DTiPhoneSimulatorSessionConfig *config = [[DTiPhoneSimulatorSessionConfig alloc] init];
    [config setApplicationToSimulateOnStart:appSpec];
    [config setSimulatedSystemRoot:sdkRoot];
    [config setSimulatedApplicationShouldWaitForDebugger:NO];    
    [config setSimulatedApplicationLaunchArgs:_args];
    [config setSimulatedApplicationLaunchEnvironment:[[NSProcessInfo processInfo] environment]];
    [config setLocalizedClientName:@"WaxSim"];

    // Make the simulator output to the current STDOUT & STDERR
    char path[MAXPATHLEN];
    fcntl(STDOUT_FILENO, F_GETPATH, &path);
    [config setSimulatedApplicationStdOutPath:[NSString stringWithUTF8String:path]];
    
    fcntl(STDERR_FILENO, F_GETPATH, &path);
    [config setSimulatedApplicationStdErrPath:[NSString stringWithUTF8String:path]];
    
    _session = [[DTiPhoneSimulatorSession alloc] init];
    [_session setDelegate:self];
    [_session setSimulatedApplicationPID:[NSNumber numberWithInt:35]];
    
    NSError *error;
    if (![_session requestStartWithConfig:config timeout:30 error:&error]) {
        WaxLog(@"Could not start simulator session: %@", [error localizedDescription]);
        return EXIT_FAILURE;
    }
    
    return EXIT_SUCCESS;
}

- (void)end {
    [_session requestEndWithTimeout:0];
}

// DTiPhoneSimulatorSession Delegate
// ---------------------------------
- (void)session:(DTiPhoneSimulatorSession *)session didStart:(BOOL)started withError:(NSError *)error {
    if (!started) {
        WaxLog(@"Session failed to start. %@", [error localizedDescription]);
        exit(EXIT_FAILURE);
    }
}

- (void)session:(DTiPhoneSimulatorSession *)session didEndWithError:(NSError *)error {
    WaxLog(@"Session ended with error. %@", [error localizedDescription]);
    return exit(error ? EXIT_FAILURE : EXIT_SUCCESS);
}

@end
