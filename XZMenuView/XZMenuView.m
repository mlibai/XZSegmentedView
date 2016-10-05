//
//  XZMenuView.m
//  Demo
//
//  Created by M. X. Z. on 2016/10/5.
//  Copyright © 2016年 J. W. Z. All rights reserved.
//

#import "XZMenuView.h"

NSString *const kPDMenuIdentifier = @"kPDMenuIdentifier";

@interface _XZMenuViewCell : UICollectionViewCell

@property (nonatomic, strong) UIView<XZMenuItemView> *reusingView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@interface XZMenuView () <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) UICollectionView *menuItemsView;

@end

@implementation XZMenuView

- (instancetype)initWithFrame:(CGRect)frame {
    if (CGRectIsEmpty(frame)) {
        frame.size.width = (frame.size.width ?: CGRectGetWidth([UIScreen mainScreen].bounds));
        frame.size.height = (frame.size.height ?: 44.0);
    }
    self = [super initWithFrame:frame];
    if (self != nil) {
        [self menuItemsView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect menuBounds = self.bounds;
    CGFloat menuHeight = CGRectGetHeight(menuBounds);
    CGFloat menuWidth = CGRectGetWidth(menuBounds);
    CGRect leftFrame = CGRectZero, rightFrame = CGRectZero;
    if (_leftView != nil) {
        CGRect frame    = _leftView.frame;
        CGFloat height  = CGRectGetHeight(frame);
        CGFloat width   = CGRectGetWidth(frame);
        if (height > menuHeight) {
            width = menuHeight * width / height;
            height = menuHeight;
        }
        leftFrame       = CGRectMake(0, (menuHeight - height) / 2.0, width, height);
        _leftView.frame = leftFrame;
    }
    
    if (_rightView != nil) {
        CGRect frame     = _rightView.frame;
        CGFloat height   = CGRectGetHeight(frame);
        CGFloat width    = CGRectGetWidth(frame);
        if (height > menuHeight) {
            width = menuHeight * width / height;
            height = menuHeight;
        }
        rightFrame       = CGRectMake(menuWidth - width, (menuHeight - height) / 2.0, width, height);
        _rightView.frame = rightFrame;
    }
    
    NSUInteger itemsCount = [_dataSource numberOfItemsInMenuView:self];
    if (itemsCount > 0) {
        CGRect centerFrame = CGRectMake(CGRectGetMaxX(leftFrame), 0, CGRectGetWidth(menuBounds) - CGRectGetWidth(leftFrame) - CGRectGetWidth(rightFrame), menuHeight);
        CGFloat minimumWidth = 49.0;
        CGFloat totalWith = menuWidth - CGRectGetWidth(leftFrame) - CGRectGetWidth(rightFrame);
        minimumWidth = (totalWith / floor(totalWith / minimumWidth));
        [(UICollectionViewFlowLayout *)self.menuItemsView.collectionViewLayout setItemSize:CGSizeMake(minimumWidth, menuHeight)];
        self.menuItemsView.frame = centerFrame;
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:selectedIndex inSection:0];
    [self.menuItemsView selectItemAtIndexPath:indexPath animated:animated scrollPosition:(UICollectionViewScrollPositionCenteredHorizontally)];
}

- (void)reloadData {
    [self.menuItemsView reloadData];
}

- (void)insertItemAtIndex:(NSInteger)index {
    [self.menuItemsView insertItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
}

- (void)removeItemAtIndex:(NSInteger)index {
    [self.menuItemsView deleteItemsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]]];
}

- (UIView *)viewForItemAtIndex:(NSInteger)index {
    _XZMenuViewCell *cell = (_XZMenuViewCell *)[self.menuItemsView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return [cell reusingView];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([_dataSource respondsToSelector:@selector(numberOfItemsInMenuView:)]) {
        return [_dataSource numberOfItemsInMenuView:self];
    }
    return 0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    _XZMenuViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kPDMenuIdentifier forIndexPath:indexPath];
    
    if ([_dataSource respondsToSelector:@selector(menuView:viewForItemAtIndex:reusingView:)]) {
        cell.reusingView = [_dataSource menuView:self viewForItemAtIndex:indexPath.item reusingView:cell.reusingView];
    } else if ([_dataSource respondsToSelector:@selector(menuView:titleForMenuItemAtIndex:)]) {
        NSString *title = [_dataSource menuView:self titleForMenuItemAtIndex:indexPath.item];
        if (title != nil) {
            cell.titleLabel.text = title;
        }
    }
    
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(menuView:didSelectItemAtIndex:)]) {
        [_delegate menuView:self didSelectItemAtIndex:indexPath.item];
    }
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(menuView:widthForMenuItemAtIndex:)]) {
        return CGSizeMake([_delegate menuView:self widthForMenuItemAtIndex:indexPath.item], CGRectGetHeight(collectionView.bounds));
    }
    return CGSizeMake(_minimumItemWidth, CGRectGetHeight(collectionView.bounds));
}

#pragma mark - 属性

