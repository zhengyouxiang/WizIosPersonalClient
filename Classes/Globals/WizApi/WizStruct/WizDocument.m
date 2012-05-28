//
//  WizDocument.m
//  Wiz
//
//  Created by 朝 董 on 12-4-23.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "WizDocument.h"
#import "WizGlobals.h"
#import "NSDate-Utilities.h"
#import "WizDbManager.h"
#import "WizFileManager.h"
#import "WizNotification.h"
#import "WizSyncManager.h"
#import "TagsListTreeControllerNew.h"
#import "WizSettings.h"

BOOL isReverseMask(NSInteger mask)
{
    if (mask %2 == 0) {
        return YES;
    }
    return NO;
}

@implementation WizDocument
@synthesize fileType;
@synthesize type;
@synthesize location;
@synthesize url;
@synthesize dateCreated;
@synthesize dateModified;
@synthesize tagGuids;
@synthesize dataMd5;
@synthesize protected_;
@synthesize serverChanged;
@dynamic  localChanged;
@synthesize attachmentCount;

- (WizEditDocumentType) localChanged
{
    return localChanged;
}
- (void) setLocalChanged:(WizEditDocumentType)localChanged_
{
    if (localChanged == WizEditDocumentTypeAllChanged && localChanged_ == WizEditDocumentTypeInfoChanged) {
        return;
    }
    localChanged = localChanged_;
}
- (void) dealloc
{
    [fileType release];
    [type release];
    [location release];
    [url release];
    [dateCreated release];
    [dateModified release];
    [tagGuids release];
    [dataMd5 release];
    [super dealloc];
}
- (NSComparisonResult) compareCreateDate:(WizDocument*)doc
{
    if (self.dateCreated == nil || doc.dateCreated == nil) {
        return -1;
    }
    return [self.dateCreated compare:doc.dateCreated];
}
- (NSComparisonResult) compareModifiedDate:(WizDocument *)doc
{
    if (self.dateModified == nil || nil == doc.dateModified) {
        return -1;
    }
    return [self.dateModified compare:doc.dateModified];
}
- (NSComparisonResult) compareWithFirstLetter:(WizDocument *)doc
{
    return [[WizGlobals pinyinFirstLetter:self.title] compare:[WizGlobals pinyinFirstLetter:doc.title]];
}

- (BOOL) isExistMobileViewFile
{
    return [[WizFileManager shareManager] fileExistsAtPath:[self documentMobileFile]];
}
- (BOOL) isExistAbstractFile
{
    return [[WizFileManager shareManager] fileExistsAtPath:[self documentAbstractFile]];
}
- (BOOL) isExistIndexFile
{
    BOOL ret = [[WizFileManager shareManager] fileExistsAtPath:[self documentIndexFile]];
    return ret;
}

- (BOOL) isEdited
{
    return YES;
}

- (NSString*) localDataMd5
{
    NSString* zipPath = [[WizFileManager shareManager] createZipByGuid:self.guid];
    NSString* fileMd5 = [WizGlobals fileMD5:zipPath];
    [[WizFileManager shareManager] deleteFile:zipPath];
    return fileMd5;
}

- (BOOL) isNewWebnote
{
    NSString* content = [NSString stringWithContentsOfFile:[self documentIndexFile] usedEncoding:nil error:nil];
    NSRange range = [content rangeOfString:@"<title>Web Note</title>"];
    if (range.location == NSNotFound) {
        return NO;
    }
    return YES;
}
- (NSString*) documentIndexFilesPath
{
    WizFileManager* share = [WizFileManager shareManager];
    return [share documentIndexFilesPath:self.guid];
}
- (NSString*) documentIndexFile
{
	WizFileManager* share = [WizFileManager shareManager];
    return [share documentIndexFile:self.guid];
}
- (NSString*) documentMobileFile
{
    WizFileManager* share = [WizFileManager shareManager];
    return [share documentMobileFile:self.guid];
}
- (NSString*) documentAbstractFile
{
    WizFileManager* share = [WizFileManager shareManager];
    return [share documentAbstractFile:self.guid];
}
- (NSString*) documentFullFile
{
    WizFileManager* share = [WizFileManager shareManager];
    return [share documentFullFile:self.guid];
}

