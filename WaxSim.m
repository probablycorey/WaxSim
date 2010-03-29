#import <AppKit/AppKit.h>
#import "iPhoneSimulatorRemoteClient.h"
#import "Simulator.h"
#import "termios.h"

static BOOL gReset = false;

void printUsage();
void simulate(NSString *sdk, NSString *appPath, NSMutableArray *additionalArgs);
void resetSignal(int sig);

int main(int argc, char *argv[]) {
    signal(SIGQUIT, resetSignal);
    
    int c;
    char *sdk = nil;
    char *appPath = nil;
    char *buildPath = nil;
	NSMutableArray *additionalArgs = [NSMutableArray array];
    
    while ((c = getopt(argc, argv, "s:ah")) != -1) {
        switch(c) {
            case 's':
                sdk = optarg;
                break;
            case 'a':
                fprintf(stdout, "Available SDK Versions.\n", optopt);
                for (NSString *sdkVersion in [Simulator availableSDKs]) {
                    fprintf(stderr, "  %s\n", [sdkVersion UTF8String]);
                }
                return 1; 
            case 'h':
                printUsage();
                return 1;                 
            case '?':
                if (optopt == 's') {
                    fprintf(stderr, "Option -%c requires an argument.\n", optopt);
                    printUsage();
                }
                else {
                    fprintf(stderr, "Unknown option `-%c'.\n", optopt);
                    printUsage();
                }
                return 1;
                break;
            default:
                abort ();
        }
        
    }
    
    if (argc > optind) {
        appPath = argv[optind++];

        if (argc > optind) {
            buildPath = argv[optind++];
        }
		
		// Additional args are sent to app
		for (int i = optind; i < argc; i++) {
			[additionalArgs addObject:[NSString stringWithUTF8String:argv[i]]];
		}
    }
    else {
        fprintf(stderr, "No app-path was specified!\n");
        printUsage();
        return 1;
    }
    
    
    NSString *sdkString = sdk ? [NSString stringWithUTF8String:sdk] : nil;
    NSString *appPathString = [NSString stringWithUTF8String:appPath];
    NSString *buildPathString = buildPath ? [NSString stringWithUTF8String:buildPath] : nil;

    while (true) {
        gReset = false;

        // Move scripts over!
        if (buildPathString) {
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *appDataPath = [appPathString stringByAppendingPathComponent:@"data"];
            NSString *buildDataPath = [buildPathString stringByAppendingPathComponent:@"data"];
            NSError *error = nil;
            [fm removeItemAtPath:appDataPath error:&error];
            [fm copyItemAtPath:buildDataPath toPath:appDataPath error:&error];            
            [fm copyItemAtPath:[buildPathString stringByAppendingPathComponent:@"wax/lib/wax-scripts"]
                        toPath:[appDataPath stringByAppendingPathComponent:@"scripts/wax"]
                         error:&error];
            
        }
        
        simulate(sdkString, appPathString, additionalArgs);
        printf("\n\nREBOOT\n", appPath);
    }
            
    return 0;
}

void simulate(NSString *sdk, NSString *appPath, NSMutableArray *additionalArgs) {
    Simulator *simulator = [[Simulator alloc] initWithAppPath:appPath sdk:sdk args:additionalArgs];
    [simulator launch];
    
    while (!gReset && [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:-1]]) ;
    
    [simulator end];
}

void printUsage() {
    fprintf(stderr, "usage: waxsim [options] app-path\n");
    fprintf(stderr, "example: waxsim -s 2.2 /path/to/app.app\n");
    fprintf(stderr, "Available options are:\n");    
    fprintf(stderr, "\t-s sdk\tVersion number of sdk to use (-s 3.1)\n");        
    fprintf(stderr, "\t-a \tAvailable SDK's\n");
    fprintf(stderr, "\t-h \tPrints out this wonderful documentation!\n");    
}

void resetSignal(int sig) {
    gReset = true;
    signal(sig, resetSignal);
}
