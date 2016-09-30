//
//  UIControl+HapticHelper.m
//
//  Created by Michael Sprindzuikate on 30/09/2016.
//

#import <objc/runtime.h>
#import "UIControl+HapticHelper.h"

NSString const *selectionGeneratorKey = @"com.hapticHelper.selectionGenerator";
NSString const *useHapticsKey = @"com.hapticHelper.useHaptics";

@interface UIControl()
    
@property (nonatomic) UISelectionFeedbackGenerator *selectionFeedbackGenerator;
@property (nonatomic) BOOL useHaptics;

@end

@implementation UIControl (HapticHelper)

+ (void)load {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class class = [self class];
        
        SEL originalSelector = @selector(touchesBegan:withEvent:);
        SEL updatedSelector = @selector(swizzledTouchesBegan:withEvent:);
       
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method updatedMethod = class_getInstanceMethod(class, updatedSelector);
        
        BOOL addedMethodSuccessfully = class_addMethod(class, originalSelector, method_getImplementation(updatedMethod), method_getTypeEncoding(updatedMethod));
        
        if (addedMethodSuccessfully) {
            
            class_replaceMethod(class, updatedSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, updatedMethod);
        }
        
    });
}

- (void)enableHapticFeedback {
    
    
    if ([self isSupported]) {
        self.selectionFeedbackGenerator = [UISelectionFeedbackGenerator new];
        [self.selectionFeedbackGenerator prepare];
        
        self.useHaptics = YES;
    }
}


- (void)swizzledTouchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIPressesEvent *)event {
    
    if (self.useHaptics) {
        [self.selectionFeedbackGenerator selectionChanged];
        [self.selectionFeedbackGenerator prepare];
    }
    
    [self swizzledTouchesBegan:touches withEvent:event];
}


#pragma mark 

- (BOOL)isSupported {
    
    return  ([[[UIDevice currentDevice] systemVersion] compare:@"10.0" options:NSNumericSearch] != NSOrderedAscending);
}

- (void)setSelectionFeedbackGenerator:(UISelectionFeedbackGenerator *)selectionFeedbackGenerator {
    
    objc_setAssociatedObject(self, &selectionGeneratorKey, selectionFeedbackGenerator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UISelectionFeedbackGenerator *)selectionFeedbackGenerator {
    return objc_getAssociatedObject(self, &selectionGeneratorKey);
}

- (BOOL)useHaptics {
    
    return [objc_getAssociatedObject(self, &useHapticsKey) boolValue];
}

- (void)setUseHaptics:(BOOL)useHaptics {
    objc_setAssociatedObject(self, &useHapticsKey, @(useHaptics), OBJC_ASSOCIATION_ASSIGN);
}



@end
