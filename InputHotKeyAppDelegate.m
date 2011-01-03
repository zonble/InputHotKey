#import "InputHotKeyAppDelegate.h"

enum 
{
    ovkEsc =27, ovkSpace = 32, ovkReturn = 13,
    ovkDelete = 127, ovkBackspace = 8,
    ovkUp = 30, ovkDown = 31, ovkLeft = 28, ovkRight = 29,
    ovkHome = 1, ovkEnd = 4, ovkPageUp = 11, ovkPageDown = 12,
    ovkTab = 9
};

@implementation InputHotKeyAppDelegate

+ (NSString *)stringForModifiers: (unsigned int)aModifierFlags
{
	NSMutableString	*s = [NSMutableString string];
	unichar ch;
	
#define APPEND(x)  {ch = x; [s appendString:[NSString stringWithCharacters:&ch length:1]];}
    if (aModifierFlags & NSCommandKeyMask) APPEND(kCommandUnicode)
	if (aModifierFlags & NSAlternateKeyMask) APPEND(kOptionUnicode)
	if (aModifierFlags & NSControlKeyMask) APPEND(kControlUnicode)
	if (aModifierFlags & NSShiftKeyMask) APPEND(kShiftUnicode)		
#undef APPEND
	return s;
}

- (void) dealloc
{
	[inputArray release];
	[center release];
	[statusItem release];
	[super dealloc];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Insert code here to initialize your application 
	[inputTableView setDelegate:self];
	[inputTableView setDataSource:self];
	[hotKeyField setDelegate:self];

	inputArray = [[NSMutableArray alloc] init];
	center = [[DDHotKeyCenter alloc] init];
	
	NSLog(@"kTISTypeKeyboardLayout:%@", kTISTypeKeyboardLayout);
	
	CFArrayRef inputs = TISCreateInputSourceList(NULL, true);
	NSUInteger count = CFArrayGetCount(inputs);
	for (NSUInteger i = 0; i < count; i++) {
		TISInputSourceRef inputSource = CFArrayGetValueAtIndex(inputs, i);
		NSString *inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID);
		CFStringRef type = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceCategory);
		
		if (!CFStringCompare(type, kTISCategoryKeyboardInputSource, 0)) {		
			NSString *name = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName);
			IconRef icon = TISGetInputSourceProperty(inputSource, kTISPropertyIconRef);
			NSImage *image = [[[NSImage alloc] initWithIconRef:icon] autorelease];
			NSMutableDictionary *d = [NSMutableDictionary dictionary];
			[d setValue:inputSourceID forKey:@"id"];
			[d setValue:name forKey:@"name"];
			[d setValue:image forKey:@"image"];
			[inputArray addObject:d];
		}
	}
	CFRelease(inputs);
	
	[self load];
	[self resetHotKeys];

	[inputTableView reloadData];
	[inputTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	
	statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:32.0] retain];
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@"Menu"] autorelease];
	NSMenuItem *showWindowItem = [[[NSMenuItem alloc] init] autorelease];
	[showWindowItem setTitle:@"Show Hotkeys"];
	[showWindowItem setTarget:self];
	[showWindowItem setAction:@selector(showWindow:)];
	[menu addItem:showWindowItem];
	[menu addItem:[NSMenuItem separatorItem]];
	
	NSMenuItem *quitItem = [[[NSMenuItem alloc] init] autorelease];
	[quitItem setTitle:@"Quit"];
	[quitItem setTarget:self];
	[quitItem setAction:@selector(quit:)];
	[menu addItem:quitItem];	

	[statusItem setTitle:@"K"];
	[statusItem setMenu:menu];
}

- (IBAction)showWindow:(id)sender
{
	if (![window isVisible]) {
		[window center];
	}
	[window makeKeyAndOrderFront:self];
}

- (IBAction)quit:(id)sender
{
	[NSApp terminate:self];
}