- (NSString*) documentWillLoadFile
{
    NSString* documentIndexFile = [self documentIndexFile];
    NSString* documentMobileFile = [self documentMobileFile];
    if ([[WizSettings defaultSettings] isMoblieView]) {
        if ([[WizFileManager defaultManager] fileExistsAtPath:documentMobileFile]) {
            return documentMobileFile;
        }
    }
    return documentIndexFile;
}
//
- (NSArray*) tagDatas
{
    if (self.tagGuids ==nil || [self.tagGuids isBlock]) {
        return nil;
    }
    NSArray* tagGuidArray = [tagGuids componentsSeparatedByString:@"*"];
    NSMutableArray* ret = [NSMutableArray array];
    for(NSString* eachGuid in tagGuidArray)
    {
        if (eachGuid == nil || [eachGuid isEqualToString:@""]) {
            continue;
        }
        WizTag* tag = [WizTag tagFromDb:eachGuid];
        if (tag == nil) {
            continue;
        }
        
        [ret addObject:tag];
    }
    return ret;
}
//
+ (NSArray*) recentDocuments
{
    WizDbManager* share = [WizDbManager shareDbManager];
    return [share recentDocuments];
}
+ (NSArray*) documentsByTag: (NSString*)tagGUID
{
    WizDbManager* share = [WizDbManager shareDbManager];
    return [share documentsByTag:tagGUID];
}
+ (NSArray*) documentsByKey: (NSString*)keywords
{
    WizDbManager* share = [WizDbManager shareDbManager];
    return [share documentsByKey:keywords];
}
+ (NSArray*) documentsByLocation: (NSString*)parentLocation
{
    WizDbManager* share = [WizDbManager shareDbManager];
    return [share documentsByLocation:parentLocation];
}
+ (NSArray*) documentForUpload
{
    WizDbManager* share = [WizDbManager shareDbManager];
    return [share documentForUpload];
}
+ (WizDocument*) documentFromDb:(NSString *)_guid
{
    WizDbManager* share = [WizDbManager shareDbManager];
    return [share documentFromGUID:_guid];
}
//
+ (void) deleteDocument:(WizDocument*)document
{
    WizFileManager* fileManager = [WizFileManager shareManager];
    [fileManager removeObjectPath:document.guid];
    WizDbManager* db = [WizDbManager shareDbManager];
    [db deleteDocument:document.guid];
    [WizNotificationCenter postDeleteDocumentMassage:document];
}
//

- (NSArray*) attachments
{
    return [[WizDbManager shareDbManager] attachmentsByDocumentGUID:self.guid];
}

- (BOOL) addFileToIndexFiles:(NSString*)sourcePath
{
    NSString* fileName = [sourcePath fileName];
    NSString* indexFilesPath = [self documentIndexFilesPath];
    NSString* toPath = [indexFilesPath stringByAppendingPathComponent:fileName];
    if ([[WizFileManager shareManager] fileExistsAtPath:toPath]) {
        return YES;
    }
    if (![[WizFileManager shareManager] moveItemAtPath:sourcePath toPath:toPath error:nil]) {
        return NO;
    }
    return YES;
}
- (BOOL) saveInfo
{
    if (self.guid == nil || [self.guid isBlock]) {
        self.guid = [WizGlobals genGUID];
    }
    NSMutableDictionary* doc = [NSMutableDictionary dictionaryWithCapacity:14];
    [doc setObject:self.guid forKey:DataTypeUpdateDocumentGUID];
    [doc setObject:[NSNumber numberWithBool:self.serverChanged] forKey:DataTypeUpdateDocumentServerChanged];
    [doc setObject:[NSNumber numberWithInt:self.localChanged] forKey:DataTypeUpdateDocumentLocalchanged];
    [doc setObject:[NSNumber numberWithBool:self.protected_] forKey:DataTypeUpdateDocumentProtected];
    [doc setObject:[NSNumber numberWithInt:self.attachmentCount] forKey:DataTypeUpdateDocumentAttachmentCount];
    if (nil == self.type)
    {
        self.type = @"note";
    }
    [doc setObject:self.type forKey:DataTypeUpdateDocumentType];
    if (nil == self.url) {
        self.url = @"";
    }
    [doc setObject:self.url forKey:DataTypeUpdateDocumentUrl];
    if (nil == self.location || [self.location isBlock]) {
        self.location = @"/My Notes/";
    }
    [doc setObject:self.location forKey:DataTypeUpdateDocumentLocation];
    if (nil == self.title || [self.title isBlock]) {
        self.title = WizStrNoTitle;
    }
    [doc setObject:self.title forKey:DataTypeUpdateDocumentTitle];
    if (nil == self.tagGuids) {
        self.tagGuids = @"";
    }
    [doc setObject:self.tagGuids forKey:DataTypeUpdateDocumentTagGuids];
    if (nil == self.fileType) {
        self.fileType = @"";
    }
    [doc setObject:self.fileType forKey:DataTypeUpdateDocumentFileType];
    if (nil == self.dateCreated ) {
        self.dateCreated = [NSDate date];
    }
    [doc setObject:self.dateCreated forKey:DataTypeUpdateDocumentDateCreated];
    if (nil == self.dateModified) {
        self.dateModified = [NSDate date];
    }
    [doc setObject:self.dateModified forKey:DataTypeUpdateDocumentDateModified];
    if (nil == self.dataMd5 || [self.dataMd5 isBlock]) {
        //md5
        self.dataMd5 = @"";
    }
    [doc setObject:self.dataMd5 forKey:DataTypeUpdateDocumentDataMd5];
    NSLog(@"%@",doc);
    if ([[WizDbManager shareDbManager] updateDocument:doc]) {
        [WizNotificationCenter postUpdateDocument:self.guid];
        return YES;
    }
    else {
        return NO;
    }
}

