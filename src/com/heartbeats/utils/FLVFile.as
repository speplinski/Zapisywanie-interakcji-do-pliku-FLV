/* This file is part of the "Zapisywanie Augmented Reality do pliku FLV" project.
 * http://lab.180hb.com/2010/06/flv-maker/
 *
 * Copyright (c) 2011 LAB^180 (http://lab.180hb.com).
 *
 * @author Szymon P. Peplinski (speplinski@180hb.com)
 *
 * This code is licensed to you under the terms of the Creative Commons 
 * Attribution–Share Alike 3.0 Unported license ("CC BY-SA 3.0").
 * An explanation of CC BY-SA 3.0 is available at 
 * http://creativecommons.org/licenses/by-sa/3.0/.
 *
 * The original authors of this document, and LAB^180, 
 * designate this project as the "Attribution Party" 
 * for purposes of CC BY-SA 3.0.
 *
 * In accordance with CC BY-SA 3.0, if you distribute this document 
 * or an adaptation of it, you must provide the URL 
 * for the original version.
 */

package com.heartbeats.utils
{

import flash.display.BitmapData;
import flash.utils.ByteArray;
import flash.utils.Endian;

/**
 * Application entry point for FLVFile.
 *
 *	@langversion ActionScript 3.0
 *	@playerversion Flash 9.0
 *
 *	@author Szymon Peplinski
 */

public class FLVFile
{
	/**
	  * Pixel width of each block in the grid.
	  */
	private static const BLOCK_WIDTH : uint = 32;

	/**
	  * Pixel height of each block in the grid.
	  */
	private static const BLOCK_HEIGHT : uint = 32;

	/**
	  * The name of the meta data event handler.
	  */
	private static const ONMETADATA : String = "onMetaData";

	/**
	  * The name of the duration of the FLV file in seconds.
	  */
	private static const DURATION : String = "duration";

	/**
	  * The name of the width of the FLV file.
	  */
	private static const WIDTH : String = "width";

	/**
	  * The name of the height of the FLV file.
	  */
	private static const HEIGHT : String = "height";

	/**
	  * The name of the frame rate of the FLV file.
	  */
	private static const FRAMERATE : String = "framerate";

	/**
	  * The name of the codec version that was used to encode the video.
	  */
	private static const VIDEOCODECID : String = "videocodecid";

	/**
	  * A Boolean value that is true if the FLV file is encoded with a keyframe on the last frame 
	  * that allows seeking to the end of a progressive download movie clip. 
	  * It is false if the FLV file is not encoded with a keyframe on the last frame.
	  */
	private static const CANSEEKTOEND : String = "canSeekToEnd";

	/**
	  * The name of the meta data creator.
	  */
	private static const METADATACREATOR : String = "metadatacreator";

	/**
	  * The name of the file creator.
	  */
	private static const CREATEDBY : String = "180heartbeats";

	/**
	  * The width of the video, in pixels.
	  */
	private var _frameWidth : uint;

	/**
	  * The height of the video, in pixels.
	  */
	private var _frameHeight : uint;

	/**
	  * The frames per second at which the video was recorded.
	  */
	private var _frameRate : Number;

	/**
	  * The length of the file, in seconds.
	  */
	private var _duration : Number;

	/**
	  * The content of a file.
	  */
	private var _flvFile : ByteArray;

	/**
	  * The length of the last tag, in bytes.
	  */
	private var _previousTagSize : uint = 0;

	/**
	  * The video frame delay.
	  */
	private var _delay : uint = 0;

	/**
	  * The content of an video frame.
	  */
	private var _frameData : BitmapData;

	/**
	  * Stores the lone instance of the class.
	  */
	private static var _instance : FLVFile;
	
	/**
	  * An instance-retrieval get method, instance, that returns a reference to the lone instance.
	  * @return Retrieve an instance of the class.
	  */
	public static function get instance () : FLVFile
	{
		return initialize ();
	}
	
	/**
	  * @return The content of a FLV file.
	  */
	public static function get file () : ByteArray
	{
		return instance._flvFile;
	}
	
	public static function get duration () : Number
	{
		return instance._duration;
	}
	
	/**
	  * Protected instance-retrieval method, initialize, that returns a reference to the lone instance.
	  * @return Retrieve an instance of the class
	  */
	protected static function initialize () : FLVFile
	{
		if ( _instance == null )
		{
			_instance = new FLVFile ( new SingletonEnforcer () );
		}
		return _instance;
	}
	
	/**
	  * @param frameWidth The nominal width of the FLV file.
	  * @param frameHeight The nominal height of the FLV file.
	  * @param framesPerSecond The nominal frame rate, in frames per second.
	  * @param durationInSeconds Determines the length of time for the FLV file.
	  */
	public static function createFile ( frameWidth : uint, frameHeight : uint, framesPerSecond : Number, durationInSeconds : Number = 0 ) : void
	{
		instance._createFile ( frameWidth, frameHeight, framesPerSecond, durationInSeconds );
	}
	
	/**
	  * @param videoFrameData The data (pixels) of a Bitmap.
	  */
	public static function saveFrame ( frameData : BitmapData ) : void
	{
		instance._saveFrame ( frameData );
	}

	/**
	  * @constructor
	  */
	public function FLVFile ( singletonEnforcer : SingletonEnforcer ) 
	{
		super ();
		
		if ( singletonEnforcer == null ) 
		{
			throw new Error ( "Error: Instantiation failed: Use FLVFile.instance instead of new." );
		}
	}

	/**
	 * @param frameWidth The nominal width of the FLV file.
	 * @param frameHeight The nominal height of the FLV file.
	 * @param framesPerSecond The nominal frame rate, in frames per second.
	 * @param durationInSeconds Determines the length of time for the FLV file.
	 */
	private function _createFile ( frameWidth : uint, frameHeight : uint, framesPerSecond : Number, durationInSeconds : Number = 0 ) : void
	{
		this._frameWidth = frameWidth;
		this._frameHeight = frameHeight;
		this._frameRate = framesPerSecond;
		this._duration = durationInSeconds;

		// The FLV File
		this._flvFile = new ByteArray ();
		this._flvFile.endian = Endian.BIG_ENDIAN;

		// The FLV header
		this._flvFile.writeBytes ( this._header () );

		// The FLV file body
		this._flvFile.writeUnsignedInt ( this._previousTagSize );
		this._flvFile.writeBytes ( this._scriptDataObject () );
	}
	
	private function _saveFrame ( frameData : BitmapData ) : void
	{
		this._frameData = frameData;

		this._flvFile.writeUnsignedInt ( this._previousTagSize );
		this._flvFile.writeBytes ( this._flvTag () );
	}
	
	private function _header () : ByteArray
	{
		var byteArray : ByteArray = new ByteArray ();

		// Signature byte always 'F' ( 0x46 )
		byteArray.writeByte ( 0x46 );

		// Signature byte always 'L' ( 0x4C )
		byteArray.writeByte ( 0x4C );

		// Signature byte always 'V' ( 0x56 )
		byteArray.writeByte ( 0x56 );

		// File version ( 0x01 for FLV version 1 )
		byteArray.writeByte ( 0x01 );

		// TypeFlagsReserved	UB[5] Must be 0
		// TypeFlagsAudio		UB[1] Audio tags are present 
		// TypeFlagsReserved	UB[1] Must be 0 
		// TypeFlagsVideo		UB[1] Video tags are present 
		byteArray.writeByte ( 0x01 );

		// Offset in bytes from start of file to start of body (that is, size of header)
		// The DataOffset field usually has a value of 9 for FLV version 1.
		byteArray.writeUnsignedInt ( 0x09 );

		return byteArray;
	}
	
	private function _flvTag () : ByteArray
	{
		var flvTag : ByteArray = new ByteArray ();

		var data : ByteArray = this._videoData ();

		var timeStamp : uint = uint ( 1000 / this._frameRate * this._delay ++ );

		// TagType [UI8]
		// Type of this tag. Values are:
		// 8 : audio, 9 : video, 18 : script data, all others : reserved
		flvTag.writeByte ( 0x09 );

		// DataSize [UI24]
		// Length of the data in the Data field
		this._writeUI24 ( flvTag, data.length );

		// Timestamp [UI24] 
		// Time in milliseconds at which the data in this tag applies. 
		// This value is relative to the first tag in the FLV file, which always has a timestamp of 0.
		this._writeUI24 ( flvTag, timeStamp );

		// TimestampExtended [UI8] 
		// Extension of the Timestamp field to form a SI32 value. 
		// This field represents the upper 8bits, while the previous Timestamp field represents the lower 24bits of the time in milliseconds.
		flvTag.writeByte ( 0 );

		// StreamID [UI24] 
		// Always 0
		this._writeUI24 ( flvTag, 0 );
 
		// Body of the tag
		// If TagType == 8 AUDIODATA 
		// If TagType == 9 VIDEODATA 
		// If TagType == 18 SCRIPTDATAOBJECT
		flvTag.writeBytes ( data );

		this._previousTagSize = flvTag.length;

		return flvTag;
	}
	
	private function _videoData () : ByteArray
	{
		var videoData : ByteArray = new ByteArray ();

		// FrameType UB[4]
		// 1: keyframe (for AVC, a seekable frame) 
		// 2: inter frame (for AVC, a non-seekable frame) 
		// 3: disposable inter frame (H.263 only) 
		// 4: generated keyframe (reserved for server use only) 
		// 5: video info/command frame 

		// CodecID UB[4] 
		// 1: JPEG (currently unused) 
		// 2: Sorenson H.263 
		// 3: Screen video 
		// 4: On2 VP6 
		// 5: On2 VP6 with alpha channel 
		// 6: Screen video version 2 
		// 7: AVC

		// FrameType ( 1 ) + CodecID ( 3 )
		videoData.writeByte ( 0x13 );

		// Video packet 
		//
		// The video packet is the top-level structural element in a screen video packet 
		// and consists of information about the image sub-block dimensions and grid size, 
		// followed by the data for each block.

		// BlockWidth UB[4] 
		// Pixel width of each block in the grid. 
		// This value is stored as (actualWidth / 16) - 1, 
		// so possible block sizes are a multiple of 16 and not more than 256. 

		// ImageWidth UB[12] 
		// Pixel width of the full image.

		// BlockWidth + ImageWidth
		this._writeUI4_12 ( videoData, ( BLOCK_WIDTH >> 4 ) - 1, this._frameWidth );

		// BlockHeight UB[4] 
		// Pixel height of each block in the grid. 
		// This value is stored as (actualHeight / 16) - 1, 
		// so possible block sizes are a multiple of 16 and not more than 256.

		// ImageHeight UB[12] 
		// Pixel height of the full image.

		// BlockHeight + ImageHeight
		this._writeUI4_12 ( videoData, ( BLOCK_HEIGHT >> 4 ) - 1, this._frameHeight );

		// ImageBlocks IMAGEBLOCK[n] 
		// Blocks of image data. 
		// Blocks are ordered from bottom left to top right, in rows.

		var yMax : uint = uint ( this._frameHeight / BLOCK_HEIGHT );
		var yRemainder : uint = this._frameHeight % BLOCK_HEIGHT;

		if ( yRemainder > 0 ) 
		{
			yMax ++;
		}

		var xMax : uint = uint ( this._frameWidth / BLOCK_WIDTH );
		var xRemainder : uint = this._frameWidth % BLOCK_WIDTH;

		if ( xRemainder > 0 ) 
		{
			xMax ++;
		}

		var y1 : uint;
		var x1 : uint;

		var y2 : uint;
		var x2 : uint;

		for ( y1 = 0; y1 < yMax; y1 ++ )
		{
			for ( x1 = 0; x1 < xMax; x1 ++ ) 
			{
				// The image block represents one block in a frame.
				var imageBlock : ByteArray = new ByteArray ();
		
				var yLimit : uint = BLOCK_HEIGHT;
		
				if ( yRemainder > 0 && y1 + 1 == yMax ) 
				{
					yLimit = yRemainder;
				}

				for ( y2 = 0; y2 < yLimit; y2 ++ ) 
				{
					var xLimit : uint = BLOCK_WIDTH;
			
					if ( xRemainder > 0 && x1 + 1 == xMax ) 
					{
						xLimit = xRemainder;
					}
			
					for ( x2 = 0; x2 < xLimit; x2 ++ ) 
					{
						// Pixels are ordered from bottom left to top right in rows.
						var px : uint = ( x1 * BLOCK_WIDTH ) + x2;
						var py : uint = this._frameHeight - ( ( y1 * BLOCK_HEIGHT ) + y2 );
				
						var pixel : uint = this._frameData.getPixel ( px, py );
				
						// Each pixel is three bytes: B, G, R.
						imageBlock.writeByte ( pixel & 0xff ); // B
						imageBlock.writeByte ( pixel >> 8 & 0xff ); // G
						imageBlock.writeByte ( pixel >> 16 & 0xff ); // R
					}
				}
		
				// Pixel data compressed using ZLIB.
				imageBlock.compress ();

				// DataSize UB[16] 
				// Note: UB[16] is not the same as UI16; no byte swapping occurs. 
				// Size of the compressed block data that follows. If this is an interframe, 
				// and this block is not changed since the last keyframe, 
				// DataSize is 0 and the Data field is absent.
				this._writeUI16 ( videoData, imageBlock.length );
		
				// Data 
				// If DataSize > 0, UI8[DataSize]
				videoData.writeBytes ( imageBlock );
			}
		}
		
		return videoData;
	}
	
	private function _scriptDataObject () : ByteArray
	{
		var scriptData : ByteArray = new ByteArray ();

		var metaData : ByteArray = this._metaData ();

		// TagType [UI8]
		// 18: script data
		scriptData.writeByte ( 18 );

		// DataSize [UI24]
		// Length of the data in the Data field.
		this._writeUI24 ( scriptData, metaData.length );

		// Timestamp [UI24] 
		// Time in milliseconds at which the data in this tag applies. 
		//This value is relative to the first tag in the FLV file, which always has a timestamp of 0. 
		this._writeUI24 ( scriptData, 0 );

		//TimestampExtended [UI8] 
		// Extension of the Timestamp field to form a SI32 value. 
		// This field represents the upper 8bits, while the previous Timestamp field 
		// represents the lower 24bits of the time in milliseconds.
		scriptData.writeByte ( 0 );

		// StreamID [UI24] 
		// Always 0 
		this._writeUI24 ( scriptData, 0 );

		// Data
		// Body of the tag.
		scriptData.writeBytes ( metaData );

		this._previousTagSize = scriptData.length;

		return scriptData;
	}
	
	private function _metaData () : ByteArray
	{
		// An FLV file can contain metadata with an "onMetaData" marker. Various stream properties 
		// are available to a running ActionScript program via the NetStream.onMetaData property.

		var metaData : ByteArray = new ByteArray ();

		// String type.
		metaData.writeByte ( 2 );

		// String length in bytes.
		this._writeUI16 ( metaData, ONMETADATA.length );

		// String data.
		metaData.writeUTFBytes ( ONMETADATA );

		// ECMA array type.
		metaData.writeByte ( 8 );

		// ECMA array length.
		metaData.writeUnsignedInt ( 7 );

		// ScriptDataVariable record defines variable data in ActionScript. 
		// Lists of ScriptDataVariable records are terminated by using the ScriptDataVariableEnd tag.

		// ScriptDataValue
		// If Type == 0 DOUBLE 
		// If Type == 1 UI8 
		// If Type == 2 SCRIPTDATASTRING 
		// If Type == 3 SCRIPTDATAOBJECT[n] 
		// If Type == 4 SCRIPTDATASTRING
		// If Type == 7 UI16 
		// If Type == 8 SCRIPTDATAVARIABLE[ECMAArrayLength] 
		// If Type == 10 SCRIPTDATAVARIABLE[n] 
		// If Type == 11 SCRIPTDATADATE 
		// If Type == 12 SCRIPTDATALONGSTRING 

		if ( this._duration > 0 ) 
		{
			this._writeUI16 ( metaData, DURATION.length );
			metaData.writeUTFBytes ( DURATION );
			metaData.writeByte ( 0 ); 
			metaData.writeDouble ( this._duration );
		}

		this._writeUI16 ( metaData, WIDTH.length );
		metaData.writeUTFBytes ( WIDTH );
		metaData.writeByte ( 0 );
		metaData.writeDouble ( this._frameWidth );

		this._writeUI16 ( metaData, HEIGHT.length );
		metaData.writeUTFBytes ( HEIGHT );
		metaData.writeByte ( 0 );
		metaData.writeDouble ( this._frameHeight );

		this._writeUI16 ( metaData, FRAMERATE.length );
		metaData.writeUTFBytes ( FRAMERATE );
		metaData.writeByte ( 0 );
		metaData.writeDouble ( this._frameRate );

		this._writeUI16 ( metaData, VIDEOCODECID.length );
		metaData.writeUTFBytes ( VIDEOCODECID );
		metaData.writeByte ( 0 );
		metaData.writeDouble ( 3 ); // CodecID 3: Screen video.

		this._writeUI16 ( metaData, CANSEEKTOEND.length );
		metaData.writeUTFBytes ( CANSEEKTOEND );
		metaData.writeByte ( 1 ); 
		metaData.writeByte ( 1 );

		this._writeUI16 ( metaData, METADATACREATOR.length );
		metaData.writeUTFBytes ( METADATACREATOR );
		metaData.writeByte ( 2 ); 
		this._writeUI16 ( metaData, CREATEDBY.length );
		metaData.writeUTFBytes ( CREATEDBY );

		// VariableEndMarker1 [UI24]
		// Always 9
		this._writeUI24 ( metaData, 9 );

		return metaData;
	}
	
	private function _writeUI24 ( byteArray : ByteArray, value : uint ) : void
	{
		var byte1 : int = value >> 16 & 0xff;
		var byte2 : int = value >> 8 & 0xff;
		var byte3 : int = value & 0xff;

		byteArray.writeByte ( byte1 );
		byteArray.writeByte ( byte2 );
		byteArray.writeByte ( byte3 );
	}
	
	private function _writeUI16 ( byteArray : ByteArray, value : uint ) : void
	{
		byteArray.writeByte ( value >> 8 & 0xff );
		byteArray.writeByte ( value & 0xff );
	}
	
	private function _writeUI4_12 ( byteArray : ByteArray, blockSize : uint, imageSize : uint ) : void
	{
		var byte1a : int = blockSize << 4;
		var byte1b : int = imageSize >> 8;

		var byte1 : uint = ( byte1a + byte1b ) & 0xff;
		var byte2 : uint = imageSize & 0xff;

		byteArray.writeByte ( byte1 );
		byteArray.writeByte ( byte2 );
	}

}
}

internal class SingletonEnforcer {}