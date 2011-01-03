#import "HotKeyField.h"
#import "InputHotKeyAppDelegate.h"

typedef int CGSConnection;

typedef enum {
    CGSGlobalHotKeyEnable = 0,
    CGSGlobalHotKeyDisable = 1,
} CGSGlobalHotKeyOperatingMode;

extern CGSConnection _CGSDefaultConnection(void);
extern CGError CGSGetGlobalHotKeyOperatingMode(CGSConnection connection, CGSGlobalHotKeyOperatingMode *mode);
extern CGError CGSSetGlobalHotKeyOperatingMode(CGSConnection connection, CGSGlobalHotKeyOperatingMode mode);

@interface HotKeyField (Private)
- (NSDictionary *)hotKeyDictForEvent:(NSEvent *)event;
- (void)absorbEvents;
@end


@implementation HotKeyField

- (void)dealloc
{
	[clearButton release];
	[displayTextView release];
	[hotKey release];
	[super dealloc];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
		NSRect textRect = NSMakeRect(0, 0, frame.size.width - 56, frame.size.height);
		displayTextView = [[NSTextField alloc] initWithFrame:textRect];
		[displayTextView setEditable:NO];
		[displayTextView setAlignment:NSCenterTextAlignment];
		[displayTextView setStringValue:@""];
		[self addSubview:displayTextView];	
		
		NSRect clearRect = NSMakeRect(frame.size.width -50, 0, 50, frame.size.height);	
		clearButton = [[NSButton alloc] initWithFrame:clearRect];
		[clearButton setTitle:NSLocalizedString(@"Clear", @"")];
		[clearButton setTarget:self];
		[clearButton setAction:@selector(clear:)];
		[clearButton setBezelStyle:NSTexturedSquareBezelStyle];
		[clearButton setButtonType:NSMomentaryLightButton];
		[self addSubview:clearButton];
    }
    return self;
}

- (void)updateStringForHotKey 
{
	unsigned int modifiers = [[self.hotKey valueForKey:@"modifiers"] unsignedIntValue];
	NSString *character = [self.hotKey valueForKey:@"character"];
	if (!character) {
		character = @"";
	}
	NSString *newString = [InputHotKeyAppDelegate stringForModifiers:modifiers];
	newString = [NSString stringWithFormat:@"%@%@", newString, character];
	[displayTextView setStringValue:[newString length]?newString:@""];	
	[displayTextView display];
}

- (IBAction)set:(id)sender
{
	[self absorbEvents];
}

- (IBAction)clear:(id)sender
{
	[displayTextView setStringValue:@""];
	[delegate hotKeyFieldDidClear:self];
	self.hotKey = nil;
}

- (void)timerFire:(NSTimer *)timer
{
	NSTimeInterval t = [[NSDate date]timeIntervalSinceReferenceDate];
	t = fmod(t,1.0);
	t = (sin(t * M_PI * 2) + 1) / 2;
	
	NSColor *newColor = [[NSColor textBackgroundColor] blendedColorWithFraction:t ofColor:[NSColor selectedTextBackgroundColor]];	
	[displayTextView setBackgroundColor:newColor];
}

- (void)mouseDown:(NSEvent *)event
{
	NSPoint location = [event locationInWindow];
	location = [self convertPoint:location fromView:nil];
	if (NSPointInRect(location, [displayTextView frame])) {
		[self absorbEvents];
	}
	else {
		[super mouseDown:event];
	}
}

@synthesize delegate;
@synthesize hotKey;

@end

@implementation HotKeyField (Private)

- (NSDictionary *)hotKeyDictForEvent:(NSEvent *)event
{
	unsigned int modifiers = [event modifierFlags];
	unsigned short keyCode = [event keyCode];
	
	NSString *character = [event charactersIgnoringModifiers];
	if (keyCode == 48) {
		character= @"\t";
	}
	else {
		character = [[character substringToIndex:1] uppercaseString];
	}
	
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  [NSNumber numberWithUnsignedInt:modifiers],@"modifiers",
						  [NSNumber numberWithUnsignedShort:keyCode],@"keyCode",
						  character, @"character",
						  nil];
	return dict;
}

- (void)absorbEvents
{
	[[self window] makeFirstResponder:self];

	NSTimer *timer = [[NSTimer alloc]initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:0.1] interval:0.1 target:self selector:@selector(timerFire:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	
	[displayTextView setBackgroundColor:[NSColor selectedTextBackgroundColor]];
	[displayTextView setStringValue:@"Set Keys"];
	[[self window] display];
	NSEvent *theEvent = nil;
	
	CGSConnection conn = _CGSDefaultConnection();
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyDisable);
	BOOL collectEvents = YES;
	while (collectEvents) {
		theEvent = [NSApp nextEventMatchingMask:NSKeyDownMask|NSFlagsChangedMask|NSLeftMouseDownMask|NSAppKitDefinedMask|NSSystemDefinedMask untilDate:[NSDate dateWithTimeIntervalSinceNow:10.0] inMode:NSDefaultRunLoopMode dequeue:YES];
		switch ([theEvent type]) {
			case NSKeyDown:
			{
				unsigned short keyCode = [theEvent keyCode];
				NSString *characters = [theEvent charactersIgnoringModifiers];
				if (keyCode == 48) 
					characters = @"\t";
				if (keyCode == 36) {
					// Enter
					// Do nothing.
				}
				else if (keyCode == 122 || keyCode == 120 || keyCode == 99 || keyCode == 118 || keyCode == 96 || keyCode == 97 || keyCode == 98 || keyCode == 100 || keyCode == 101 || keyCode == 109 || keyCode == 103 || keyCode == 111) {
					// F1 - F12
					// Do nothing.
				}						
				else if (keyCode == 53) { 
					// Escape
					// Leave
					collectEvents = NO; 
				}					
				else if ([theEvent modifierFlags] & (NSCommandKeyMask|NSFunctionKeyMask|NSControlKeyMask|NSAlternateKeyMask)) {					
					NSDictionary *hotkey = [self hotKeyDictForEvent:theEvent];					
					if ([delegate hotKeyField:self hotKeyIsRegistered:hotkey]) {
						collectEvents = YES;
						break;
					}
					
					[self setHotKey:hotkey];
					[delegate hotKeyField:self didSetHotKey:hotkey];
					collectEvents = NO;
				}
				else {
					NSBeep();
				}
			}					
				break;
			case NSFlagsChanged:
			{
				NSString *newString = [InputHotKeyAppDelegate stringForModifiers:[theEvent modifierFlags]];
				[displayTextView setStringValue:[newString length]?newString:@""];	
				[displayTextView display];
				break;
			}
			case NSSystemDefinedMask:
			case NSAppKitDefinedMask:
			case NSLeftMouseDown:
				collectEvents = NO;
			default:
				break;
		}
	}
	[timer invalidate];
	[timer release];
	CGSSetGlobalHotKeyOperatingMode(conn, CGSGlobalHotKeyEnable);
	[self updateStringForHotKey];
	[displayTextView setBackgroundColor:[NSColor textBackgroundColor]];
}

@end
