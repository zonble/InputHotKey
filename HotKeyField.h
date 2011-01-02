#import <Cocoa/Cocoa.h>

@interface HotKeyField : NSView
{
	NSTextField *displayTextView;
	NSButton *setButton;
	NSButton *clearButton;
	NSString *shortcut;	
	NSDictionary *hotKey;
}

@property (retain, nonatomic) NSDictionary *hotKey;

@end
