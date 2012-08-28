//
//  WizPadTreeTableCell.m
//  Wiz
//
//  Created by wiz on 12-8-16.
//
//

#import "WizPadTreeTableCell.h"

#define WizTreeMaxDeep 7

@interface WizPadTreeTableCell ()

@end

@implementation WizPadTreeTableCell
@synthesize strTreeNodeKey;
@synthesize titleLabel;
@synthesize expandedButton;
@synthesize detailLabel;
@synthesize delegate;
- (void) dealloc
{
    delegate = nil;
    [expandedButton release];
    [titleLabel release];
    [detailLabel release];
    [super dealloc];
}

- (void) showExpandedIndicatory
{
    [self bringSubviewToFront:expandedButton];
    [self.delegate showExpandedIndicatory:self];
}

- (void) didExpanded
{
    [self.delegate onExpandedNodeByKey:self.strTreeNodeKey];
    [self showExpandedIndicatory];

}
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        expandedButton  = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
        [self.contentView addSubview:expandedButton];
        expandedButton.backgroundColor = [UIColor whiteColor];
        [expandedButton addTarget:self action:@selector(didExpanded) forControlEvents:UIControlEventTouchUpInside];
        expandedButton.backgroundColor = [UIColor clearColor];
        
        titleLabel = [[UILabel alloc] init];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.font = [UIFont systemFontOfSize:16];
        
        [self.contentView addSubview:titleLabel];
        detailLabel = [[UILabel alloc] init];
        detailLabel.font = [UIFont systemFontOfSize:13];
        detailLabel.textColor = [UIColor lightGrayColor];
        [self.contentView addSubview:detailLabel];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        
        detailLabel.backgroundColor = [UIColor clearColor];
        
        UIView* selectedView = [[UIView alloc] init];
        selectedView.backgroundColor = [UIColor brownColor];
        self.selectedBackgroundView = selectedView;
        [selectedView release];


    }
    return self;
}

- (void) drawRect:(CGRect)rect
{
    detailLabel.text = nil;
    NSInteger treeNodeDeep = [self.delegate treeNodeDeep:self.strTreeNodeKey];

    CGFloat indentationLevel = 20* ((treeNodeDeep > WizTreeMaxDeep ? WizTreeMaxDeep : treeNodeDeep) -1);
    NSLog(@"treeDeep is %f",indentationLevel);
    static float  buttonWith = 44;
    expandedButton.frame = CGRectMake(indentationLevel, 0.0, buttonWith, buttonWith);
    titleLabel.frame = CGRectMake(buttonWith+indentationLevel, 0.0, self.frame.size.width - buttonWith - indentationLevel, 25);
    detailLabel.frame = CGRectMake(buttonWith+indentationLevel, 25, self.frame.size.width - buttonWith - indentationLevel, 15);
    [self.delegate decorateTreeCell:self];
    [self showExpandedIndicatory];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    if (selected) {
        static UIImageView* selectedView = nil;
        if (nil == selectedView) {
            selectedView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"treeCellSelected"]] retain];
        }
        self.backgroundView = selectedView;
        titleLabel.textColor = [UIColor lightTextColor];
        
    }
    else
    {
        self.backgroundView = nil;
        titleLabel.textColor = [UIColor blackColor];
    }
}
@end
