//
//  GLPeriodCalendarView.m
//  GLPeriodCalendar
//
//  Created by ltebean on 15-4-16.
//  Copyright (c) 2015 glow. All rights reserved.
//

#import "GLCalendarView.h"
#import "GLCalendarDayCell.h"
#import "GLCalendarMonthCoverView.h"
#import "GLDateUtils.h"
#import "CMPopTipView.h"

static NSString * const CELL_REUSE_IDENTIFIER = @"DayCell";

#define DEFAULT_PADDING 6;
#define DEFAULT_ROW_HEIGHT 54;

@interface GLCalendarView()<UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate>
@property (nonatomic, readwrite) NSCalendar *calendar;
@property (nonatomic, weak) GLCalendarDateRange *rangeUnderEdit;

@property (nonatomic, strong) UILongPressGestureRecognizer *dragBeginDateGesture;
@property (nonatomic, strong) UILongPressGestureRecognizer *dragEndDateGesture;

@property (nonatomic) BOOL draggingBeginDate;
@property (nonatomic) BOOL draggingEndDate;

@property (nonatomic) CMPopTipView *popTipView;


@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIView *weekDayTitle;
@property (weak, nonatomic) IBOutlet GLCalendarMonthCoverView *monthCoverView;
@property (weak, nonatomic) IBOutlet UIView *magnifierContainer;
@property (weak, nonatomic) IBOutlet UIImageView *maginifierContentView;
@end


@implementation GLCalendarView
{
    BOOL drawPop;
}

@synthesize firstDate = _firstDate;
@synthesize lastDate = _lastDate;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self load];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self load];
    }
    return self;
}

- (void)load
{
    UIView *view = [[[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] lastObject];
    view.frame = self.bounds;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    [self addSubview:view];
    self.popTipView = [[CMPopTipView alloc] initWithMessage:@""];
    UIColor *color = [[UIColor darkGrayColor] colorWithAlphaComponent:0.7];
    self.popTipView.backgroundColor = color;
    drawPop = true;
    [self setup];
}

- (void)setup
{
    
    
    self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;

    self.ranges = [NSMutableArray array];
    
    self.calendar = [GLDateUtils calendar];
    
    self.monthCoverView.hidden = YES;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
//    [self.collectionView registerNib:[UINib nibWithNibName:@"GLCalendarDayCell" bundle:[NSBundle bundleForClass:self.class]] forCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER];
    
    [self.collectionView registerClass:[GLCalendarDayCell class] forCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER];
    
    self.dragBeginDateGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragBeginDate:)];
    self.dragEndDateGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDragEndDate:)];
    
    self.dragBeginDateGesture.delegate = self;
    self.dragEndDateGesture.delegate = self;
    
    self.dragBeginDateGesture.minimumPressDuration = 0.05;
    self.dragEndDateGesture.minimumPressDuration = 0.05;
    
    [self.collectionView addGestureRecognizer:self.dragBeginDateGesture];
    [self.collectionView addGestureRecognizer:self.dragEndDateGesture];
    
    [self addSubview:self.magnifierContainer];
    self.magnifierContainer.hidden = YES;
    
    [self reloadAppearance];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self setupWeekDayTitle];
}

- (void)setupWeekDayTitle
{

    [self.weekDayTitle.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CGFloat width = (CGRectGetWidth(self.bounds) - self.padding * 2) / 7;
    CGFloat centerY = self.weekDayTitle.bounds.size.height / 2;
    NSArray *titles;
    if ([self.delegate respondsToSelector:@selector(weekDayTitlesForCalendarView:)]) {
        titles = [self.delegate weekDayTitlesForCalendarView:self];
    } else {
        self.calendar.locale = [[NSLocale alloc] initWithLocaleIdentifier:self.languageCode];
        titles = self.calendar.shortStandaloneWeekdaySymbols;
    }
    NSInteger firstWeekDayIdx = [self.calendar firstWeekday] - 1;  // Sunday == 1
    if (firstWeekDayIdx > 0) {
        NSArray *post = [titles subarrayWithRange:NSMakeRange(firstWeekDayIdx, 7 - firstWeekDayIdx)];
        NSArray *pre = [titles subarrayWithRange:NSMakeRange(0, firstWeekDayIdx)];
        titles = [post arrayByAddingObjectsFromArray:pre];
    }
    for (int i = 0; i < titles.count; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, width, 20)];
        label.textAlignment = NSTextAlignmentCenter;
        label.attributedText = [[NSAttributedString alloc] initWithString:titles[i] attributes:self.weekDayTitleAttributes];
        label.center = CGPointMake(self.padding + i * width + width / 2, centerY);
        [self.weekDayTitle addSubview:label];
    }
}

