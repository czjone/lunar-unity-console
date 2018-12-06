//
//  LUCVarEditController.m
//
//  Lunar Unity Mobile Console
//  https://github.com/SpaceMadness/lunar-unity-console
//
//  Copyright 2018 Alex Lementuev, SpaceMadness.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "LUCVarEditController.h"

#import "Lunar-Full.h"

@interface LUCVarEditController () <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate>
{
    __weak LUCVar * _variable;
}

@property (nonatomic, weak) IBOutlet UISlider * slider;
@property (nonatomic, weak) IBOutlet UITextField * textField;
@property (nonatomic, weak) IBOutlet UIView * editContainerView;
@property (nonatomic, weak) IBOutlet UIPickerView * pickerView;
@property (nonatomic, weak) IBOutlet UILabel *errorLabel;

@end

@implementation LUCVarEditController

- (instancetype)initWithVariable:(LUCVar *)variable
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        _variable = variable;
        self.popupTitle = _variable.name;
        self.popupIcon = LUGetImage(@"lunar_console_icon_settings");
        self.popupButtons = @[
            [LUConsolePopupButton buttonWithIcon:LUGetImage(@"lunar_console_icon_button_variable_reset")
                        target:self
                        action:@selector(onResetButton:)]
        ];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [LUTheme mainTheme].backgroundColorDark;
	
	_pickerView.hidden = YES;
	_editContainerView.hidden = YES;
	_errorLabel.hidden = YES;
	
	if (_variable.type == LUCVarTypeFloat && _variable.hasRange)
    {
		_editContainerView.hidden = NO;
		
		CGFloat min = _variable.range.min;
        CGFloat max = _variable.range.max;
        if (max - min > 0.000001)
        {
            _slider.minimumValue = min;
            _slider.maximumValue = max;
			_slider.hidden = NO;
            _slider.value = [_variable.value floatValue];
        }
        else
        {
            _slider.enabled = NO;
			_errorLabel.hidden = NO;
            _errorLabel.text = [NSString stringWithFormat:@"Invalid range [%g, %g]", min, max];
        }
    }
	else if (_variable.type == LUCVarTypeEnum)
	{
		_pickerView.hidden = NO;
		_pickerView.delegate = self;
		_pickerView.dataSource = self;
	}
    else
	{
		_editContainerView.hidden = NO;
    }
    
    _textField.text = _variable.value;
}

#pragma mark -
#pragma mark Actions

- (IBAction)sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    _textField.text = [[NSString alloc] initWithFormat:@"%g", slider.value];
}

- (IBAction)sliderEditingFinished:(id)sender
{
    UISlider *slider = sender;
    NSString *value = [[NSString alloc] initWithFormat:@"%g", slider.value];
    
    _textField.text = value;
    [self notifyValueUpdate:value];
}

- (void)onResetButton:(id)sender
{
    _textField.text = _variable.defaultValue;
    if (_variable.type == LUCVarTypeFloat && _variable.hasRange)
    {
        _slider.value = [_variable.defaultValue floatValue];
    }
    [self notifyValueUpdate:_variable.defaultValue];
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    NSString *valueText = textField.text;
    if ([self isValidValue:valueText])
    {
        if (_variable.type == LUCVarTypeFloat)
        {
            float value;
            LUStringTryParseFloat(valueText, &value);
            if (_variable.hasRange)
            {
                if (value < _variable.range.min)
                {
                    value = _variable.range.min;
                }
                else if (value > _variable.range.max)
                {
                    value = _variable.range.max;
                }
                _slider.value = value;
            }
            [self notifyValueUpdate:[[NSString alloc] initWithFormat:@"%g", value]];
        }
        else
        {
            [self notifyValueUpdate:valueText];
        }
    }
    else
    {
        LUDisplayAlertView(@"Input Error", [NSString stringWithFormat:@"Invalid value: '%@'", valueText]);
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark -
#pragma mark UIPickerViewDataSource

// returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
	return 1;
}

// returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
	return _variable.allValues.count;
}

#pragma mark -
#pragma mark UIPickerViewDelegate

- (nullable NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return _variable.allValues[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	NSLog(@"Selected value: %@", _variable.allValues[row]);
}

#pragma mark -
#pragma mark Value

- (BOOL)isValidValue:(NSString *)value
{
    switch (_variable.type)
    {
        case LUCVarTypeFloat:
            return LUStringTryParseFloat(value, NULL);
        case LUCVarTypeInteger:
            return LUStringTryParseInteger(value, NULL);
        default:
            return YES;
    }
}

- (void)notifyValueUpdate:(NSString *)value
{
    if (![_variable.value isEqualToString:value])
    {
        if ([_delegate respondsToSelector:@selector(editController:didChangeValue:)])
        {
            [_delegate editController:self didChangeValue:value];
        }
    }
}

#pragma mark -
#pragma mark Popup Controller

- (CGSize)preferredPopupSize
{
    return CGSizeMake(0, 70);
}

@end
