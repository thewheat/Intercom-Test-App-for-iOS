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
@property (nonatomic, weak) IBOutlet UIButton *setPadding;
@property (nonatomic, assign) BOOL enableUnread;

@property (nonatomic, weak) IBOutlet UITextField *userid;
@property (nonatomic, weak) IBOutlet UITextField *email;
@property (nonatomic, weak) IBOutlet UITextField *name;

@property (nonatomic, weak) IBOutlet UITextField *activeField;
@property (nonatomic, weak) IBOutlet UINavigationBar *navBar;

@property (nonatomic, weak) IBOutlet UITextField *bottomPadding;

@property (nonatomic, weak) IBOutlet UITextField *custom_attribute_name;
@property (nonatomic, weak) IBOutlet UITextField *custom_attribute_value;
@property (nonatomic, weak) IBOutlet UISwitch *custom_attribute;

@property (nonatomic, weak) IBOutlet UITextField *event_name;
@property (nonatomic, weak) IBOutlet UITextField *event_metadata_name;
@property (nonatomic, weak) IBOutlet UITextField *event_metadata_value;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

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

    self.scrollView = nil;
    for(int i = 0; i < self.view.subviews.count; i++){
        if([self.view.subviews[i] isKindOfClass:[UIScrollView class]]){
            self.scrollView = self.view.subviews[i];
        }
        else if([self.view.subviews[i] isKindOfClass:[UINavigationBar class]]){
            self.navBar = self.view.subviews[i];
        }
    }
    [self registerForKeyboardNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUnreadCount:) name:IntercomUnreadConversationCountDidChangeNotification object:nil];
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
        [Intercom setUserHash:hexadecimalString(hmacForKeyAndData(secret, data))];
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
        self.settings_sdk_api_key = [matches valueForKey:@"sdk_api_key"];
        self.settings_app_id = [matches valueForKey:@"app_id"];
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
- (IBAction)deepLinkDone:(UIButton *)sender {
    [self performSegueWithIdentifier:@"unwindToMain" sender:self];
}
- (IBAction) unwindToMain:(UIStoryboardSegue *) sender{
}


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
    [self updateNameIfNecessary];
}


- (void)updateNameIfNecessary {
    if(self.name.text.length > 0){
        ICMUserAttributes *userAttributes = [ICMUserAttributes new];
        userAttributes.name = self.name.text;
        [Intercom updateUser:userAttributes];
    }
}

- (IBAction)loginUnidentified:(id)sender {
    NSLog(@"Sign in as unregistered user");
    [Intercom registerUnidentifiedUser];
    [self updateNameIfNecessary];
}
- (IBAction)updateCustomAttributePressed:(id)sender {
    NSLog(@"Update Custom Attribute. Name: %@ / Value: %@", self.custom_attribute_name.text, self.custom_attribute_value.text);

    ICMUserAttributes *userAttributes = [ICMUserAttributes new];
    if(self.custom_attribute.isOn){
        userAttributes.customAttributes = @{self.custom_attribute_name.text : self.custom_attribute_value.text};
        [Intercom updateUser:userAttributes];
    }
    else{
        Boolean found = false;
        if ([self.custom_attribute_name.text.lowercaseString isEqualToString:@"name"]){
            found = true;
            userAttributes.name = self.custom_attribute_value.text;
        }
        else if ([self.custom_attribute_name.text.lowercaseString isEqualToString:@"phone"]){
            found = true;
            userAttributes.phone = self.custom_attribute_value.text;
        }
        else if ([self.custom_attribute_name.text.lowercaseString isEqualToString:@"email"]){
            found = true;
            userAttributes.email = self.custom_attribute_value.text;
        }
        else if ([self.custom_attribute_name.text.lowercaseString isEqualToString:@"languageoverride"]
                 || [self.custom_attribute_name.text.lowercaseString isEqualToString:@"language_override"]){
            found = true;
            userAttributes.languageOverride = self.custom_attribute_value.text;
        }
        else if ([self.custom_attribute_name.text.lowercaseString isEqualToString:@"created_at"]
                 || [self.custom_attribute_name.text.lowercaseString isEqualToString:@"remote_created_at"]
                 || [self.custom_attribute_name.text.lowercaseString isEqualToString:@"signed_up_at"] ){
            found = true;
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.custom_attribute_value.text.intValue];
            userAttributes.signedUpAt = date;
        }
        else if ([self.custom_attribute_name.text.lowercaseString isEqualToString:@"unsubscribed_from_emails"]){
            found = true;
            userAttributes.unsubscribedFromEmails = [self.custom_attribute_value.text.lowercaseString isEqualToString:@"true"];
        }
        if (found){
            [Intercom updateUser:userAttributes];
        }
        else{
            NSString *message = [NSString stringWithFormat:@"Unrecognized standard attribute"];
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
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
    [Intercom setInAppMessagesVisible:NO];
}
- (IBAction)interfaceShowPressed:(id)sender {
    [Intercom setInAppMessagesVisible:YES];
}

- (IBAction)setPadding:(id)sender {
    float floatvalue = [self.bottomPadding.text floatValue];
    [Intercom setBottomPadding:floatvalue];
}
- (IBAction)showLauncher:(id)sender {
    [Intercom setLauncherVisible:YES];
}
- (IBAction)hideLauncher:(id)sender {
    [Intercom setLauncherVisible:NO];
}
- (IBAction)showMesseger:(id)sender {
    [Intercom presentMessenger];
}
- (IBAction)hideMessenger:(id)sender {
    [self performSelector:@selector(hideAfter5Seconds) withObject:self afterDelay:5.0 ];
}
- (void)hideAfter5Seconds {
    [Intercom hideMessenger];
}

- (IBAction)unreadCountShow:(id)sender {
    NSUInteger count = [Intercom unreadConversationCount];
    NSLog(@"Show unread count %tu", count);
    NSString *message = [NSString stringWithFormat:@"Unread count %tu", count];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}
- (IBAction)unreadCountEnable:(id)sender {
    NSLog(@"Show unread count enable");
    self.enableUnread = true;
}

- (IBAction)unreadCountDisable:(id)sender {
    NSLog(@"Show unread count disable");
    self.enableUnread = false;
}

- (void)updateUnreadCount:(id)sender {
    NSUInteger count = [Intercom unreadConversationCount];
    NSString *message = [NSString stringWithFormat:@"Unread count %tu", count];
    NSLog(@"Observer unread count %tu", count);
    if (self.enableUnread){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
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



// https://developer.apple.com/library/ios/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
// Call this method somewhere in your view controller setup code.
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSLog(@"show keyboard");
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;

    // If active text field is hidden by keyboard, scroll it so it's visible
    // Your app might not need or want this behavior.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeField.frame animated:YES];
    }

    // TODO: a better way to do this. Couldn't find a way to dismiss keyboard in order to change navigate away
    [self showBackIcon];
}


- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    NSLog(@"hide keyboard");
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

-(void) dismissKeyboardAndHideBackIcon{
    [self endEditing];
    [self hideBackIcon];
}
-(void) endEditing{
    [self.view endEditing:YES];
}
-(void) showBackIcon{
    UIButton *backButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    [backButton setImage:[UIImage imageNamed:@"Back-100.png"] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(dismissKeyboardAndHideBackIcon) forControlEvents:UIControlEventTouchUpInside];
    if(self.navBar.items.count > 0) self.navBar.items[0].leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
}
-(void) hideBackIcon{
    if(self.navBar.items.count > 0){
        self.navBar.items[0].leftBarButtonItem = nil;
    }
}

@end
