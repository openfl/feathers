package;

import feathers.examples.helloWorld.Main;

import openfl.display.Loader;
import openfl.display.Sprite;
import openfl.display.StageAlign;
// import openfl.display.StageOrientation;
import openfl.display.StageScaleMode;
import openfl.display3D.Context3DProfile;
import openfl.display3D.Context3DRenderMode;
import openfl.events.Event;
// import openfl.filesystem.File;
// import openfl.filesystem.FileMode;
// import openfl.filesystem.FileStream;
import openfl.geom.Rectangle;
import openfl.system.Capabilities;
import openfl.utils.ByteArray;

import starling.core.Starling;

class HelloWorld extends Sprite
{
	public function new()
	{
		super ();
		
		// var menu:ContextMenu = new ContextMenu();
		// menu.hideBuiltInItems();
		// this.contextMenu = menu;
		
		if(this.stage != null)
		{
			this.stage.scaleMode = StageScaleMode.NO_SCALE;
			this.stage.align = StageAlign.TOP_LEFT;
		}
		
		#if mobile
		this.mouseEnabled = this.mouseChildren = false;
		this.showLaunchImage();
		#end

		#if web
		//pretends to be an iPhone Retina screen
		DeviceCapabilities.dpi = 326;
		DeviceCapabilities.screenPixelWidth = 960;
		DeviceCapabilities.screenPixelHeight = 640;
		#end
		
		this.loaderInfo.addEventListener(Event.COMPLETE, loaderInfo_completeHandler);
	}

	private var _starling:Starling;
	private var _launchImage:Loader;
	private var _savedAutoOrients:Bool;

	private function showLaunchImage():Void
	{
		var filePath:String = null;
		var isPortraitOnly:Bool = false;
		if(Capabilities.manufacturer.indexOf("iOS") >= 0)
		{
			var isCurrentlyPortrait:Bool = true; //this.stage.orientation == StageOrientation.DEFAULT || this.stage.orientation == StageOrientation.UPSIDE_DOWN;
			if(Capabilities.screenResolutionX == 1242 && Capabilities.screenResolutionY == 2208)
			{
				//iphone 6 plus
				filePath = isCurrentlyPortrait ? "Default-414w-736h@3x.png" : "Default-414w-736h-Landscape@3x.png";
			}
			else if(Capabilities.screenResolutionX == 1536 && Capabilities.screenResolutionY == 2048)
			{
				//ipad retina
				filePath = isCurrentlyPortrait ? "Default-Portrait@2x.png" : "Default-Landscape@2x.png";
			}
			else if(Capabilities.screenResolutionX == 768 && Capabilities.screenResolutionY == 1024)
			{
				//ipad classic
				filePath = isCurrentlyPortrait ? "Default-Portrait.png" : "Default-Landscape.png";
			}
			else if(Capabilities.screenResolutionX == 750)
			{
				//iphone 6
				isPortraitOnly = true;
				filePath = "Default-375w-667h@2x.png";
			}
			else if(Capabilities.screenResolutionX == 640)
			{
				//iphone retina
				isPortraitOnly = true;
				if(Capabilities.screenResolutionY == 1136)
				{
					filePath = "Default-568h@2x.png";
				}
				else
				{
					filePath = "Default@2x.png";
				}
			}
			else if(Capabilities.screenResolutionX == 320)
			{
				//iphone classic
				isPortraitOnly = true;
				filePath = "Default.png";
			}
		}

		if(filePath != null)
		{
			#if sys
			if (sys.FileSystem.exists (filePath))
			{
				var bytes:ByteArray = ByteArray.fromFile (filePath);
				this._launchImage = new Loader();
				this._launchImage.loadBytes(bytes);
				this.addChild(this._launchImage);
				// this._savedAutoOrients = this.stage.autoOrients;
				// this.stage.autoOrients = false;
				if(isPortraitOnly)
				{
					// this.stage.setOrientation(StageOrientation.DEFAULT);
				}
			}
			#end
		}
	}
	
	private function start():Void
	{
		#if web
		this.gotoAndStop(2);
		this.graphics.clear();
		
		Starling.multitouchEnabled = true;
		var MainType:Class = getDefinitionByName("feathers.examples.helloWorld.Main") as Class;
		this._starling = new Starling(MainType, this.stage);
		this._starling.supportHighResolutions = true;
		this._starling.start();
		#else
		Starling.multitouchEnabled = true;
		this._starling = new Starling(Main, this.stage, null, null, Context3DRenderMode.AUTO, Context3DProfile.BASELINE);
		this._starling.supportHighResolutions = true;
		this._starling.start();
		#end
		
		if(this._launchImage != null)
		{
			this._starling.addEventListener("rootCreated", starling_rootCreatedHandler);
		}

		this.stage.addEventListener(Event.RESIZE, stage_resizeHandler, false, 0x7FFFFFFF /*int.MAX_VALUE*/, true);
		this.stage.addEventListener(Event.DEACTIVATE, stage_deactivateHandler, false, 0, true);
	}

	private function loaderInfo_completeHandler(event:Event):Void
	{
		this.start();
	}

	private function starling_rootCreatedHandler(event:Dynamic):Void
	{
		if(this._launchImage != null)
		{
			this.removeChild(this._launchImage);
			this._launchImage.unloadAndStop(true);
			this._launchImage = null;
			// this.stage.autoOrients = this._savedAutoOrients;
		}
	}

	private function stage_resizeHandler(event:Event):Void
	{
		this._starling.stage.stageWidth = this.stage.stageWidth;
		this._starling.stage.stageHeight = this.stage.stageHeight;

		var viewPort:Rectangle = this._starling.viewPort;
		viewPort.width = this.stage.stageWidth;
		viewPort.height = this.stage.stageHeight;
		try
		{
			this._starling.viewPort = viewPort;
		}
		catch(error:Dynamic) {}
	}

	private function stage_deactivateHandler(event:Event):Void
	{
		this._starling.stop(true);
		this.stage.addEventListener(Event.ACTIVATE, stage_activateHandler, false, 0, true);
	}

	private function stage_activateHandler(event:Event):Void
	{
		this.stage.removeEventListener(Event.ACTIVATE, stage_activateHandler);
		this._starling.start();
	}

}