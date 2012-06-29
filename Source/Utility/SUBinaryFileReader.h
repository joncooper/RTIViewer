//
//  SUBinaryFileReader.h
//  PTMViewer
//
//  Created by Jon Cooper on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SUBinaryFileReader : NSObject

@property (readonly, nonatomic) NSUInteger currentPosition;

- (id)initWithURL:(NSURL *)url;

- (void)mark;
- (void)reset;

- (NSString *)peekLine;
- (NSString *)readLine;
- (NSString *)stringFromRange:(NSRange)range;

- (Float32)readFloat32;
- (UInt8)readUInt8;

- (void)readFloat32:(Float32 **)array count:(NSUInteger)count;
- (void)readNSData:(NSData **)data count:(NSUInteger)count;

@end