//
//  XLTestTextFieldProperties.m
//  XLForm Tests
//
//  Created by Claus on 9/5/16.
//
//

#import "XLTestCase.h"
#import <XLForm/XLFormTextFieldCell.h>
#import <UIKit/UIKit.h>

@interface XLTestTextFieldProperties : XLTestCase
@end

@implementation XLTestTextFieldProperties

- (void)testPropertiesGetSet
{
    // Get the tableView
    UITableView * tableView = self.formController.tableView;
    
    UITableViewCell * cell = [self.formController tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];

    // Check if the cell contains the correct properties
    expect(cell).to.beKindOf([XLFormTextFieldCell class]);
    XLFormTextFieldCell * textFieldCell = (XLFormTextFieldCell *)cell;
    expect(textFieldCell.textFieldLengthPercentage).to.equal(0.3);
    expect(textFieldCell.textFieldMaxNumberOfCharacters).to.equal(10);
}

- (void)testMaxNumbersOfCharacters
{
    // Get the tableView
    UITableView * tableView = self.formController.tableView;

    UITableViewCell * cell = [self.formController tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    expect(cell).to.beKindOf([XLFormTextFieldCell class]);
    XLFormTextFieldCell * textFieldCell = (XLFormTextFieldCell *)cell;

    // Check if range check works
    expect(cell).to.conformTo(@protocol(UITextFieldDelegate));
    id<UITextFieldDelegate> textFieldDelegate = (id<UITextFieldDelegate>)cell;
    NSRange range = NSMakeRange(0, 0);
    expect([textFieldDelegate textField:textFieldCell.textField shouldChangeCharactersInRange:range replacementString:@"123"]).to.beTruthy();
    expect([textFieldDelegate textField:textFieldCell.textField shouldChangeCharactersInRange:range replacementString:@"1234567890"]).to.beTruthy();
    expect([textFieldDelegate textField:textFieldCell.textField shouldChangeCharactersInRange:range replacementString:@"12345678901"]).to.beFalsy();
}

- (void)testDecimalNumberFromInputAcceptsBothSeparatorsInEveryLocale
{
    NSDecimalNumber *expected = [NSDecimalNumber decimalNumberWithString:@"33.45"];
    for (NSString *identifier in @[@"en_US", @"en_GB", @"de_DE", @"fr_FR", @"ar_SA"]) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:identifier];
        expect([XLFormTextFieldCell decimalNumberFromInput:@"33.45" locale:locale]).to.equal(expected);
        expect([XLFormTextFieldCell decimalNumberFromInput:@"33,45" locale:locale]).to.equal(expected);
        expect([XLFormTextFieldCell decimalNumberFromInput:@"-1.5" locale:locale]).to.equal([NSDecimalNumber decimalNumberWithString:@"-1.5"]);
        expect([XLFormTextFieldCell decimalNumberFromInput:@" 12 " locale:locale]).to.equal([NSDecimalNumber decimalNumberWithString:@"12"]);
        expect([XLFormTextFieldCell decimalNumberFromInput:@".5" locale:locale]).to.equal([NSDecimalNumber decimalNumberWithString:@"0.5"]);
    }
}

- (void)testDecimalNumberFromInputAcceptsLocaleSeparator
{
    NSLocale *arabic = [NSLocale localeWithLocaleIdentifier:@"ar_SA"];
    expect([XLFormTextFieldCell decimalNumberFromInput:@"33٫45" locale:arabic]).to.equal([NSDecimalNumber decimalNumberWithString:@"33.45"]);
}

- (void)testDecimalNumberFromInputRejectsPartialNumbers
{
    for (NSString *identifier in @[@"en_US", @"de_DE", @"fr_FR", @"ar_SA"]) {
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:identifier];
        for (NSString *input in @[@"12abc", @"33.45.6", @"1,234.5", @"33'45", @"0x10", @"-", @".", @"abc"]) {
            expect([XLFormTextFieldCell decimalNumberFromInput:input locale:locale]).to.equal([NSDecimalNumber notANumber]);
        }
    }
}

- (void)testDecimalRowStoresParsedValueOnEditingChanged
{
    UITableView * tableView = self.formController.tableView;
    UITableViewCell * cell = [self.formController tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    expect(cell).to.beKindOf([XLFormTextFieldCell class]);
    XLFormTextFieldCell * textFieldCell = (XLFormTextFieldCell *)cell;

    textFieldCell.textField.text = @"33,45";
    [self sendEditingChangedToTextField:textFieldCell.textField];
    expect(textFieldCell.rowDescriptor.value).to.equal([NSDecimalNumber decimalNumberWithString:@"33.45"]);

    textFieldCell.textField.text = @"12abc";
    [self sendEditingChangedToTextField:textFieldCell.textField];
    expect(textFieldCell.rowDescriptor.value).to.equal([NSDecimalNumber notANumber]);
}

#pragma mark - Helpers

// The test bundle has no host app, so sendActionsForControlEvents: can't dispatch through
// UIApplication. Invoke the registered editing-changed actions directly instead.
- (void)sendEditingChangedToTextField:(UITextField *)textField
{
    for (id target in textField.allTargets) {
        for (NSString *action in [textField actionsForTarget:target forControlEvent:UIControlEventEditingChanged]) {
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [target performSelector:NSSelectorFromString(action) withObject:textField];
            #pragma clang diagnostic pop
        }
    }
}

#pragma mark - Build Form

-(void)buildForm
{
    XLFormDescriptor * form = [XLFormDescriptor formDescriptor];
    XLFormSectionDescriptor * section = [XLFormSectionDescriptor formSection];
    [form addFormSection:section];
    
    XLFormRowDescriptor * row = [XLFormRowDescriptor formRowDescriptorWithTag:nil rowType:XLFormRowDescriptorTypeText];
    [row.cellConfigAtConfigure setObject:@(0.3) forKey:XLFormTextFieldLengthPercentage];
    [row.cellConfigAtConfigure setObject:@(10) forKey:XLFormTextFieldMaxNumberOfCharacters];
    [section addFormRow:row];

    [section addFormRow:[XLFormRowDescriptor formRowDescriptorWithTag:@"decimal" rowType:XLFormRowDescriptorTypeDecimal]];
    
    self.formController.form = form;
}

@end