# pragma mark - appearance

- (void)reloadAppearance
{
    GLCalendarView *appearance = [[self class] appearance];
    self.padding = appearance.padding ?: DEFAULT_PADDING;
    self.rowHeight = appearance.rowHeight ?: DEFAULT_ROW_HEIGHT;
    self.weekDayTitleAttributes = appearance.weekDayTitleAttributes ?: @{NSFontAttributeName:[UIFont systemFontOfSize:8], NSForegroundColorAttributeName:[UIColor grayColor]};
    self.monthCoverAttributes = appearance.monthCoverAttributes ?: @{NSFontAttributeName:[UIFont systemFontOfSize:30]};
    self.monthCoverView.textAttributes = self.monthCoverAttributes;
}

#pragma mark - public api

- (void)reload
{
    self.monthCoverView.languageCode = self.languageCode;
    [self.monthCoverView updateWithFirstDate:self.firstDate lastDate:self.lastDate calendar:self.calendar rowHeight:self.rowHeight today:[self todayDate]];
    [self.collectionView reloadData];
}

- (void)addRange:(GLCalendarDateRange *)range
{
    [self.ranges addObject:range];
    [self reloadFromBeginDate:range.beginDate toDate:range.endDate];
}

- (void)removeRange:(GLCalendarDateRange *)range
{
    [self.ranges removeObject:range];
    [self reloadFromBeginDate:range.beginDate toDate:range.endDate];
}

- (void)updateRange:(GLCalendarDateRange *)range withBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate
{
    NSDate *beginDateToReload = [[GLDateUtils minForDate:range.beginDate andDate:beginDate] copy];
    NSDate *endDateToReload = [[GLDateUtils maxForDate:range.endDate andDate:endDate] copy];
    range.beginDate = beginDate;
    range.endDate = endDate;
    [self reloadFromBeginDate:beginDateToReload toDate:endDateToReload];
}

- (void)forceFinishEdit
{
    self.rangeUnderEdit.inEdit = NO;
    [self reloadFromBeginDate:self.rangeUnderEdit.beginDate toDate:self.rangeUnderEdit.endDate];
    self.rangeUnderEdit = nil;
}

- (void)scrollToDate:(NSDate *)date animated:(BOOL)animated;
{
    NSInteger item = [GLDateUtils daysBetween:self.firstDate and:date];
    [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:animated];
}

# pragma mark - getter & setter

- (void)setFirstDate:(NSDate *)firstDate
{
    _firstDate = [GLDateUtils weekFirstDate:[GLDateUtils cutDate:firstDate]];
}

- (NSDate *)firstDate
{
    if (!_firstDate) {
        self.firstDate = [GLDateUtils dateByAddingDays:-7 toDate:[self todayDate]];
    }
    return _firstDate;
}

- (void)setLastDate:(NSDate *)lastDate
{
    _lastDate = [GLDateUtils weekLastDate:[GLDateUtils cutDate:lastDate]];
}

- (NSDate *)lastDate
{
    if (!_lastDate) {
        self.lastDate = [GLDateUtils dateByAddingDays:+365 toDate:[self todayDate]];
    }
    return _lastDate;
}

# pragma mark - UICollectionView data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [GLDateUtils daysBetween:self.firstDate and:self.lastDate] + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row >=  [GLDateUtils daysBetween:self.firstDate and:self.lastDate] + 1)
        return nil;

    
    GLCalendarDayCell *cell = (GLCalendarDayCell *)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_REUSE_IDENTIFIER forIndexPath:indexPath];
    
    CELL_POSITION cellPosition;
    ENLARGE_POINT enlargePoint;
    
    NSInteger position = indexPath.item % 7;
    if (position == 0) {
        cellPosition = POSITION_LEFT_EDGE;
    } else if (position == 6) {
        cellPosition = POSITION_RIGHT_EDGE;
    } else {
        cellPosition = POSITION_NORMAL;
    }
    
    NSDate *date = [self dateForCellAtIndexPath:indexPath];
    if (self.draggingBeginDate && [GLDateUtils date:self.rangeUnderEdit.beginDate isSameDayAsDate:date]) {
        enlargePoint = ENLARGE_BEGIN_POINT;
    } else if (self.draggingEndDate && [GLDateUtils date:self.rangeUnderEdit.endDate isSameDayAsDate:date]) {
        enlargePoint = ENLARGE_END_POINT;
    } else {
        enlargePoint = ENLARGE_NONE;
    }
    cell.calendarView = self;
    cell.popTipView = self.popTipView;
    [cell setDate:date range:[self selectedRangeForDate:date] cellPosition:cellPosition enlargePoint:enlargePoint];
    
    return cell;
}

