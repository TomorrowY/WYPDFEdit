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

#import <UIKit/UIKit.h>
#import "AnnotationItem.h"

@implementation AnnotationItem



-(void)addCurrentlevel:(NSNumber *)object{
    
    _currentlevel=[object intValue];
    
}

-(void)setReplytoauthor:(NSString *)replytoauthor{
    if (_replytoauthor != replytoauthor) {
                _replytoauthor = [replytoauthor copy];
    }
}

-(void)setSecondLevel:(NSNumber*)object{
    
    _isSecondLevel=[object boolValue];
}

-(void)setcurrentlevelshow:(NSNumber*)object{
    
    _currentlevelshow=[object boolValue];
    
}

-(void)setAnnotationSection:(NSNumber*)object{
    
    _annosection=[object intValue];
    
}

@end


@implementation AnnotationButton


@end

