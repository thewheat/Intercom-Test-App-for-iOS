#import "ViewController.h"
#import <CommonCrypto/CommonHMAC.h>
@import Intercom;

void intercomCheckSecureMode(NSString* data);


@interface ViewController ()

@property (nonatomic, weak) IBOutlet UIButton *logoutButton;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIButton *loginUnidentifiedButton;
@property (nonatomic, weak) IBOutlet UIButton *sendMessageButton;
@property (nonatomic, weak) IBOutlet UIButton *showConversationsButton;
@property (nonatomic, assign) BOOL loggedIn;

@property (nonatomic, weak) IBOutlet UITextField *userid;
@property (nonatomic, weak) IBOutlet UITextField *email;
@property (nonatomic, weak) IBOutlet UITextField *name;



@property (nonatomic, weak) IBOutlet UITextField *custom_attribute_name;
@property (nonatomic, weak) IBOutlet UITextField *custom_attribute_value;

@property (nonatomic, weak) IBOutlet UITextField *event_name;
@property (nonatomic, weak) IBOutlet UITextField *event_metadata_name;
@property (nonatomic, weak) IBOutlet UITextField *event_metadata_value;


@property (nonatomic, weak) IBOutlet UITextField *app_id;
@property (nonatomic, weak) IBOutlet UITextField *sdk_api_key;
@property (nonatomic, weak) IBOutlet UITextField *secret_key;

@property (nonatomic, assign) NSString *settings_app_id;
@property (nonatomic, assign) NSString *settings_sdk_api_key;
@property (nonatomic, assign) NSString *settings_secret_key;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSLog(@"viewDidLoad");
    [self readSettings];
    [self populateSettings];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) populateSettings{
    self.app_id.text = self.settings_app_id;
    self.sdk_api_key.text = self.settings_sdk_api_key;
    self.secret_key.text = self.settings_secret_key;
}


-(void)intercomCheckSecureMode:(NSString*) data {
    [self readSettings];
    NSString *secret = self.settings_secret_key; //settings.getValue(Settings.SDK_SECURE_MODE_SECRET_KEY);
    NSLog(@"Check secure mode. Data: %@ / Set Secure mode?: %@ %@",  data, (secret.length > 0 ? @"Yes":@"No"), hexadecimalString(hmacForKeyAndData(secret, data)));
    if(secret.length > 0 ) {
        [Intercom setHMAC:hexadecimalString(hmacForKeyAndData(secret, data)) data:data];
    }
}
// TODO: refactor settings because I do not know how to properly iOS yet - 1
-(void)readSettings{
    AppDelegate *appDelegate =[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appDelegate managedObjectContext];
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Settings" inManagedObjectContext:context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDesc];
    
    NSManagedObject *matches = nil;
    
    NSError *error;
    NSArray *objects = [context executeFetchRequest:request
                                              error:&error];
    
    if ([objects count] == 0) {
        NSLog(@"No matches");
        // hardcode values for testing
        self.settings_sdk_api_key = @"";
        self.settings_app_id = @"";
        self.settings_secret_key = @"";
    } else {
        matches = objects[0];
        NSLog(@"Loading saved settings for %@", [matches valueForKey:@"app_id"]);
        self.settings_sdk_api_key = [matches valueForKey:@"app_id"];
        self.settings_app_id = [matches valueForKey:@"sdk_api_key"];
        self.settings_secret_key = [matches valueForKey:@"secret_key"];
    }
}