- (void)showPop:(GLCalendarDayCell*)cell
{
    if( drawPop == true && cell.superview != nil )
    {
        [self showCorrentDatePop:self.rangeUnderEdit.beginDate :self.rangeUnderEdit.endDate :cell];
    }
}

- (NSDate *)dateForCellAtIndexPath:(NSIndexPath *)indexPath
{
    return [GLDateUtils dateByAddingDays:indexPath.item toDate:self.firstDate];
}

- (GLCalendarDateRange *)selectedRangeForDate:(NSDate *)date
{
    for (GLCalendarDateRange *range in self.ranges) {
        if ([range containsDate:date]) {
            return range;
        }
    }
    return nil;
}


- (void)showCorrentDatePop:(NSDate*)begindate :(NSDate*)enddate :(UICollectionViewCell*)cell
{
    
    if (cell.superview != nil)
    {
        NSString *message = [self.delegate calenderView:self tipShowByBeginDate:begindate endDate:enddate];
        [self.popTipView setMessage:message];
        [self.popTipView presentPointingAtView:cell inView:cell.superview animated:YES];
    }
}

# pragma mark - UICollectionView delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDate *date = [self dateForCellAtIndexPath:indexPath];
    GLCalendarDateRange *range = [self selectedRangeForDate:date];
    


    // if click in a range
    if (range && range.editable) {
        if (range == self.rangeUnderEdit) {
            return;
        }
        // click a different range
        if (self.rangeUnderEdit && range != self.rangeUnderEdit) {
            [self finishEditRange:self.rangeUnderEdit continueEditing:YES];
        }
        [self beginToEditRange:range];
    } else {
        
        
        if (self.rangeUnderEdit) {
            BOOL canAdd = [self.delegate calenderView:self canAddRangeWithBeginDate:date];
            if (canAdd) {
                [self removeRange:self.rangeUnderEdit];
                [self.popTipView dismissAnimated:false];
                UICollectionViewCell *dateCell =[self.collectionView cellForItemAtIndexPath:indexPath];
                int daysToAdd = 1;
                NSDate *newDate1 = [date dateByAddingTimeInterval:60*60*24*daysToAdd];
                [self showCorrentDatePop:date :newDate1 :dateCell];
                
                GLCalendarDateRange *rangeToAdd = [self.delegate calenderView:self rangeToAddWithBeginDate:date];
                [self addRange:rangeToAdd];
            }
        }
        else
        {
            BOOL canAdd = [self.delegate calenderView:self canAddRangeWithBeginDate:date];
            if (canAdd) {
                UICollectionViewCell *dateCell =[self.collectionView cellForItemAtIndexPath:indexPath];
                int daysToAdd = 1;
                NSDate *newDate1 = [date dateByAddingTimeInterval:60*60*24*daysToAdd];
                [self showCorrentDatePop:date :newDate1 :dateCell];
                GLCalendarDateRange *rangeToAdd = [self.delegate calenderView:self rangeToAddWithBeginDate:date];
                [self addRange:rangeToAdd];
            }
            
        }
    }
}

# pragma mark - UICollectionView layout

- (UIEdgeInsets)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0, self.padding, 0, self.padding); // top, left, bottom, right
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(self.cellWidth, self.rowHeight);
}

- (CGFloat)cellWidth
{
    return (CGRectGetWidth(self.bounds) - self.padding * 2) / 7;
}

# pragma mark - UIScrollView delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.monthCoverView.contentSize = self.collectionView.contentSize;
    self.monthCoverView.hidden = NO;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.monthCoverView.alpha = 1;
        self.collectionView.alpha = 0.3;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // update month cover
    self.monthCoverView.contentOffset = self.collectionView.contentOffset;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset
{
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.monthCoverView.alpha = 0;
        self.collectionView.alpha = 1;
    } completion:^(BOOL finished) {
        self.monthCoverView.hidden = YES;
    }];
}

# pragma mark - Edit range

- (void)initRangUnderEdit: (GLCalendarDateRange *)range
{
    self.rangeUnderEdit = range;
    self.rangeUnderEdit.inEdit = YES;
}

