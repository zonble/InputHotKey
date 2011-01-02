#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

@interface InputHotKeyAppDelegate : NSObject <NSApplicationDelegate> 
{
    NSWindow *window;
	NSTableView *inputTableView;
	NSMutableArray *inputArray;
}

+ (NSString *)stringForKeycode:(unsigned int)keycode;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *inputTableView;


@end
