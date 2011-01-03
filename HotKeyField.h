#import <Cocoa/Cocoa.h>

@class HotKeyField;

@protocol HotKeyFieldDelegate

- (BOOL)hotKeyField:(HotKeyField *)inHotKeyField hotKeyIsRegistered:(NSDictionary *)inHotKey;
- (void)hotKeyField:(HotKeyField *)inHotKeyField didSetHotKey:(NSDictionary *)inHotKey;
- (void)hotKeyFieldDidClear:(HotKeyField *)inHotKeyField;

@end


@interface HotKeyField : NSView
{
	id <HotKeyFieldDelegate> delegate;
	
	NSTextField *displayTextView;
	NSButton *clearButton;
	NSDictionary *hotKey;
}

- (void)updateStringForHotKey;

@property (assign, nonatomic) id <HotKeyFieldDelegate> delegate;
@property (retain, nonatomic) NSDictionary *hotKey;

@end