- (void) upload
{
    if (!self.localChanged) {
        return;
    }
    [[WizSyncManager shareManager] uploadWizObject:self];
    NSArray* attachments = [self attachments];
    for (WizAttachment* attch in attachments) {
        if (attch.localChanged) {
            [[WizSyncManager shareManager] uploadWizObject:attch];
        }
    }
}
- (void) download
{
    [[WizSyncManager shareManager] downloadWizObject:self];
}


- (NSString*) photoHtmlString:(NSString*)photoName
{
    return [NSString stringWithFormat:@"<img src=\"index_files/%@\" alt=\"%@\" >",photoName,photoName];
}
- (NSString*) audioHtmlString:(NSString*)audioName
{
    return [NSString stringWithFormat:@"<embed src=\"index_files/%@\" autostart=false>",audioName];
}
- (NSString*) titleHtmlString:(NSString*)_title
{
    return [NSString stringWithFormat:@"<title>%@</title>",_title];
}
- (NSString*) wizHtmlString:(NSString*)_title body:(NSString*)body  attachments:(NSArray*) attachments
{
    NSMutableString* tableContensString = [NSMutableString string];
    [tableContensString appendString:@"<ul>"];
    if (body) {
        [tableContensString appendFormat:@"<li><p>%@</p></li>",body];
    }
    for (WizAttachment* attachment in attachments) {
        NSString* source = attachment.description;
        NSString* fileName = [source fileName];
        NSString* attachmentType = [source fileType];
        [self addFileToIndexFiles:source];
        if ([WizGlobals checkAttachmentTypeIsImage:attachmentType]) {
            [tableContensString appendFormat:@"<li>%@</li>",[self photoHtmlString:fileName]];
        }
        else if ([WizGlobals checkAttachmentTypeIsAudio:attachmentType])
        {
            [tableContensString appendFormat:@"<li>%@</li>",[self audioHtmlString:fileName]];
        }
        else {
            [tableContensString appendFormat:@"Add %@",fileName];
        }
    }
    [tableContensString appendString:@"</ul>"];
    NSString* html = [NSString stringWithFormat:@"<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><style type=\"text/css\">  </style></head>%@<body>%@</body></html>",[self titleHtmlString:_title],tableContensString];
    return html;
}
- (BOOL) saveWithData:(NSString*)textBody   attachments:(NSArray*)documentsSourceArray
{
    if (self.serverChanged) {
        return NO;
    }
    if (self.guid == nil || [self.guid isBlock]) {
        self.guid = [WizGlobals genGUID];
    }
    BOOL hasPicture = NO;
    BOOL hasAudio = NO;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"self.localChanged < 0"];
    NSArray* editAttacment = [documentsSourceArray filteredArrayUsingPredicate:predicate];
    NSMutableArray* photoAndAudios = [NSMutableArray array];
    for (WizAttachment* each in editAttacment) {
        NSString* sourcePath = each.description;
        each.documentGuid = self.guid;
        NSString* attachmentType = [sourcePath fileType];
        if ([WizGlobals checkAttachmentTypeIsImage:attachmentType]) {
            [photoAndAudios addObject:each];
            hasPicture = YES;
        }
        else if ([WizGlobals checkAttachmentTypeIsAudio:attachmentType])
        {
            [photoAndAudios addObject:each];
            hasAudio = YES;
        }
        else if ([WizGlobals checkAttachmentTypeIsTxt:attachmentType])
        {
            NSError* error = nil;
            textBody = [NSString stringWithContentsOfFile:sourcePath usedEncoding:nil error:&error];
            if(error)
            {
                textBody = @"";
            }
        }
        else {
            [each saveData:each.description];
            textBody = [NSString stringWithFormat:@"Add by itouch"];
        }
    }
    self.attachmentCount = [documentsSourceArray count] - [photoAndAudios count];
    if (hasPicture && !hasAudio) {
        self.type = WizDocumentTypeImageKeyString;
    }
    else if (!hasPicture && hasAudio)
    {
        self.type = WizDocumentTypeAudioKeyString;
    }
    else {
        self.type = WizDocumentTypeNoteKeyString;
    }
    //
    if (nil == self.title) {
        if (hasPicture && !hasAudio) {
            self.title = WizStrNewDocumentTitleImage;
        }
        else if (!hasPicture && hasAudio)
        {
            self.title = WizStrNewDocumentTitleAudio;
        }
        else {
            if ([textBody firstLine]) {
                self.title = [textBody firstLine];
            }
            else
            {
                self.title = WizStrNewDocumentTitleAudio;
            }
        }
    }
    MKPlacemark* placeMark = [[WizSettings defaultSettings] getCurrentPlaceMark];
    NSLog(@"location %@",placeMark);
    if (nil != placeMark) {
        self.title = [self.title stringByAppendingString:placeMark.description];
    }
    NSString* html = [self wizHtmlString:self.title body:textBody attachments:photoAndAudios];
    NSString* documentIndex = [self documentIndexFile];
    [html writeToFile:documentIndex atomically:YES encoding:NSUTF16StringEncoding error:nil];
    [html writeToFile:[self documentMobileFile] atomically:YES encoding:NSUTF16StringEncoding error:nil];
    self.dataMd5 = [self localDataMd5];
    self.localChanged = WizEditDocumentTypeAllChanged;
    [self saveInfo];
    return YES;
}

