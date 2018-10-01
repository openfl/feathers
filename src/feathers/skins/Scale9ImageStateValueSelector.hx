/*
Feathers
Copyright 2012-2015 Bowler Hat LLC. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.skins;
import feathers.core.PropertyProxy;
import feathers.data.DataProperties;
import feathers.display.Scale9Image;
import feathers.textures.Scale9Textures;
import openfl.errors.ArgumentError;

/**
 * Values for each state are Scale9Textures instances, and the manager
 * attempts to reuse the existing Scale9Image instance that is passed in to
 * getValueForState() as the old value by swapping the textures.
 */

class Scale9ImageStateValueSelector extends StateWithToggleValueSelector
{
	
	public function new()
	{
		super();
	};

	private var _imageProperties:PropertyProxy;

	
	public var imageProperties(get, set):PropertyProxy;
	public function get_imageProperties():PropertyProxy
	{
		if(this._imageProperties==null)
		{
			this._imageProperties = new PropertyProxy();
		}
		return this._imageProperties;
	}

	
	public function set_imageProperties(value:PropertyProxy):PropertyProxy
	{
		trace("FUNCTINON DISABLED!");
		return new PropertyProxy();
		//this._imageProperties = value;
	}

	
	override public function setValueForState(value:Dynamic, state:Dynamic, isSelected:Bool = false):Void
	{
		if(!(Std.is(value, Scale9Textures)))
		{
			throw new ArgumentError("Value for state must be a Scale9Textures instance.");
		}
		super.setValueForState(value, state, isSelected);
	}

	
	override public function updateValue(target:Dynamic, state:Dynamic, oldValue:Dynamic = null):Dynamic
	{
		
	
		var textures:Scale9Textures = cast(super.updateValue(target, state),Scale9Textures);
		if (textures == null)
		{
			return null;
		}

		var image:Scale9Image;
		
		if(Std.is(oldValue, Scale9Image))
		{
			//trace("Scale 9 >>[B1]");
			image = cast(oldValue,Scale9Image);
			image.textures = textures;
			image.readjustSize();
		}
		else
		{
	
			image = new Scale9Image(textures);
		}
		
		DataProperties.copyValuesFromDictionaryTo(_imageProperties.storage, image);
		
		/*for (propertyName in this._imageProperties.storage)
		{
			var propertyValue:Dynamic = this._imageProperties.getProperty(propertyName);
			Reflect.setProperty(image, propertyName, propertyValue);
		}
	*/
		return image;
	}
}
