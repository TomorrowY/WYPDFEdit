/**
 * Copyright (C) 2003-2017, Foxit Software Inc..
 * All Rights Reserved.
 *
 * http://www.foxitsoftware.com
 *
 * The following code is copyrighted and is the proprietary of Foxit Software Inc.. It is not allowed to
 * distribute any parts of Foxit Mobile PDF SDK to third party or public without permission unless an agreement
 * is signed between Foxit Software Inc. and customers to explicitly grant customers permissions.
 * Review legal.txt for additional license and legal information.
 */

#import <FoxitRDK/FSPDFObjC.h>
#import <UIKit/UIKit.h>
#import "Utility.h"
#import "Const.h"
#import "FSAnnotExtent.h"


NSDate* convertFSDateTime2NSDate(FSDateTime *time)
{
    if ([time getYear] > 10000 || [time getYear] == 0 ||
        [time getMonth] > 12 || [time getMonth] == 0 ||
        [time getDay] > 31 || [time getDay] == 0 ||
        [time getHour] > 24 ||
        [time getMinute] > 60 ||
        [time getSecond] > 60)
    {
        return nil;
    }
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setYear:[time getYear]];
    [comps setMonth:[time getMonth]];
    [comps setDay:[time getDay]];
    [comps setHour:[time getHour]];
    [comps setMinute:[time getMinute]];
    [comps setSecond:[time getSecond]];
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDate *date = [gregorian dateFromComponents:comps];
            return date;
}

FSDateTime* convert2FSDateTime(NSDate* date)
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit ;
    NSDateComponents *comps = [gregorian components:unitFlags fromDate:date];
    FSDateTime *time = [[FSDateTime alloc] init];
    time.year = [comps year];
    time.month = [comps month];
    time.day = [comps day];
    time.hour = [comps hour];
    time.minute = [comps minute];
    time.second = [comps second];
    time.UTHourOffset = 0;
    time.UTMinuteOffset = 0;
        return time;
}

FSRectF* convertToFSRect(FSPointF *p1, FSPointF *p2)
{
    FSRectF *rect = [[FSRectF alloc] init];
    rect.left = MIN([p1 getX], [p2 getX]);
    rect.right = MAX([p1 getX], [p2 getX]);
    rect.top = MAX([p1 getY], [p2 getY]);
    rect.bottom = MIN([p1 getY], [p2 getY]);
    return rect;
}

@implementation FSAnnot(useProperties)

-(int)pageIndex
{
    return [[self getPage] getIndex];
}

-(enum FS_ANNOTTYPE)type
{
    return [self getType];
}

-(FSRectF*)fsrect
{
    return [self getRect];
}

-(void)setFsrect:(FSRectF *)fsrect
{
    [self move:fsrect];
}

-(unsigned int)color
{
    if (self.type == e_annotFreeText) {
        FSFreeText* annot = (FSFreeText*)self;
        FSDefaultAppearance* ap = [annot getDefaultAppearance];
        return ap.textColor;
    } else {
        return [self getBorderColor];
    }
}

-(void)setColor:(unsigned int)color
{
    if (self.type == e_annotFreeText) {
        FSFreeText* annot = (FSFreeText*)self;
        FSDefaultAppearance* ap = [annot getDefaultAppearance];
        ap.textColor = color;
        [annot setDefaultAppearance:ap];
    }
    else {
        [self setBorderColor:color];
    }
}

-(float)lineWidth
{
    return [[self getBorderInfo] getWidth];
}
-(void)setLineWidth:(float)lineWidth
{
    FSBorderInfo* borderInfo = [[FSBorderInfo alloc] init];
    [borderInfo setStyle:e_borderStyleSolid];
    [borderInfo setWidth:lineWidth];
    [self setBorderInfo:borderInfo];
    }
-(int)flags
{
    return [self getFlags];
}

-(NSString*)subject
{
    if(![self isMarkup]) return nil;
    return [(FSMarkup*)self getSubject];
}

-(void)setSubject:(NSString *)subject
{
    if(![self isMarkup]) return;
    return [(FSMarkup*)self setSubject:subject];
}

-(NSString*)NM
{
    return [self getUniqueID];
}
-(void)setNM:(NSString *)NM
{
    [self setUniqueID:NM];
}
-(NSString *)replyTo
{
    if (e_annotNote != self.type) {
        return nil;
    }
    
    FSMarkup* markup = [(FSNote*)self getReplyTo];
    if(!markup)
        return nil;
    return markup.NM;
}
-(NSString*)author
{
    if(![self isMarkup]) return nil;
    FSMarkup* mk = (FSMarkup*)self;
    return [mk getTitle];
}
-(void)setAuthor:(NSString *)author
{
    FSMarkup* mk = (FSMarkup*)self;
    return [mk setTitle:author];
}
-(NSString*)contents
{
    return [self getContent];
}

-(void)setContents:(NSString*)contents
{
    [self setContent:contents];
}

