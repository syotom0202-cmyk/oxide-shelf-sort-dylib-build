#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>

typedef void (*OSSUnitySendMessage)(const char *gameObject, const char *method, const char *message);

@interface OSSActionTarget : NSObject
+ (instancetype)sharedTarget;
- (void)pressed:(UIButton *)sender;
@end

static OSSUnitySendMessage oss_send_message(void) {
    void *handle = dlopen(NULL, RTLD_NOW);
    if (handle == NULL) {
        return NULL;
    }

    OSSUnitySendMessage send = (OSSUnitySendMessage)dlsym(handle, "UnitySendMessage");
    if (send == NULL) {
        send = (OSSUnitySendMessage)dlsym(handle, "_UnitySendMessage");
    }
    dlclose(handle);
    return send;
}

static void oss_try_sort(void) {
    OSSUnitySendMessage send = oss_send_message();
    if (send == NULL) {
        NSLog(@"[OxideShelfSort] UnitySendMessage is not available");
        return;
    }

    /*
     * The current asset contains the existing ui_tab_sort Button.  Press is
     * the no-argument entry used by Unity UI Button to invoke its onClick
     * event.  The clone name covers instantiated prefab objects.
     */
    const char *objects[] = {"ui_tab_sort", "ui_tab_sort(Clone)"};
    const char *methods[] = {"Press"};

    for (NSUInteger i = 0; i < sizeof(objects) / sizeof(objects[0]); i++) {
        for (NSUInteger j = 0; j < sizeof(methods) / sizeof(methods[0]); j++) {
            send(objects[i], methods[j], "");
        }
    }
}

static UIWindow *oss_key_window(void) {
    UIApplication *application = UIApplication.sharedApplication;
    for (UIWindow *window in application.windows.reverseObjectEnumerator) {
        if (!window.hidden && window.alpha > 0.0 && window.windowLevel == UIWindowLevelNormal) {
            return window;
        }
    }
    return application.keyWindow;
}

static void oss_install_button(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = oss_key_window();
        if (window == nil || window.rootViewController.view == nil) {
            return;
        }

        UIView *root = window.rootViewController.view;
        if ([root viewWithTag:0x4F5353] != nil) {
            return;
        }

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.tag = 0x4F5353;
        button.frame = CGRectMake(CGRectGetWidth(root.bounds) - 92.0, 24.0, 76.0, 36.0);
        button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
        button.layer.cornerRadius = 8.0;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.45].CGColor;
        [button setTitle:@"SORT" forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:13.0];
        [button addTarget:[OSSActionTarget sharedTarget]
                   action:@selector(pressed:)
         forControlEvents:UIControlEventTouchUpInside];
        [root addSubview:button];
    });
}

@implementation OSSActionTarget

+ (instancetype)sharedTarget {
    static OSSActionTarget *target;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        target = [OSSActionTarget new];
    });
    return target;
}

- (void)pressed:(UIButton *)sender {
    sender.alpha = 0.55;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        sender.alpha = 1.0;
        oss_try_sort();
    });
}

@end

__attribute__((constructor))
static void oss_init(void) {
    @autoreleasepool {
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(__unused NSNotification *note) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                oss_install_button();
            });
        }];
    }
}
