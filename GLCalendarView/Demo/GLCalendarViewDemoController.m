//
//  ViewController.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-16.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLCalendarViewDemoController.h"
#import "GLCalendarView.h"
#import "GLCalendarDateRange.h"
#import "GLDateUtils.h"
#import "GLCalendarDayCell.h"

#define UIColorFromRGB(rgbValue) \
[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface GLCalendarViewDemoController ()<GLCalendarViewDelegate>
@property (nonatomic, strong) GLCalendarDateRange *rangeUnderEdit;

@property (strong, nonatomic) GLCalendarView *calendarView;


@end

@implementation GLCalendarViewDemoController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)showCalendarView
{
    [GLDateUtils changeTimeZoneAbbreviation:@"PDT"];
    self.calendarView = [[GLCalendarView alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width , self.view.bounds.size.height - 100)];
    [self.view addSubview:self.calendarView];
    self.calendarView.delegate = self;
    self.calendarView.showMagnifier = YES;
    

    
    [self.calendarView reload];
    
    if (self.rangeUnderEdit != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.calendarView scrollToDate:self.rangeUnderEdit.beginDate animated:NO];
            [self.calendarView initRangUnderEdit:self.rangeUnderEdit];
            [self.calendarView addRange:self.rangeUnderEdit];
            
        });
        
    }
}

- (IBAction)showButtonClick:(id)sender
{
    [self showCalendarView];
}

- (void)hideCalendarView
{
    [self.calendarView removeFromSuperview];
    self.calendarView = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
    
}


- (BOOL)checkValidDay:(NSDate*)date
{
    if ([GLDateUtils date:date isEarlyDate:[self.calendarView todayDate]])
    {
        return NO;
    }
    return  YES;
}

- (BOOL)calenderView:(GLCalendarView *)calendarView canAddRangeWithBeginDate:(NSDate *)beginDate
{
    return [self checkValidDay:beginDate];
}


- (NSString*)calenderView:(GLCalendarView *)calendarView tipShowByBeginDate:(NSDate*)begindate endDate:(NSDate*)enddate
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    NSString *stringBegin = [formatter stringFromDate:begindate];
    NSString *stringEnd = [formatter stringFromDate:enddate];
    NSString *message = [NSString stringWithFormat:@"%@ - %@ (Drag point to change the date)",stringBegin,stringEnd];

    return message;
}

- (GLCalendarDateRange *)calenderView:(GLCalendarView *)calendarView rangeToAddWithBeginDate:(NSDate *)beginDate
{
    NSDate* endDate = [GLDateUtils dateByAddingDays:1 toDate:beginDate];
    GLCalendarDateRange *range = [GLCalendarDateRange rangeWithBeginDate:beginDate endDate:endDate];
    range.backgroundColor = UIColorFromRGB(0x80ae99);
    range.editable = YES;
    [calendarView beginToEditRange:range];
    self.rangeUnderEdit = range;
    return range;
}

- (void)calenderView:(GLCalendarView *)calendarView beginToEditRange:(GLCalendarDateRange *)range
{
    NSLog(@"begin to edit range: %@", range);
    self.rangeUnderEdit = range;
}

- (void)calenderView:(GLCalendarView *)calendarView finishEditRange:(GLCalendarDateRange *)range continueEditing:(BOOL)continueEditing
{
    NSLog(@"finish edit range: %@", range);
//    self.rangeUnderEdit = nil;
}

- (BOOL)calenderView:(GLCalendarView *)calendarView canUpdateRange:(GLCalendarDateRange *)range toBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    return [self checkValidDay:beginDate];
}

- (void)calenderView:(GLCalendarView *)calendarView didUpdateRange:(GLCalendarDateRange *)range toBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    NSLog(@"did update range: %@", range);
}

- (IBAction)deleteButtonPressed:(id)sender
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    NSString *stringBegin = [formatter stringFromDate:self.rangeUnderEdit.beginDate];
    NSString *stringEnd = [formatter stringFromDate:self.rangeUnderEdit.endDate];

    self.beginDateLabel.text = stringBegin;
    self.endDateLabel.text = stringEnd;
    [self hideCalendarView];
    
}

@end
