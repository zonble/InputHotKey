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
	[super dealloc];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification 
{
	// Insert code here to initialize your application 
	[inputTableView setDelegate:self];
	[inputTableView setDataSource:self];
	inputArray = [[NSMutableArray alloc] init];
	
	CFArrayRef inputs = TISCreateInputSourceList(NULL, true);
	NSUInteger count = CFArrayGetCount(inputs);
	for (NSUInteger i = 0; i < count; i++) {
		TISInputSourceRef inputSource = CFArrayGetValueAtIndex(inputs, i);
		NSString *inputSourceID = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceID);
		NSString *type = TISGetInputSourceProperty(inputSource, kTISPropertyInputSourceCategory);
		NSString *name = TISGetInputSourceProperty(inputSource, kTISPropertyLocalizedName);
		IconRef icon = TISGetInputSourceProperty(inputSource, kTISPropertyIconRef);
		NSImage *image = [[[NSImage alloc] initWithIconRef:icon] autorelease];
		NSMutableDictionary *d = [NSMutableDictionary dictionary];
		[d setValue:inputSourceID forKey:@"id"];
		[d setValue:name forKey:@"name"];
		[d setValue:image forKey:@"image"];
		[inputArray addObject:d];
	}
	CFRelease(inputs);
	[inputTableView reloadData];
	NSData *data = [NSArchiver archivedDataWithRootObject:inputArray];
	[[NSUserDefaults standardUserDefaults] setValue:data forKey:@"keys"];
}

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
	
	return nil;
}

@synthesize window;
@synthesize inputTableView;

@end
