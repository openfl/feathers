/*
Feathers
Copyright 2012-2015 Bowler Hat LLC. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.skins;
import feathers.core.PropertyProxy;
import feathers.data.DataProperties;
import openfl.errors.ArgumentError;
import openfl.utils.Dictionary;
import starling.display.Image;
import starling.textures.Texture;

/**
 * Values for each state are Texture instances, and the manager attempts to
 * reuse the existing Image instance that is passed in to getValueForState()
 * as the old value by swapping the texture.
 */
class ImageStateValueSelector extends StateWithToggleValueSelector
{

	public function new()
	{
		super();
	}

	/**
	 * @private
	 */
	private var _imageProperties:PropertyProxy;

	/**
	 * Optional properties to set on the Image instance.
	 *
	 * @see http://doc.starling-framework.org/core/starling/display/Image.html starling.display.Image
	 */
	public var imageProperties(get, set):PropertyProxy;

	public function get_imageProperties():PropertyProxy
	{
		if(this._imageProperties == null)
		{
			this._imageProperties = new PropertyProxy();
		}
		return this._imageProperties;
	}

	/**
	 * @private
	 */
	public function set_imageProperties(value:PropertyProxy):PropertyProxy
	{
		trace("FUNCTINON DISABLED************************");
		return new PropertyProxy();
		//return _imageProperties.storage == value..storage(value);
	}

	/**
	 * @private
	 */
	override public function setValueForState(value:Dynamic, state:Dynamic, isSelected:Bool = false):Void
	{
		if(!(Std.is(value, Texture)))
		{
			throw new ArgumentError("Value for state must be a Texture instance.");
		}
		super.setValueForState(value, state, isSelected);
	}

	/**
	 * @private
	 */
	override public function updateValue(target:Dynamic, state:Dynamic, oldValue:Dynamic = null):Dynamic
	{
		var texture:Texture = cast(super.updateValue(target, state),Texture);
		if(texture==null)
		{
			return null;
		}
		var image:Image;

		if(Std.is(oldValue, Image))
		{
			image = oldValue;
			image.texture = texture;
			image.readjustSize();
		}
		else
		{
			image = new Image(texture);
		}
		
		DataProperties.copyValuesFromDictionaryTo(_imageProperties.storage, image);
/*
		for (propertyName in this._imageProperties.storage)
		{
			var propertyValue:Dynamic = this._imageProperties.getProperty(propertyName);
			Reflect.setProperty(image,propertyName, propertyValue);
		}*/
		/*for (propertyName in value.storage.iterator()) {
				var propertyValue:Dynamic = value.storage.get(propertyName);
				Reflect.setProperty(newValue.storage, propertyName, propertyValue);
			}*/

		return image;
	}
}
