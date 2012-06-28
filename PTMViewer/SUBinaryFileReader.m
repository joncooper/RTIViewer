//
//  SUBinaryFileReader.m
//  PTMViewer
//
//  Created by Jon Cooper on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SUBinaryFileReader.h"

@interface SUBinaryFileReader()

- (UInt8)getUInt8at:(NSUInteger)position;

@end

@implementation SUBinaryFileReader {
    NSURL                        *_fileURL;
    NSData                       *_fileData;
    NSUInteger                   _markedPosition;
}

@synthesize currentPosition = _currentPosition;

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        NSError *error;
        _fileURL = url;
        _fileData = [NSData dataWithContentsOfURL:_fileURL options:NSDataReadingMappedIfSafe error:&error];
        _currentPosition = 0;
        _markedPosition = 0;
    }
    return self;
}

- (void)mark {
    _markedPosition = _currentPosition;
}

- (void)reset {
    _currentPosition = _markedPosition;
}

- (NSString *)peekLine {
    [self mark];
    NSString *line = [self readLine];
    [self reset];
    return line;
}

- (NSString *)readLine {
    if (_currentPosition >= [_fileData length]) {
        return nil;
    }
    
    NSInteger start = _currentPosition;
    NSInteger end = -1;
    
    while ((_currentPosition < [_fileData length]) && (end < start)) {
        if ([self getUInt8at:_currentPosition] == 0x0a) {
            if ((_currentPosition > 0) && ([self getUInt8at:(_currentPosition-1)] == 0x0d)) {
                end = _currentPosition - 1;
            } else {
                end = _currentPosition;
            }
            _currentPosition = _currentPosition + 1;
            return [self stringFromRange:NSMakeRange(start, end - start)];
        } else {
            _currentPosition = _currentPosition + 1;
        }
    }
    return nil;
}

- (NSString *)stringFromRange:(NSRange)range {
    NSData *data = [_fileData subdataWithRange:range];
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (Float32)readFloat32 {
    Float32 f;
    [_fileData getBytes:&f range:NSMakeRange(_currentPosition, 4)];
    _currentPosition += 4;
    return f;
}

- (void)readFloat32:(Float32 **)array count:(NSUInteger)count {
    int bytes = 4 * count;
    [_fileData getBytes:array range:NSMakeRange(_currentPosition, bytes)];
    _currentPosition += bytes;
}

- (UInt8)readUInt8 {
    UInt8 byte = [self getUInt8at:_currentPosition];
    _currentPosition += 1;
    return byte;
}

- (UInt8)getUInt8at:(NSUInteger)position {
    UInt8 byte;
    [_fileData getBytes:&byte range:NSMakeRange(position, 1)];
    return byte;
}

@end