- (void)beginToEditRange:(GLCalendarDateRange *)range
{
    self.rangeUnderEdit = range;
    self.rangeUnderEdit.inEdit = YES;
    [self reloadFromBeginDate:self.rangeUnderEdit.beginDate toDate:self.rangeUnderEdit.endDate];
    [self.delegate calenderView:self beginToEditRange:range];
    
    
}

- (void)finishEditRange:(GLCalendarDateRange *)range continueEditing:(BOOL)continueEditing
{
    self.rangeUnderEdit.inEdit = NO;
    [self reloadFromBeginDate:self.rangeUnderEdit.beginDate toDate:self.rangeUnderEdit.endDate];
    [self.delegate calenderView:self finishEditRange:self.rangeUnderEdit continueEditing:continueEditing];
    self.rangeUnderEdit = nil;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)recognizer
{
    if (!self.rangeUnderEdit) {
        return NO;
    }
    if (recognizer == self.dragBeginDateGesture) {
        CGPoint location = [recognizer locationInView:self.collectionView];
        CGRect rectForBeginDate = [self rectForDate:self.rangeUnderEdit.beginDate];
        rectForBeginDate.origin.x -= self.cellWidth / 2;
        if (CGRectContainsPoint(rectForBeginDate, location)) {
            return YES;
        }
    }
    if (recognizer == self.dragEndDateGesture) {
        CGPoint location = [recognizer locationInView:self.collectionView];
        CGRect rectForEndDate = [self rectForDate:self.rangeUnderEdit.endDate];
        rectForEndDate.origin.x += self.cellWidth / 2;
        if (CGRectContainsPoint(rectForEndDate, location)) {
            return YES;
        }
    }
    return NO;
}

- (void)setPopShowState:(BOOL)show
{
    drawPop = show;
    if(drawPop == false)
    {
        [self.popTipView dismissAnimated:false];
    }
}


- (void)handleDragBeginDate:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self setPopShowState:false];

        self.draggingBeginDate = YES;
        [self reloadCellOnDate:self.rangeUnderEdit.beginDate];
        [self showMagnifierAboveDate:self.rangeUnderEdit.beginDate];
        return;
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        drawPop = true;
        self.draggingBeginDate = NO;
        [self hideMagnifier];
        [self reloadCellOnDate:self.rangeUnderEdit.beginDate];
        return;
    }
    
    CGPoint location = [recognizer locationInView:self.collectionView];
    if (location.y <= self.collectionView.contentOffset.y) {
        return;
    }
    
    NSDate *date = [self dateAtLocation:location];
    
    if ([GLDateUtils date:self.rangeUnderEdit.beginDate isSameDayAsDate:date]) {
        return;
    }
    
    
    if ([self.rangeUnderEdit.endDate compare:date] == NSOrderedAscending) {
        return;
    }
    
    BOOL canUpdate = [self.delegate calenderView:self canUpdateRange:self.rangeUnderEdit toBeginDate:date endDate:self.rangeUnderEdit.endDate];
    
    if (canUpdate) {
        NSDate *originalBeginDate = [self.rangeUnderEdit.beginDate copy];
        self.rangeUnderEdit.beginDate = date;
        if ([originalBeginDate compare:date] == NSOrderedAscending) {
            [self reloadFromBeginDate:originalBeginDate toDate:date];
        } else {
            [self reloadFromBeginDate:date toDate:originalBeginDate];
        }
        [self showMagnifierAboveDate:self.rangeUnderEdit.beginDate];
        [self.delegate calenderView:self didUpdateRange:self.rangeUnderEdit toBeginDate:date endDate:self.rangeUnderEdit.endDate];
    }
}



- (void)handleDragEndDate:(UIPanGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [self setPopShowState:false];
        self.draggingEndDate = YES;
        [self reloadCellOnDate:self.rangeUnderEdit.endDate];
        [self showMagnifierAboveDate:self.rangeUnderEdit.endDate];
        return;
    }
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        [self setPopShowState:true];

        self.draggingEndDate = NO;
        [self hideMagnifier];
        [self reloadCellOnDate:self.rangeUnderEdit.endDate];
        return;
    }

    CGPoint location = [recognizer locationInView:self.collectionView];
    if (location.y <= self.collectionView.contentOffset.y) {
        return;
    }
    
    NSDate *date = [self dateAtLocation:location];

    if ([GLDateUtils date:self.rangeUnderEdit.endDate isSameDayAsDate:date]) {
        return;
    }
    if ([date compare:self.rangeUnderEdit.beginDate] == NSOrderedAscending) {
        return;
    }
    
    BOOL canUpdate = [self.delegate calenderView:self canUpdateRange:self.rangeUnderEdit toBeginDate:self.rangeUnderEdit.beginDate endDate:date];
    
    if (canUpdate) {
        NSDate *originalEndDate = [self.rangeUnderEdit.endDate copy];
        self.rangeUnderEdit.endDate = date;
        if ([originalEndDate compare:date] == NSOrderedAscending) {
            [self reloadFromBeginDate:originalEndDate toDate:date];
        } else {
            [self reloadFromBeginDate:date toDate:originalEndDate];
        }
        [self showMagnifierAboveDate:self.rangeUnderEdit.endDate];
        [self.delegate calenderView:self didUpdateRange:self.rangeUnderEdit toBeginDate:self.rangeUnderEdit.beginDate endDate:date];
    }
}