- (UICollectionView *)menuItemsView {
    if (_menuItemsView != nil) {
        return _menuItemsView;
    }
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    flowLayout.minimumLineSpacing = 0;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.itemSize = CGSizeMake([self minimumItemWidth], CGRectGetHeight(self.bounds));
    _menuItemsView = [[UICollectionView alloc] initWithFrame:self.bounds collectionViewLayout:flowLayout];
    _menuItemsView.backgroundColor = [UIColor clearColor];
    if ([_menuItemsView respondsToSelector:@selector(setPrefetchingEnabled:)]) {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < 80000
        [_menuItemsView setValue:@(NO) forKey:@"prefetchingEnabled"];  // iOS 10 兼容，关闭预加载，避免选中的cell在边缘时，滚动会丢失选中的问题
#else
        _menuItemsView.prefetchingEnabled = NO;
#endif
    }
    _menuItemsView.allowsMultipleSelection        = NO;
    _menuItemsView.delegate                       = self;
    _menuItemsView.dataSource                     = self;
    _menuItemsView.clipsToBounds                  = YES;
    _menuItemsView.showsHorizontalScrollIndicator = NO;
    _menuItemsView.showsHorizontalScrollIndicator = NO;
    _menuItemsView.alwaysBounceVertical           = NO;
    _menuItemsView.alwaysBounceHorizontal         = YES;
    [_menuItemsView registerClass:[_XZMenuViewCell class] forCellWithReuseIdentifier:kPDMenuIdentifier];
    [self addSubview:_menuItemsView];
    [self setNeedsLayout];
    return _menuItemsView;
}

- (void)setLeftView:(UIView *)leftView {
    if (_leftView != leftView) {
        [_leftView removeFromSuperview];
        _leftView = leftView;
        if (_leftView != nil) {
            _leftView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            CGRect frame = _leftView.frame;
            frame.origin.x = -frame.size.width;
            frame.origin.y = (CGRectGetHeight(self.bounds) - CGRectGetHeight(frame)) * 0.5;
            _leftView.frame = frame;
            [self addSubview:_leftView];
            [self setNeedsLayout];
        }
    }
}

- (void)setRightView:(UIView *)rightView {
    if (_rightView != rightView) {
        [_rightView removeFromSuperview];
        _rightView = rightView;
        if (_rightView != nil) {
            _rightView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
            CGRect frame   = _rightView.frame;
            CGRect bounds = self.bounds;
            frame.origin.x = CGRectGetMaxX(bounds) + CGRectGetWidth(frame);
            frame.origin.y = (CGRectGetHeight(self.bounds) - CGRectGetHeight(frame)) * 0.5;
            _rightView.frame = frame;
            [self addSubview:_rightView];
            [self setNeedsLayout];
        }
    }
}

- (NSInteger)selectedIndex {
    return [self.menuItemsView indexPathsForSelectedItems].firstObject.item;
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animated:NO];
}

@synthesize minimumItemWidth = _minimumItemWidth;

- (CGFloat)minimumItemWidth {
    if (_minimumItemWidth > 0) {
        return _minimumItemWidth;
    }
    _minimumItemWidth = 49.0;
    return _minimumItemWidth;
}

- (void)setMinimumItemWidth:(CGFloat)minimumItemWidth {
    if (_minimumItemWidth != minimumItemWidth) {
        _minimumItemWidth = minimumItemWidth;
        if (_menuItemsView != nil) {
            CGFloat minimumWidth = _minimumItemWidth;
            CGFloat totalWith = CGRectGetWidth([UIScreen mainScreen].bounds) - 8.0 * 2 - 38.0;
            minimumWidth = (totalWith / floor(totalWith / minimumWidth));
            UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)_menuItemsView.collectionViewLayout;
            flowLayout.itemSize = CGSizeMake(minimumWidth, CGRectGetHeight(_menuItemsView.frame));
            [_menuItemsView reloadData];
        }
    }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end









@implementation _XZMenuViewCell

- (void)setReusingView:(UIView<XZMenuItemView> *)reusingView {
    if (_reusingView != reusingView) {
        [_reusingView removeFromSuperview];
        _reusingView = reusingView;
        if (_reusingView != nil) {
            _reusingView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
            CGSize viewSize = _reusingView.frame.size;
            CGSize cellSize = self.contentView.bounds.size;
            _reusingView.frame = CGRectMake((cellSize.width - viewSize.width) * 0.5, (cellSize.height - viewSize.height) * 0.5, viewSize.width, viewSize.height);
            [self.contentView addSubview:_reusingView];
            if ([_reusingView respondsToSelector:@selector(setHighlighted:)]) {
                [_reusingView setHighlighted:[self isHighlighted]];
            }
            if ([_reusingView respondsToSelector:@selector(setSelected:)]) {
                [_reusingView setSelected:[self isSelected]];
            }
        }
    }
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if ([_reusingView respondsToSelector:@selector(setSelected:)]) {
        [_reusingView setSelected:selected];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if ([_reusingView respondsToSelector:@selector(setHighlighted:)]) {
        [_reusingView setHighlighted:highlighted];
    }
}

@synthesize titleLabel = _titleLabel;

- (UILabel *)titleLabel {
    if (_titleLabel != nil) {
        return _titleLabel;
    }
    [self setTitleLabel:[[UILabel alloc] init]];
    return _titleLabel;
}

- (void)setTitleLabel:(UILabel *)titleLabel {
    if (_titleLabel != titleLabel) {
        [_titleLabel removeFromSuperview];
        _titleLabel = titleLabel;
        if (_titleLabel != nil) {
            _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
            [self.contentView insertSubview:_titleLabel atIndex:0];
            
            NSLayoutConstraint *const1 = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:(NSLayoutAttributeCenterX) relatedBy:(NSLayoutRelationEqual) toItem:self.contentView attribute:(NSLayoutAttributeCenterX) multiplier:1.0 constant:0];
            NSLayoutConstraint *const2 = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:(NSLayoutAttributeCenterY) relatedBy:(NSLayoutRelationEqual) toItem:self.contentView attribute:(NSLayoutAttributeCenterY) multiplier:1.0 constant:0];
            [self.contentView addConstraint:const1];
            [self.contentView addConstraint:const2];
        }
    }
}

@end
