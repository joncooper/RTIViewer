//
//  SUBinaryFileReaderSpec.m
//  PTMViewer
//
//  Created by Jon Cooper on 6/27/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "SUBinaryFileReader.h"

SPEC_BEGIN(SUBinaryFileReaderSpec)

// See fixture_gen.c; to generate the fixture: gcc -o fg fixture_gen.c && ./fg 
//
describe(@"with a fixture file", ^{
    __block SUBinaryFileReader *binaryFileReader;
    
    beforeEach(^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSURL *url = [bundle URLForResource:@"fixture" withExtension:@"dat"];
        binaryFileReader = [[SUBinaryFileReader alloc] initWithURL:url];
    });
    
    describe(@"-mark / -reset", ^{
        it(@"marks and resets the current position", ^{
            UInt8 byte;
            for (int i = 0; i < 10; i++) {
                byte = [binaryFileReader readUInt8];
            }
            [[theValue([binaryFileReader currentPosition]) should] equal:theValue(10)];
            [[theValue(byte) should] equal:theValue(' ')];
            
            [binaryFileReader mark];
            
            for (int i = 0; i < 4; i++) {
                byte = [binaryFileReader readUInt8];
            }
            [[theValue([binaryFileReader currentPosition]) should] equal:theValue(14)];
            [[theValue(byte) should] equal:theValue('e')];        
            
            [binaryFileReader reset];
            
            [[theValue([binaryFileReader currentPosition]) should] equal:theValue(10)];
            [[theValue([binaryFileReader readUInt8]) should] equal:theValue('l')];
        });
    });
    describe(@"uint8 support", ^{
        describe(@"-readUInt8", ^{
            beforeEach(^{
                [binaryFileReader readLine];
                [binaryFileReader readLine];
            });
            it(@"returns a UInt8", ^{
                [[theValue([binaryFileReader readUInt8] == 0x01) should] beTrue];
                [[theValue([binaryFileReader readUInt8] == 0x02) should] beTrue];
                [[theValue([binaryFileReader readUInt8] == 0xAB) should] beTrue];
            });
            it(@"increments the currentPosition", ^{
                [binaryFileReader readUInt8];
                [[theValue([binaryFileReader currentPosition]) should] equal:theValue(43)];
            });
        });
    });
    describe(@"string support", ^{
        describe(@"-peekLine", ^{
            it(@"returns a string", ^{
                NSString *str = [binaryFileReader peekLine];
                [[str should] equal:@"This is a line of text."];
            });    
            it(@"does not increment the currentPosition", ^{
                [binaryFileReader peekLine];
                [[theValue([binaryFileReader currentPosition]) should] equal:theValue(0)];
            });
        });
        describe(@"-readLine", ^{
            it(@"returns a string, with line-end stripped", ^{
                NSString *str = [binaryFileReader readLine];
                [[str should] equal:@"This is a line of text."];
            });
            it(@"correctly handles \r\n line termination", ^{
                NSString *str = [binaryFileReader readLine];
                str = [binaryFileReader readLine];
                [[str should] equal:@"And another one."];                
            });
            it(@"increments the currentPosition", ^{
                [binaryFileReader readLine];
                [[theValue([binaryFileReader currentPosition]) should] equal:theValue(24)];
            });    
        });
        describe(@"-stringFromRange", ^{
            it(@"returns a string", ^{
                NSString *str = [binaryFileReader stringFromRange:NSMakeRange(0, 5)];
                [[str should] equal:@"This "];
            });
            it(@"does not increment the currentPosition", ^{
                [binaryFileReader stringFromRange:NSMakeRange(0, 10)];
                [[theValue([binaryFileReader currentPosition]) should] equal:theValue(0)];
            });
        });
    });
    describe(@"float32 support", ^{
        beforeEach(^{
            // TODO: should I implement seek()? Probably
            [binaryFileReader readLine];
            [binaryFileReader readLine];
            for (int i = 0; i < 3; i++)
                [binaryFileReader readUInt8];
        });
        describe(@"-readFloat32", ^{
            [[theValue([binaryFileReader readFloat32] == 0.123456789) should] beTrue];
            [[theValue([binaryFileReader readFloat32] == -9.87654321) should] beTrue];
            [[theValue([binaryFileReader readFloat32] == 3.14159) should] beTrue];
        });
        describe(@"-readFloat32:count", ^{
            Float32 *floats = (Float32 *)calloc(3, sizeof(Float32));
            [binaryFileReader readFloat32:&floats count:3];
            [[theValue(floats[0] == 0.123456789) should] beTrue];
            [[theValue(floats[0] == -9.87654321) should] beTrue];
            [[theValue(floats[0] == 3.14159) should] beTrue];
            free(floats);
        });
    });
});

SPEC_END