# pragma mark - maginifier

- (void)showMagnifierAboveDate:(NSDate *)date
{
    if (!self.showMagnifier) {
        return;
    }
    GLCalendarDayCell *cell = (GLCalendarDayCell *)[self collectionView:self.collectionView cellForItemAtIndexPath:[self indexPathForDate:date]];
    CGFloat delta = self.cellWidth / 2;
    if (self.draggingBeginDate) {
        delta = delta;
    } else {
        delta = -delta;
    }
    UIGraphicsBeginImageContextWithOptions(self.maginifierContentView.frame.size, YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextFillRect(context, self.maginifierContentView.bounds);
    CGContextTranslateCTM(context, -cell.center.x + delta, -cell.center.y);
    CGContextTranslateCTM(context, self.maginifierContentView.frame.size.width / 2, self.maginifierContentView.frame.size.height / 2);
    [self.collectionView.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.maginifierContentView.image = image;
    self.magnifierContainer.center = [self convertPoint:CGPointMake(cell.center.x - delta - 58, cell.center.y - 90) fromView:self.collectionView];
    self.magnifierContainer.hidden = NO;
}

- (void)hideMagnifier
{
    if (!self.showMagnifier) {
        return;
    }
    self.magnifierContainer.hidden = YES;
}

- (IBAction)backToTodayButtonPressed:(id)sender
{
    [self scrollToDate:[self todayDate] animated:YES];
}
# pragma mark - helper


- (NSDate*)todayDate
{
    return [NSDate date];
}

static NSDate *today;
- (NSDate *)today
{
    if (!today) {
        today = [GLDateUtils cutDate:[self todayDate]];
    }
    return today;
}

- (NSDate *)dateAtLocation:(CGPoint)location
{
    return [self dateForCellAtIndexPath:[self indexPathAtLocation:location]];
}

- (NSIndexPath *)indexPathAtLocation:(CGPoint)location
{
    NSInteger row = location.y / self.rowHeight;
    CGFloat col = (location.x - self.padding) / self.cellWidth;
    NSInteger item = row * 7 + floorf(col);
    return [NSIndexPath indexPathForItem:item inSection:0];
}

- (CGRect)rectForDate:(NSDate *)date
{
    NSInteger dayDiff = [GLDateUtils daysBetween:self.firstDate and:date];
    NSInteger row = dayDiff / 7;
    NSInteger col = dayDiff % 7;
    return CGRectMake(self.padding + col * self.cellWidth, row * self.rowHeight, self.cellWidth, self.rowHeight);
}


- (void)reloadCellOnDate:(NSDate *)date
{
    [self reloadFromBeginDate:date toDate:date];
}

- (void)reloadFromBeginDate:(NSDate *)beginDate toDate:(NSDate *)endDate
{
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSInteger beginIndex = MAX(0, [GLDateUtils daysBetween:self.firstDate and:beginDate]);
    NSInteger endIndex = MIN([self collectionView:self.collectionView numberOfItemsInSection:0] - 1, [GLDateUtils daysBetween:self.firstDate and:endDate]);
    for (NSInteger i = beginIndex; i <= endIndex; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:0]];
    }
    // prevent crash: too many update animations on one view - limit is 31 in flight at a time
    if (indexPaths.count > 30) {
        [self.collectionView reloadData];
    } else {
        [UIView performWithoutAnimation:^{
            [self.collectionView reloadItemsAtIndexPaths:indexPaths];
        }];
    }
}

- (NSIndexPath *)indexPathForDate:(NSDate *)date
{
    return [NSIndexPath indexPathForItem:[GLDateUtils daysBetween:self.firstDate and:date] inSection:0];
}
@end