- (BOOL) deleteTag:(NSString*)tagGuid
{
    if (nil == self.tagGuids) {
        return NO;
    }
    NSRange range = [self.tagGuids rangeOfString:tagGuid];
    if (range.location == NSNotFound || range.length == NSNotFound)
    {
        return NO;
    }
    self.tagGuids = [self.tagGuids stringByReplacingCharactersInRange:range withString:@""];
    if(range.location >= 1)
    {
        NSRange subRange = NSMakeRange(range.location-1, 1);
        NSString* sepatatedStr = [self.tagGuids substringWithRange:subRange];
        if([sepatatedStr isEqualToString:@"*"])
        {
            self.tagGuids = [self.tagGuids stringByReplacingCharactersInRange:subRange withString:@""];
        }
    }
    self.localChanged = WizEditDocumentTypeInfoChanged;
    return [self saveInfo];
}

- (void) setTagWithArray:(NSArray*)tags
{
    NSMutableString* tagsGuid_ = [NSMutableString stringWithCapacity:0];
    for (WizTag* tag in tags) {
        [tagsGuid_ appendFormat:@"%@*",tag.guid];
    }
    if (tagsGuid_.length >0) {
        tagsGuid_ = [NSMutableString stringWithString:[tagsGuid_ substringToIndex:tagsGuid_.length -1]];
    }
    self.tagGuids = tagsGuid_;
}
- (NSArray*) existPhotoAndAudio
{
    NSArray* array = [[WizFileManager shareManager] contentsOfDirectoryAtPath:[self documentIndexFilesPath] error:nil];
    NSMutableArray* ret = [NSMutableArray array];
    for (NSString* each in array) {
        NSString* attachmentType = [each fileType];
        if ([WizGlobals checkAttachmentTypeIsImage:attachmentType] || [WizGlobals checkAttachmentTypeIsAudio:attachmentType]) {
            [ret addAttachmentBySourceFile:[[self documentIndexFilesPath] stringByAppendingPathComponent:each]];
        }
    }
    return ret;
}
+ (NSArray*)documentsForCache
{
    WizDbManager* share = [WizDbManager shareDbManager];
    NSInteger duration = [[WizSettings defaultSettings] durationForDownloadDocument];
    return [share documentsForCache:duration];
}
- (BOOL) isIosDocument
{
    if(nil == self.type)
    {
        return NO;
    }
    return [self.type isEqualToString:WizDocumentTypeAudioKeyString] || [self.type isEqualToString:WizDocumentTypeImageKeyString] || [self.type isEqualToString:WizDocumentTypeNoteKeyString];
}
@end
