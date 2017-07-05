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

#import "UIExtensionsManager.h"
#import "FSUndo.h"
#import "Utility.h"
#import "FSAnnotAttributes.h"
#import "FSAnnotExtent.h"

@interface UndoItem()
@end

@implementation UndoItem

+ (instancetype)itemWithUndo:(UndoBlock)undo redo:(RedoBlock)redo pageIndex:(int)pageIndex
{
    return [[UndoItem alloc] initWithUndo:undo redo:redo pageIndex:pageIndex];
}

+ (instancetype)itemByMergingUndoItemInArray:(NSArray<UndoItem*>*)undoItemArray
{
    NSMutableArray<UndoBlock>* undoArray = [NSMutableArray<UndoBlock> array];
    NSMutableArray<RedoBlock>* redoArray = [NSMutableArray<UndoBlock> array];
    for (UndoItem* undoItem in undoItemArray) {
        [undoArray addObject:undoItem.undo];
        [redoArray addObject:undoItem.redo];
    }
    return [UndoItem itemWithUndo:^(UndoItem* item){
        for (UndoBlock undo in undoArray) {
            undo(item);
        }
    } redo:^(UndoItem* item){
        for (RedoBlock redo in redoArray) {
            redo(item);
        }
    } pageIndex:[undoItemArray objectAtIndex:0].pageIndex];
}

- (instancetype)initWithUndo:(UndoBlock)undo redo:(RedoBlock)redo pageIndex:(int)pageIndex;
{
    if (self = [super init]) {
        self.undo = undo;
        self.redo = redo;
        self.pageIndex = pageIndex;
    }
    return self;
}



@end

@implementation UndoModifyAnnot

+(instancetype)createWithOldAttributes:(FSAnnotAttributes *)oldAttributes newAttributes:(FSAnnotAttributes *)newAttributes pdfViewCtrl:(FSPDFViewCtrl*)pdfViewCtrl page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler
{
    if (oldAttributes && newAttributes && pdfViewCtrl && page && annotHandler) {
        int pageIndex = [page getIndex];
        return [UndoItem itemWithUndo:^(UndoItem* item){
            FSAnnot* annot = [Utility getAnnotByNM:oldAttributes.NM inPage:page];
            CGRect currentPvRect = [pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            [annot applyAttributes:oldAttributes];
            [pdfViewCtrl refresh:CGRectInset(currentPvRect, -30, -30) pageIndex:pageIndex];
            [annotHandler modifyAnnot:annot addUndo:NO];
        } redo:^(UndoItem* item){
            FSAnnot* annot = [Utility getAnnotByNM:newAttributes.NM inPage:page];
            CGRect currentPvRect = [pdfViewCtrl convertPdfRectToPageViewRect:annot.fsrect pageIndex:pageIndex];
            [annot applyAttributes:newAttributes];
            [pdfViewCtrl refresh:CGRectInset(currentPvRect, -30, -30) pageIndex:pageIndex];
            [annotHandler modifyAnnot:annot addUndo:NO];
        } pageIndex:pageIndex];
    }
    return nil;
}

@end

@implementation UndoAddAnnot

+(instancetype)createWithAttributes:(FSAnnotAttributes *)attributes page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler
{
    if (attributes && page && annotHandler) {
        return [UndoItem itemWithUndo:^(UndoItem* item){
            FSAnnot* annot = [Utility getAnnotByNM:attributes.NM inPage:page];
            if (annot) {
                [annotHandler removeAnnot:annot addUndo:NO];
            }
        } redo:^(UndoItem* item){
            FSAnnot* annot = [page addAnnot:attributes.type rect:attributes.rect];
            if (annot) {
                [attributes resetAnnot:annot];
                [annotHandler addAnnot:annot addUndo:NO];
            }
        } pageIndex:[page getIndex]];
    }
    return nil;
}

@end

@implementation UndoDeleteAnnot

+(instancetype)createWithAttributes:(FSAnnotAttributes *)attributes page:(FSPDFPage *)page annotHandler:(id<IAnnotHandler>)annotHandler
{
    if (attributes && page && annotHandler) {
        return [UndoItem itemWithUndo:^(UndoItem* item){
            FSAnnot* annot = [page addAnnot:attributes.type rect:attributes.rect];
            if (annot) {
                [attributes resetAnnot:annot];
                [annotHandler addAnnot:annot addUndo:NO];
            }
        } redo:^(UndoItem* item){
            FSAnnot* annot = [Utility getAnnotByNM:attributes.NM inPage:page];
            if (annot) {
                [annotHandler removeAnnot:annot addUndo:NO];
            }
        } pageIndex:[page getIndex]];
    }
    return nil;
}

@end

@implementation FSUndo

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.undoItems = [NSMutableArray<UndoItem*> array];
        self.redoItems = [NSMutableArray<UndoItem*> array];
        self.listeners = [NSMutableArray<IFSUndoEventListener> array];
    }
    return self;
}

-(void)addUndoItem:(UndoItem*)undoItem
{
    [self.undoItems addObject:undoItem];
    [self.redoItems removeAllObjects];
    for (id<IFSUndoEventListener> listener in self.listeners) {
        [listener onUndoChanged];
    }
}

-(BOOL)canUndo
{
    return self.undoItems.count > 0;
}

-(BOOL)canRedo
{
    return self.redoItems.count > 0;
}

-(void)undo
{
    if (self.undoItems.count == 0) return;
    UndoItem* item = [self.undoItems objectAtIndex:self.undoItems.count - 1];
    if (item.undo) {
        item.undo(item);
    }
    [self.redoItems addObject:item];
    [self.undoItems removeObject:item];
    for (id<IFSUndoEventListener> listener in self.listeners) {
        [listener onUndoChanged];
    }
}

-(void)redo
{
    if (self.redoItems.count == 0) return;
    UndoItem* item = [self.redoItems objectAtIndex:self.redoItems.count -1];
    if (item.redo) {
        item.redo(item);
    }
    [self.undoItems addObject:item];
    [self.redoItems removeObject:item];
    for (id<IFSUndoEventListener> listener in self.listeners) {
        [listener onUndoChanged];
    }
}

-(void)clearUndoRedo
{
    [self.undoItems removeAllObjects];
    [self.redoItems removeAllObjects];
    for (id<IFSUndoEventListener> listener in self.listeners) {
        [listener onUndoChanged];
    }
}

-(void)registerUndoEventListener:(id<IFSUndoEventListener>)listener
{
    [self.listeners addObject:listener];
}

@end
