//
//  UIFont+Replacement.m
//  FontReplacer
//
//  Created by Cédric Luthi on 2011-08-08.
//  Copyright (c) 2011 Cédric Luthi. All rights reserved.
//

#import "UIFont+Replacement.h"
#import <objc/runtime.h>

@implementation UIFont (Replacement)

static NSDictionary *replacementDictionary = nil;

static void initializeReplacementFonts() {
	static BOOL initialized = NO;
	if (initialized) {
    return;
  }
	initialized = YES;

	NSDictionary *replacementDictionary = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"ReplacementFonts"];
	[UIFont setReplacementDictionary:replacementDictionary];
}

+ (void)load {
  NSString *selectorName = @"fontWithName:size:";
  SEL tests = NSSelectorFromString([selectorName stringByAppendingString:@"traits:"]);

	Method fontWithName_size_ = class_getClassMethod([UIFont class], @selector(fontWithName:size:));
	Method fontWithName_size_tests_ = class_getClassMethod([UIFont class], tests);
	Method replacementFontWithName_size_ = class_getClassMethod([UIFont class], @selector(replacement_fontWithName:size:));
	Method replacementFontWithName_size_tests_ = class_getClassMethod([UIFont class], @selector(replacement_fontWithName:size:tests:));

	if (fontWithName_size_ && replacementFontWithName_size_ && strcmp(method_getTypeEncoding(fontWithName_size_), method_getTypeEncoding(replacementFontWithName_size_)) == 0) {
    method_exchangeImplementations(fontWithName_size_, replacementFontWithName_size_);
  }

	if (fontWithName_size_tests_ && replacementFontWithName_size_tests_ && strcmp(method_getTypeEncoding(fontWithName_size_tests_), method_getTypeEncoding(replacementFontWithName_size_tests_)) == 0) {
    method_exchangeImplementations(fontWithName_size_tests_, replacementFontWithName_size_tests_);
  }

	Method fontWithDescriptor_ = class_getClassMethod([UIFont class], @selector(fontWithDescriptor:size:));
	Method replacementFontWithDescriptor_ = class_getClassMethod([UIFont class], @selector(replacement_fontWithDescriptor:size:));

	if (fontWithDescriptor_ && replacementFontWithDescriptor_ && strcmp(method_getTypeEncoding(fontWithDescriptor_), method_getTypeEncoding(replacementFontWithDescriptor_)) == 0) {
    method_exchangeImplementations(fontWithDescriptor_, replacementFontWithDescriptor_);
  }
}

+ (UIFont *)replacement_fontWithDescriptor:(id)descriptor size:(CGFloat)pointSize {
	initializeReplacementFonts();
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-method-access"
  NSString *fontName = [descriptor fontAttributes][@"NSFontNameAttribute"];
#pragma clang diagnostic pop
	NSString *replacementFontName = replacementDictionary[fontName];
	return [self replacement_fontWithName:replacementFontName ?: fontName size:pointSize];
}

+ (UIFont *)replacement_fontWithName:(NSString *)fontName size:(CGFloat)fontSize {
	initializeReplacementFonts();
	NSString *replacementFontName = replacementDictionary[fontName];
	return [self replacement_fontWithName:replacementFontName ?: fontName size:fontSize];
}

+ (UIFont *)replacement_fontWithName:(NSString *)fontName size:(CGFloat)fontSize tests:(int)traits {
	initializeReplacementFonts();
	NSString *replacementFontName = replacementDictionary[fontName];
	return [self replacement_fontWithName:replacementFontName ?: fontName size:fontSize tests:traits];
}

+ (NSDictionary *)replacementDictionary {
  return replacementDictionary;
}

+ (void)setReplacementDictionary:(NSDictionary *)aReplacementDictionary {
	if (aReplacementDictionary == replacementDictionary) {
    return;
  }
	
	for (id key in [aReplacementDictionary allKeys]) {
		if (![key isKindOfClass:[NSString class]]) {
			NSLog(@"ERROR: Replacement font key must be a string.");
			return;
		}

		id value = [aReplacementDictionary valueForKey:key];
		if (![value isKindOfClass:[NSString class]]) {
			NSLog(@"ERROR: Replacement font value must be a string.");
			return;
		}
	}

	replacementDictionary = aReplacementDictionary;

	for (id key in [replacementDictionary allKeys]) {
		NSString *fontName = replacementDictionary[key];
		UIFont *font = [UIFont fontWithName:fontName size:10];
		if (!font) {
      NSLog(@"WARNING: replacement font '%@' is not available.", fontName);
    }
	}
}

@end
