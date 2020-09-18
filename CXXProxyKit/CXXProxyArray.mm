//
//  CXXNonOwningProxyArray.m
//  CXXProxyKit
//
//  Created by Dmitry Khrykin on 01.09.2020.
//  Copyright © 2020 Dmitry Khrykin. All rights reserved.
//

#import "CXXProxyArray.h"

@interface CXXNonOwningProxyArray () {
    CXXArraySizeGetter _getArraySize;
    CXXArrayElementProxyAllocator _allocElementProxy;
}

@end

@implementation CXXNonOwningProxyArray

- (instancetype)initWithItemProxyAllocator:(CXXArrayElementProxyAllocator)itemProxyAllocator
                             countingBlock:(CXXArraySizeGetter)countingBlock {
    if (self = [super init]) {
        _allocElementProxy = itemProxyAllocator;
        _getArraySize = countingBlock;
    }

    return self;
}

- (id)objectAtIndexedSubscript:(NSInteger)idx {
    return _allocElementProxy(idx);
}

- (NSInteger)count {
    return _getArraySize();
}

- (NSUInteger)countByEnumeratingWithState:(nonnull NSFastEnumerationState *)state
                                  objects:(__unsafe_unretained id _Nullable * _Nonnull)buffer
                                    count:(NSUInteger)bufferSize {
    NSUInteger indexInBuffer = 0;

    // We use state->state to track how far we have enumerated through _list
    // between sucessive invocations of -countByEnumeratingWithState:objects:count:
    unsigned long currentItemIndex = state->state;

    // This is the initialization condition, so we'll do one-time setup here.
    // Ensure that you never set state->state back to 0, or use another method to
    // detect initialization (such as using one of the values of state->extra).
    if (currentItemIndex == 0) {
        // We are not tracking mutations, so we'll set state->mutationsPtr to point
        // into one of our extra values, since these values are not otherwise used
        // by the protocol.
        // If your class was mutable, you may choose to use an internal variable that
        // is updated when the class is mutated.
        // state->mutationsPtr MUST NOT be NULL and SHOULD NOT be set to self.
        state->mutationsPtr = &state->extra[0];
    }

    // Now we provide items and determine if we have finished iterating.
    if (currentItemIndex < [self count]) {
        // Set state->itemsPtr to the provided buffer.
        // state->itemsPtr MUST NOT be NULL.
        state->itemsPtr = buffer;
        // Fill in the stack array, either until we've provided all items from the list
        // or until we've provided as many items as the stack based buffer will hold.
        while ((currentItemIndex < [self count]) && (indexInBuffer < bufferSize)) {
            buffer[indexInBuffer] = [self objectAtIndexedSubscript:currentItemIndex];
            currentItemIndex++;

            // We must return how many items are in state->itemsPtr.
            indexInBuffer++;
        }
    } else {
        // We've already provided all our items.  Signal that we are finished by returning 0.
        indexInBuffer = 0;
    }

    state->state = currentItemIndex;

    return indexInBuffer;
}

- (NSArray *)toArray {
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:self.count];
    for (NSInteger idx = 0; idx < self.count; idx++) {
        [array addObject:[self objectAtIndexedSubscript:idx]];
    }

    return array;
}

@end
