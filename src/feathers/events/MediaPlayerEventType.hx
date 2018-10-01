/*
Feathers
Copyright 2012-2015 Bowler Hat LLC. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.events;
/**
 * Event <code>type</code> constants for Feathers media player controls.
 * This class is not a subclass of <code>starling.events.Event</code>
 * because these constants are meant to be used with
 * <code>dispatchEventWith()</code> and take advantage of the Starling's
 * event object pooling. The object passed to an event listener will be of
 * type <code>starling.events.Event</code>.
 * 
 * <listing version="3.0">
 * function listener( event:Event ):void
 * {
 *     trace( mediaPlayer.currentTime );
 * }
 * mediaPlayer.addEventListener( MediaPlayerEventType.CURRENT_TIME_CHANGE, listener );</listing>
 */
class MediaPlayerEventType
{
	/**
	 * Dispatched when a media player changes to the full-screen display mode
	 * or back to the normal display mode.
	 */
	inline public static var DISPLAY_STATE_CHANGE:String = "displayStageChange";

	/**
	 * Dispatched when a media player's playback state changes, such as when
	 * it begins playing or is paused.
	 */
	inline public static var PLAYBACK_STATE_CHANGE:String = "playbackStageChange";
	
	/**
	 * Dispatched when a media player's total playhead time changes.
	 */
	inline public static var TOTAL_TIME_CHANGE:String = "totalTimeChange";
	
	/**
	 * Dispatched when a media player's current playhead time changes.
	 */
	inline public static var CURRENT_TIME_CHANGE:String = "currentTimeChange";

	/**
	 * Dispatched when the original, native width or height of a video
	 * player's content is calculated.
	 */
	inline public static var DIMENSIONS_CHANGE:String = "dimensionsChange";

	/**
	 * Dispatched when a media player's sound transform is changed.
	 */
	inline public static var SOUND_TRANSFORM_CHANGE:String = "soundTransformChange";

	/**
	 * Dispatched periodically when a media player's content is loading to
	 * indicate the current progress.
	 */
	inline public static var LOAD_PROGRESS:String = "loadProgress";

	/**
	 * Dispatched when a media player's content is fully loaded and it
	 * may be played to completion without buffering.
	 */
	inline public static var LOAD_COMPLETE:String = "loadComplete";
}
