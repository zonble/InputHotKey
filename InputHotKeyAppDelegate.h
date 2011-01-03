#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "DDHotKeyCenter.h"
#import "HotKeyField.h"

@interface InputHotKeyAppDelegate : NSObject 
	<NSApplicationDelegate,
	 NSTableViewDelegate,
	 NSTableViewDataSource,
	 HotKeyFieldDelegate> 
{
    NSWindow *window;
	NSTableView *inputTableView;
	HotKeyField *hotKeyField;
	NSStatusItem *statusItem;
	
	NSMutableArray *inputArray;
	DDHotKeyCenter *center;	
}

+ (NSString *)stringForModifiers: (unsigned int)aModifierFlags;

- (void)load;
- (void)save;
- (void)resetHotKeys;

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *inputTableView;
@property (assign) IBOutlet HotKeyField *hotKeyField;

@end