- (void)load
{
	NSData *data = [[NSUserDefaults standardUserDefaults] dataForKey:@"hotkeys"];
	
	if (!data) {
		return;
	}
	
	NSDictionary *d = [NSUnarchiver unarchiveObjectWithData:data];
	for (NSMutableDictionary *input in inputArray) {
		NSString *key = [input valueForKey:@"id"];
		id hotkey = [d valueForKey:key];
		[input setValue:hotkey forKey:@"hotkey"];
	}
}
- (void)save
{
	NSMutableDictionary *d = [NSMutableDictionary dictionary];
	for (NSDictionary *input in inputArray) {
		id hotkey = [input valueForKey:@"hotkey"];
		if (hotkey && ![hotkey isKindOfClass:[NSNull class]]) {		
			NSString *key = [input valueForKey:@"id"];
			[d setValue:hotkey forKey:key];
		}
	}
	NSData *data = [NSArchiver archivedDataWithRootObject:d];
	[[NSUserDefaults standardUserDefaults] setValue:data forKey:@"hotkeys"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)resetHotKeys
{
	[center unregisterHotKeysWithTarget:self];
	for (NSDictionary *input in inputArray) {
		NSDictionary *hotkey = [input valueForKey:@"hotkey"];
		if (hotkey) {
			unsigned int modifiers = [[hotkey valueForKey:@"modifiers"] unsignedIntValue];
			unsigned short keyCode = [[hotkey valueForKey:@"keyCode"] unsignedShortValue];	
			[center registerHotKeyWithKeyCode:keyCode modifierFlags:modifiers target:self action:@selector(hotkeyWithEvent:object:) object:[input valueForKey:@"id"]];
		}
	}
}

#pragma mark -

- (void)hotkeyWithEvent:(NSEvent *)hkEvent object:(id)anObject 
{
	NSString *identifier = (NSString *)anObject;
	CFArrayRef inputs = TISCreateInputSourceList(NULL, true);
	NSUInteger count = CFArrayGetCount(inputs);
	for (NSUInteger i = 0; i < count; i++) {
		TISInputSourceRef inputSource = CFArrayGetValueAtIndex(inputs, i);
		NSString *inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID);
		if ([inputSourceID isEqualToString:identifier]) {
			TISEnableInputSource(inputSource);
			TISSelectInputSource(inputSource);
			break;
		}
	}
	CFRelease(inputs);
}


#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [inputArray count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{

	NSDictionary *d = [inputArray objectAtIndex:rowIndex];
	if ([[aTableColumn identifier] isEqualToString:@"icon"]) {
		return [d valueForKey:@"image"];
	}	
	else if ([[aTableColumn identifier] isEqualToString:@"name"]) {
		return [d valueForKey:@"name"];
	}
	else if ([[aTableColumn identifier] isEqualToString:@"hotkey"]) {
		NSDictionary *hotkey = [d valueForKey:@"hotkey"];
		if ([hotkey isKindOfClass:[NSDictionary class]]) {
			unsigned int modifiers = [[hotkey valueForKey:@"modifiers"] unsignedIntValue];
			NSString *character = [hotkey valueForKey:@"character"];
			if (!character) {
				character = @"";
			}
			NSString *newString = [InputHotKeyAppDelegate stringForModifiers:modifiers];
			newString = [NSString stringWithFormat:@"%@%@", newString, character];
			return newString;
		}
	}
	
	return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSUInteger row = [inputTableView selectedRow];
	NSDictionary *d = [[inputArray objectAtIndex:row] valueForKey:@"hotkey"];
	[hotKeyField setHotKey:d];
	[hotKeyField updateStringForHotKey];
}

#pragma mark -

- (BOOL)hotKeyField:(HotKeyField *)inHotKeyField hotKeyIsRegistered:(NSDictionary *)inHotKey
{
	unsigned int modifiers = [[inHotKey valueForKey:@"modifiers"] unsignedIntValue];
	unsigned short keyCode = [[inHotKey valueForKey:@"keyCode"] unsignedShortValue];	
	return [center hasRegisteredHotKeyWithKeyCode:keyCode modifierFlags:modifiers];
}
- (void)hotKeyField:(HotKeyField *)inHotKeyField didSetHotKey:(NSDictionary *)inHotKey
{
	NSUInteger row = [inputTableView selectedRow];
	NSMutableDictionary *d = [inputArray objectAtIndex:row];
	[d setValue:inHotKey forKey:@"hotkey"];
	[inputTableView reloadData];

	[self save];
	[self resetHotKeys];
}
- (void)hotKeyFieldDidClear:(HotKeyField *)inHotKeyField
{
	NSUInteger row = [inputTableView selectedRow];
	NSMutableDictionary *d = [inputArray objectAtIndex:row];
	[d removeObjectForKey:@"hotkey"];
	[inputTableView reloadData];

	[self save];
	[self resetHotKeys];
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(showWindow:)) {
		if ([window isMiniaturized]) {
			[menuItem setState:NSMixedState];
		}
		else if ([window isVisible]) {
			[menuItem setState:NSOnState];
		}
		else {
			[menuItem setState:NSOffState];
		}

	}
	
	return YES;
}


@synthesize window;
@synthesize inputTableView;
@synthesize hotKeyField;

@end