-(NSDate*)modifiedDate
{
    FSDateTime* dt = [self getModifiedDateTime];
    return dt ? convertFSDateTime2NSDate(dt) : nil;
}
-(void)setModifiedDate:(NSDate *)modifiedDate
{
    if (!modifiedDate) {
        return;
    }
    FSDateTime* dt = convert2FSDateTime(modifiedDate);
    [self setModifiedDateTime:dt];
}
-(NSDate*)createDate
{
    if(![self isMarkup]) return nil;
    FSMarkup* mk = (FSMarkup*)self;
    FSDateTime* dt = [mk getCreationDateTime];
    return dt ? convertFSDateTime2NSDate(dt) : nil;
}
-(void)setCreateDate:(NSDate *)createDate
{
    if(!createDate || ![self isMarkup]) return;
    FSMarkup* mk = (FSMarkup*)self;
    FSDateTime* dt = convert2FSDateTime(createDate);
    [mk setCreationDateTime:dt];
}
-(NSString*)intent
{
    if(![self isMarkup]) return nil;
    FSMarkup* mk = (FSMarkup*)self;
    return [mk getIntent];
}
-(void)setIntent:(NSString *)intent
{
    if(![self isMarkup]) return;
    FSMarkup* mk = (FSMarkup*)self;
    return [mk setIntent:intent];
}
-(NSString*)selectedText
{
    FSPDFPage* _fspage = [self getPage];
    FSPDFTextSelect* textPage = nil;
    BOOL parseSuccess = YES;
    if(![_fspage isParsed])
    {
        enum FS_PROGRESSSTATE state = [_fspage startParse:e_parsePageTextOnly pause:nil isReparse:NO];
        if (e_progressError == state)
        {
            parseSuccess = NO;
        }
        else if (e_progressToBeContinued == state)
        {
            while (e_progressToBeContinued == state)
            {
                state = [_fspage continueParse];
            }
            if (e_progressFinished != state)
            {
                parseSuccess = NO;
            }
        }
    }
    if (parseSuccess)
    {
        textPage = [FSPDFTextSelect create:_fspage];
    }
    
    NSString* selectedText = @"";
    if (textPage)
    {
        NSArray *array = self.quads;
        for (int i = 0; i < array.count; i++)
        {
            FSQuadPoints *arrayQuad = [array objectAtIndex:i];
            FSRectF *rect = convertToFSRect(arrayQuad.getFirst, arrayQuad.getFourth);
            NSString *tmp = [textPage getTextInRect:rect];
            if (tmp) {
                selectedText = [selectedText stringByAppendingString:tmp];
            }
        }
    }
    return selectedText;
}
-(NSArray*)quads
{
    NSMutableArray* array = [[NSMutableArray alloc] init];
    if(e_annotHighlight != [self getType] && e_annotUnderline != [self getType] && e_annotStrikeOut != [self getType] && e_annotSquiggly != [self getType] && e_annotLink != [self getType]) return nil;
    
    int count = [(id)self getQuadPointsCount];
    for (int i  = 0; i < count; i++) {
        FSQuadPoints *quadPoint = [(id)self getQuadPoints:i];
        [array addObject:quadPoint];
    }
    return array;
}
-(void)setQuads:(NSArray *)quads
{
    if (nil == quads) return;
    
    if(e_annotHighlight != [self getType] && e_annotUnderline != [self getType] && e_annotStrikeOut != [self getType] && e_annotSquiggly != [self getType] && e_annotLink != [self getType]) return;
    
    [(FSTextMarkup*)self setQuadPoints:quads];
}

-(BOOL)canReply
{
    if(![self isMarkup]) {
        return NO;
    }
    if (self.type == e_annotFreeText || self.type == e_annotFileAttachment) {
        return NO;
    }
    if (![self canModify]) {
        return NO;
    }
    return YES;
}

-(BOOL)canModify
{
    return  [Utility canAddAnnotToDocument:[[self getPage] getDocument]];
}

-(BOOL)canCopyText
{
    return [Utility canCopyTextInDocument:[[self getPage] getDocument]];
}

-(float)opacity
{
    if(![self isMarkup]) return 1.0;
    FSMarkup* mk = (FSMarkup*)self;
    return [mk getOpacity];
}

-(void)setOpacity:(float)opacity
{
    if(![self isMarkup]) return;
    FSMarkup* mk = (FSMarkup*)self;
    [mk setOpacity:opacity];
}

-(void)setIcon:(int)icon
{
    NSString* iconName = [Utility getIconNameWithIconType:icon annotType:self.type];
    if (iconName) {
        [(id)self setIconName:iconName];
    }
}

-(int)icon
{
    if ([self respondsToSelector:@selector(getIconName)]) {
        return [Utility getIconTypeWithIconName:[(id)self getIconName] annotType:self.type];
    }
    return FPDF_ICONTYPE_UNKNOWN;
}

- (void)applyAttributes:(FSAnnotAttributes*)attributes
{
    [attributes resetAnnot:self];
}

@end

