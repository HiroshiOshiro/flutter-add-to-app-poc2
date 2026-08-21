#import "InputViewController.h"
#import "ConfirmViewController.h"
#import "LegacyApp-Swift.h"

static NSString *const kPrefsDraftName = @"draft_name";
static NSString *const kPrefsDraftEmail = @"draft_email";
static NSString *const kPrefsDraftMessage = @"draft_message";

@interface InputViewController ()

@property (nonatomic, strong) UITextField *nameField;
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UITextField *messageField;

@end

@implementation InputViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Use navigationItem.title (not self.title) so this doesn't also
    // overwrite the tab bar item's localized title on the enclosing tab.
    self.navigationItem.title = @"LegacyApp";
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scrollView];

    UILabel *greetingLabel = [[UILabel alloc] init];
    greetingLabel.text = NSLocalizedString(@"greeting", nil);
    greetingLabel.font = [UIFont boldSystemFontOfSize:20];
    greetingLabel.textAlignment = NSTextAlignmentCenter;

    UIImageView *banner = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ProfileBanner"]];
    banner.contentMode = UIViewContentModeScaleAspectFit;
    banner.translatesAutoresizingMaskIntoConstraints = NO;

    self.nameField = [self makeFieldWithPlaceholder:NSLocalizedString(@"label_name", nil)];
    self.emailField = [self makeFieldWithPlaceholder:NSLocalizedString(@"label_email", nil)];
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.messageField = [self makeFieldWithPlaceholder:NSLocalizedString(@"label_message", nil)];

    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [nextButton setTitle:NSLocalizedString(@"action_next", nil) forState:UIControlStateNormal];
    [nextButton addTarget:self action:@selector(onNextTapped) forControlEvents:UIControlEventTouchUpInside];
    nextButton.accessibilityIdentifier = @"buttonNext";

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[
        greetingLabel,
        banner,
        [self labeledRow:NSLocalizedString(@"label_name", nil) field:self.nameField],
        [self labeledRow:NSLocalizedString(@"label_email", nil) field:self.emailField],
        [self labeledRow:NSLocalizedString(@"label_message", nil) field:self.messageField],
        nextButton
    ]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 20;
    [stack setCustomSpacing:16 afterView:greetingLabel];
    [stack setCustomSpacing:24 afterView:banner];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [scrollView addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [banner.widthAnchor constraintEqualToConstant:96],
        [banner.heightAnchor constraintEqualToConstant:96],

        [stack.topAnchor constraintEqualToAnchor:scrollView.topAnchor constant:24],
        [stack.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor constant:24],
        [stack.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor constant:-24],
        [stack.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor constant:-24],
        [stack.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor constant:-48],
    ]];

    [self loadDraft];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Re-read the draft every time this screen appears, e.g. after coming
    // back from Complete, the same way the Android InputActivity does.
    [self loadDraft];
}

- (UITextField *)makeFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.borderStyle = UITextBorderStyleRoundedRect;
    [field addTarget:self action:@selector(onFieldChanged) forControlEvents:UIControlEventEditingChanged];
    return field;
}

- (UIView *)labeledRow:(NSString *)label field:(UITextField *)field {
    UILabel *l = [[UILabel alloc] init];
    l.text = label;
    l.textColor = [UIColor secondaryLabelColor];
    l.font = [UIFont systemFontOfSize:13];

    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[l, field]];
    row.axis = UILayoutConstraintAxisVertical;
    row.spacing = 4;
    return row;
}

- (void)onFieldChanged {
    [self saveDraft];
}

- (void)loadDraft {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.nameField.text = [defaults stringForKey:kPrefsDraftName] ?: @"";
    self.emailField.text = [defaults stringForKey:kPrefsDraftEmail] ?: @"";
    self.messageField.text = [defaults stringForKey:kPrefsDraftMessage] ?: @"";
}

- (void)saveDraft {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.nameField.text ?: @"" forKey:kPrefsDraftName];
    [defaults setObject:self.emailField.text ?: @"" forKey:kPrefsDraftEmail];
    [defaults setObject:self.messageField.text ?: @"" forKey:kPrefsDraftMessage];
}

- (void)onNextTapped {
    FormData *data = BaseViewController.sharedFormData;
    data.name = self.nameField.text ?: @"";
    data.email = self.emailField.text ?: @"";
    data.message = self.messageField.text ?: @"";

    // ガイド追試: Flutter画面を開く導線に差し替え
    // ガイド追試: Flutter画面を開く導線に差し替え
    UIViewController *flutterVC = [FlutterScreenLauncher viewControllerWithRoute:@"/confirm"];
    [self.navigationController pushViewController:flutterVC animated:YES];
}

@end
