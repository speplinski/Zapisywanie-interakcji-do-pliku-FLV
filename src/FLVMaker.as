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

package 
{

import flash.display.Sprite;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.PixelSnapping;
import flash.display.StageScaleMode;
import flash.display.StageAlign;
import flash.events.Event;
import flash.events.TimerEvent;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.geom.Matrix;
import flash.media.Camera;
import flash.media.Microphone;
import flash.media.Video;
import flash.net.FileReference;
import flash.utils.Timer;
import flash.utils.setTimeout;
import flash.utils.Dictionary;
import flash.utils.setTimeout;

import com.heartbeats.utils.FLVFile;

[ SWF ( width = '320', height = '240', backgroundColor = '#FFFFFF', frameRate = '30' ) ]

/**
 *	Application entry point for FLVMaker.
 *
 *	@langversion ActionScript 3.0
 *	@playerversion Flash 9.0
 *
 *	@author Szymon Peplinski
 *	@since 01.06.2009
 */

public class FLVMaker extends Sprite 
{
	private var _webcam : Camera;
	private var _microphone : Microphone;
	private var _video : Video;
	private var _capture : Bitmap;
	
	private var _recordedMovie : Dictionary = new Dictionary ( true );
	private var _recordedMovieIndex : uint = 0;
	
	private var _recording : Boolean = false;
	
	/**
	  * @constructor
	  */
	public function FLVMaker ()
	{
		super ();
		
		if ( this.stage )
		{
			this._addedToStageHandler ();
		}
		else
		{
			this.addEventListener ( Event.ADDED_TO_STAGE, this._addedToStageHandler );
		}
	}

	/**
	  * Initialize stub.
	  */
	private function _addedToStageHandler ( event : Event = null ) : void
	{
		this.stage.scaleMode = StageScaleMode.NO_SCALE;
		this.stage.align = StageAlign.TOP_LEFT;
		
		this.stage.removeEventListener ( Event.ADDED_TO_STAGE, this._addedToStageHandler );
		
		this._webcam = Camera.getCamera ();
		if ( this._webcam == null ) 
		{
			// You need camera.
			return;
		}
		
		this._microphone = Microphone.getMicrophone ();
		if ( this._microphone == null ) 
		{
			// You need microphone.
			return;
		}
		
		this._video = new Video ( 320, 240 );
		this._video.attachCamera ( this._webcam );
		
		this._capture = new Bitmap ( new BitmapData ( 320, 240, false, 0 ), PixelSnapping.AUTO, true );
		this.addChild ( this._capture );
		
		this.addEventListener ( Event.ENTER_FRAME, this._enterFrameHandler, false, 0, true );
		
		setTimeout ( this._record, 3000 );
	}
	
	private function _enterFrameHandler ( event : Event ) : void
	{
		if ( this._recording )
		{
			this._capture.bitmapData.draw ( this._video );
			
			this._addFrame ();
			
			if ( this._recordedMovieIndex >= ( 30 * 5 ) )
			{
				this._stopRecord ();
			}
		}
	}
	
	private function _record () : void
	{
		this._recording = true;
	}
	
	private function _addFrame () : void
	{
		var bitmapData : BitmapData = new BitmapData ( 320, 240, false, 0 );
		bitmapData.draw ( this, new Matrix ( - 1, 0, 0, 1, 320, 0 ) );
		
		this._recordedMovie [ this._recordedMovieIndex ++ ] = bitmapData;
	}
	
	private function _stopRecord () : void
	{
		this._recording = false;
		this._createFile ();
	}
	
	private function _createFile () : void
	{
		FLVFile.createFile ( 320, 240, 30, ( ( this._recordedMovieIndex - 1 ) / 30 ) + 2 );
		
		var compressTimer : Timer = new Timer ( 1, this._recordedMovieIndex );
		compressTimer.addEventListener ( TimerEvent.TIMER, this._compressTimerHandler, false, 0, true );
		compressTimer.addEventListener ( TimerEvent.TIMER_COMPLETE, this._compressTimerCompleteHandler, false, 0, true );
		compressTimer.start ();
	}
	
	private function _compressTimerHandler ( event : TimerEvent ) : void
	{
		var index : uint = event.target.currentCount - 1;
		var bitmapData : BitmapData = this._recordedMovie [ index ] as BitmapData;
		
		if ( bitmapData )
		{
			if ( event.target.currentCount == event.target.repeatCount )
			{
				FLVFile.saveFrame ( bitmapData );
			}
			else
			{
				this._reduceColours ( bitmapData, index % 4 == 0 ? 128 : 96 );
				FLVFile.saveFrame ( bitmapData );
			}
		}
	}
	
	private function _compressTimerCompleteHandler ( event : TimerEvent ) : void
	{
		this._recordedMovieIndex = 0;
		this._recordedMovie = new Dictionary ( true );
		
		this._capture.bitmapData = new BitmapData ( 320, 240, false, 0xFF0000 );
		
		this.stage.addEventListener ( MouseEvent.CLICK, this._saveHandler );
	}
	
	private function _saveHandler ( event : MouseEvent ) : void
	{
		var fileReference : FileReference = new FileReference ();
		fileReference.save ( FLVFile.file, Math.floor ( Math.random () * uint.MAX_VALUE ) + ".flv" );
	}
	
	/**
	  * Remaps the color channel values in an image
	  * @param sourceBitmapData The input bitmap image to use.
	  * @param numColors Reducing the number of colors.
	  */
	private function _reduceColours ( sourceBitmapData : BitmapData, numColors : int = 256 ) : void
	{
		// Allowed values 0 - 256
		numColors = Math.max ( 0, Math.min ( numColors, 256 ) );

		var redArray : Array = new Array ( 256 );
		var greenArray : Array = new Array ( 256 );
		var blueArray : Array = new Array ( 256 );

		var n : Number = 256 / ( numColors / 3 );
		var i : uint;

		for ( i = 0; i < 256; i ++ )
		{
			blueArray [ i ] = Math.floor ( i / n ) * n;
			greenArray [ i ] = blueArray [ i ] << 8;
			redArray [ i ] = greenArray [ i ] << 8;
		}

		sourceBitmapData.paletteMap ( sourceBitmapData, sourceBitmapData.rect, new Point (), redArray, greenArray, blueArray );
	}
}

}
