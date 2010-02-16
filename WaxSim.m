#import <AppKit/AppKit.h>
#import "iPhoneSimulatorRemoteClient.h"
#import "Simulator.h"
#import "termios.h"

struct termios savedTermios;

void printUsage();
int hasInput();
void ttyRaw();
void ttyReset();

int main(int argc, char *argv[]) {
    int c;
    char *sdk = nil;
    char *appPath = nil;
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
        appPath = argv[optind];	
		
		// Additional args are sent to app
		for (int i = optind + 1; i < argc; i++) {
			[additionalArgs addObject:[NSString stringWithUTF8String:argv[i]]];
		}
    }
    else {
        fprintf(stderr, "No app-path was specified!\n");
        printUsage();
        return 1;
    }
    
    ttyRaw();
    atexit(ttyReset);
    
    NSString *sdkString = sdk ? [NSString stringWithUTF8String:sdk] : nil;
    NSString *appPathString = [NSString stringWithUTF8String:appPath];
    Simulator *simulator = [[Simulator alloc] initWithAppPath:appPathString sdk:sdkString args:additionalArgs];
    [simulator launch];

    while ([[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:-1]]) {        
        int r;
        unsigned char c;
        
        if (hasInput()) {
            if ((r = read(0, &c, sizeof(c))) < 0) continue; // error
            
            printf("REBOOT %c\n", c);
        }
    }
    
    return 0;
}

void printUsage() {
    fprintf(stderr, "usage: waxsim [options] app-path\n");
    fprintf(stderr, "example: waxsim -s 2.2 /path/to/app.app\n");
    fprintf(stderr, "Available options are:\n");    
    fprintf(stderr, "\t-s sdk\tVersion number of sdk to use (-s 3.1)\n");        
    fprintf(stderr, "\t-a \tAvailable SDK's\n");
    fprintf(stderr, "\t-h \tPrints out this wonderful documentation!\n");    
}

int hasInput() {
    struct timeval tv = { 0L, 0L };
    fd_set fds;
    FD_SET(STDIN_FILENO, &fds);
    return select(1, &fds, NULL, NULL, &tv);
}

void ttyRaw() {
    struct termios buf;
    tcgetattr(STDIN_FILENO, &buf);
    
    savedTermios = buf;
    
    buf.c_lflag &= ~ICANON;
    buf.c_cc[VMIN] = 0;
    buf.c_cc[VTIME] = 0;
    
    tcsetattr(STDIN_FILENO, TCSANOW, &buf);    
}

void ttyReset() {
    tcsetattr(STDIN_FILENO, TCSANOW, &savedTermios);
}