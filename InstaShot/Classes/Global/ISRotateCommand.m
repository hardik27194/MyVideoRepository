//
//  ISRotateCommand.m
//  InstaShot
//
//  Created by Liu Xiang on 10/23/14.
//  Copyright (c) 2014 Liu Xiang. All rights reserved.
//

#import "ISRotateCommand.h"

#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

@implementation ISRotateCommand

- (void)performWithAsset:(AVAsset*)asset
{
	AVMutableVideoCompositionInstruction *instruction = nil;
	AVMutableVideoCompositionLayerInstruction *layerInstruction = nil;
	CGAffineTransform t1;
	CGAffineTransform t2;
	
	AVAssetTrack *assetVideoTrack = nil;
	AVAssetTrack *assetAudioTrack = nil;
	// Check if the asset contains video and audio tracks
	if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
		assetVideoTrack = [asset tracksWithMediaType:AVMediaTypeVideo][0];
	}
	if ([[asset tracksWithMediaType:AVMediaTypeAudio] count] != 0) {
		assetAudioTrack = [asset tracksWithMediaType:AVMediaTypeAudio][0];
	}
	
	CMTime insertionPoint = kCMTimeZero;
	NSError *error = nil;
	
	
	// Step 1
	// Create a composition with the given asset and insert audio and video tracks into it from the asset
	if (!self.mutableComposition) {
		
		// Check whether a composition has already been created, i.e, some other tool has already been applied
		// Create a new composition
		self.mutableComposition = [AVMutableComposition composition];
		
		// Insert the video and audio tracks from AVAsset
		if (assetVideoTrack != nil) {
			AVMutableCompositionTrack *compositionVideoTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
			[compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetVideoTrack atTime:insertionPoint error:&error];
		}
		if (assetAudioTrack != nil) {
			AVMutableCompositionTrack *compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
			[compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration]) ofTrack:assetAudioTrack atTime:insertionPoint error:&error];
		}
		
	}
	
	
	// Step 2
	// Translate the composition to compensate the movement caused by rotation (since rotation would cause it to move out of frame)
	t1 = CGAffineTransformMakeTranslation(assetVideoTrack.naturalSize.height, 0.0);
	// Rotate transformation
	t2 = CGAffineTransformRotate(t1, degreesToRadians(90.0));
	

	// Step 3
	// Set the appropriate render sizes and rotational transforms
	if (!self.mutableVideoComposition) {
		
		// Create a new video composition
		self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
		self.mutableVideoComposition.renderSize = CGSizeMake(assetVideoTrack.naturalSize.height,assetVideoTrack.naturalSize.width);
		self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
		
		// The rotate transform is set on a layer instruction
		instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
		instruction.timeRange = CMTimeRangeMake(kCMTimeZero, [self.mutableComposition duration]);
		layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:(self.mutableComposition.tracks)[0]];
		[layerInstruction setTransform:t2 atTime:kCMTimeZero];
		
	} else {
		
		self.mutableVideoComposition.renderSize = CGSizeMake(self.mutableVideoComposition.renderSize.height, self.mutableVideoComposition.renderSize.width);
		
		// Extract the existing layer instruction on the mutableVideoComposition
		instruction = (self.mutableVideoComposition.instructions)[0];
		layerInstruction = (instruction.layerInstructions)[0];
		
		// Check if a transform already exists on this layer instruction, this is done to add the current transform on top of previous edits
		CGAffineTransform existingTransform;
		
		if (![layerInstruction getTransformRampForTime:[self.mutableComposition duration] startTransform:&existingTransform endTransform:NULL timeRange:NULL]) {
			[layerInstruction setTransform:t2 atTime:kCMTimeZero];
		} else {
			// Note: the point of origin for rotation is the upper left corner of the composition, t3 is to compensate for origin
			CGAffineTransform t3 = CGAffineTransformMakeTranslation(-1*assetVideoTrack.naturalSize.height/2, 0.0);
			CGAffineTransform newTransform = CGAffineTransformConcat(existingTransform, CGAffineTransformConcat(t2, t3));
			[layerInstruction setTransform:newTransform atTime:kCMTimeZero];
		}
		
	}
	
	
	// Step 4
	// Add the transform instructions to the video composition
	instruction.layerInstructions = @[layerInstruction];
	self.mutableVideoComposition.instructions = @[instruction];
	
	
	// Step 5
	// Notify AVSEViewController about rotation operation completion
	[[NSNotificationCenter defaultCenter] postNotificationName:ISEditCommandCompletionNotification object:self];
}

@end