- (IBAction)saveSettingsAndClosedPressed:(id)sender {
    NSLog(@"Save settings and Close");
    [self saveSettingsPressed:sender];
    exit(0);
}
- (IBAction)saveSettingsPressed:(id)sender {
    NSLog(@"Save settings");
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context =    [appDelegate managedObjectContext];
    
    
    NSFetchRequest *allCars = [[NSFetchRequest alloc] init];
    [allCars setEntity:[NSEntityDescription entityForName:@"Settings" inManagedObjectContext:context]];
    [allCars setIncludesPropertyValues:NO]; //only fetch the managedObjectID
    
    NSError *error = nil;
    NSArray *cars = [context executeFetchRequest:allCars error:&error];
    //    [allCars release];
    //error handling goes here
    for (NSManagedObject *car in cars) {
        [context deleteObject:car];
    }
    NSError *saveError = nil;
    [context save:&saveError];
    
    NSManagedObject *newSettings;
    newSettings = [NSEntityDescription
                   insertNewObjectForEntityForName:@"Settings"
                   inManagedObjectContext:context];
    [newSettings setValue: self.app_id.text forKey:@"app_id"];
    [newSettings setValue: self.sdk_api_key.text forKey:@"sdk_api_key"];
    [newSettings setValue: self.secret_key.text forKey:@"secret_key"];
    
    [context save:&error];
}
// TODO: refactor settings because I do not know how to properly iOS yet - 0

- (IBAction)logoutPressed:(id)sender {
    NSLog(@"Logout");
    [Intercom reset];
}
- (IBAction)loginIdentifiedPressed:(id)sender {
    NSLog(@"Sign in as registered user. email: %@ / user_id: %@", self.email.text, self.userid.text);
    NSString* data = self.email.text;
    if(self.userid.text.length > 0){
        data = self.userid.text;
    }

    [self intercomCheckSecureMode:data];
    if(self.email.text.length > 0 && self.userid.text.length > 0){
        [Intercom registerUserWithUserId:self.userid.text email:self.email.text];
    }else if(self.email.text.length > 0){
        [Intercom registerUserWithEmail:self.email.text];
    }else{
        [Intercom registerUserWithUserId:self.userid.text];
    }
}



- (IBAction)loginUnidentified:(id)sender {
    NSLog(@"Sign in as unregistered user");
    [Intercom registerUnidentifiedUser];
}
- (IBAction)updateCustomAttributePressed:(id)sender {
    NSLog(@"Update Custom Attribute. Name: %@ / Value: %@", self.custom_attribute_name.text, self.custom_attribute_value.text);
    [Intercom updateUserWithAttributes:@{@"custom_attributes": @{self.custom_attribute_name.text : self.custom_attribute_value.text}}];
}
- (IBAction)submitEventPressed:(id)sender {
    NSLog(@"Submit Event. Name: %@ / Meta Data Name: %@ / Meta Data Value: %@", self.event_name.text, self.event_metadata_name.text, self.event_metadata_value.text);
    
    if(self.event_metadata_name.text.length > 0 && self.event_metadata_value.text.length > 0){
        [Intercom logEventWithName:self.event_name.text metaData: @{self.event_metadata_name.text : self.event_metadata_value.text}];
    }
    else{
        [Intercom logEventWithName:self.event_name.text];
    }

}

- (IBAction)openIntercomPressed:(id)sender {
    [Intercom presentConversationList];
}
- (IBAction)newMessagePressed:(id)sender {
    [Intercom presentMessageComposer];
}


- (IBAction)interfaceHidePressed:(id)sender {
    [Intercom setMessagesHidden:YES];
}
- (IBAction)interfaceShowPressed:(id)sender {
    [Intercom setMessagesHidden:NO];
}

- (IBAction)positionTopLeftPressed:(id)sender {
    [Intercom setPreviewPosition:ICMPreviewPositionTopLeft];
}
- (IBAction)positionTopRightPressed:(id)sender {
    [Intercom setPreviewPosition:ICMPreviewPositionTopRight];
}
- (IBAction)positionBottomLeftPressed:(id)sender {
    [Intercom setPreviewPosition:ICMPreviewPositionBottomLeft];
}
- (IBAction)positionBottomRightPressed:(id)sender {
    [Intercom setPreviewPosition:ICMPreviewPositionBottomRight];
}


NSData *hmacForKeyAndData(NSString *key, NSString *data)
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    return [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
}

// http://stackoverflow.com/a/9084784
NSString *hexadecimalString(NSData *data){
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[data bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [data length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

- (IBAction)attributionLink:(id)sender {
    NSURL *url = [NSURL URLWithString:@"https://icons8.com"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}

- (IBAction)iconGenerator:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.gieson.com/Library/projects/utilities/icon_slayer/"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url];
    }
}



@end
