/*
Feathers
Copyright 2012-2015 Bowler Hat LLC. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.core;

import openfl.utils.Dictionary;
//#if 0
//import flash.utils.Proxy;
//import flash.utils.flash_proxy;
//#end

/**
 * Detects when its own properties have changed and dispatches an event
 * to notify listeners.
 *
 * <p>Supports nested <code>PropertyProxy</code> instances using attribute
 * <code>&#64;</code> notation. Placing an <code>&#64;</code> before a property name
 * is like saying, "If this nested <code>PropertyProxy</code> doesn't exist
 * yet, create one. If it does, use the existing one."</p>
 */
/*dynamic*/ @:final class PropertyProxy /* implements Dynamic*/
{
	/**
	 * Creates a <code>PropertyProxy</code> from a regular old <code>Object</code>.
	 */
	public static function fromObject(source:Dynamic, onChangeCallback:Dynamic = null):PropertyProxy
	{
	
		var newValue:PropertyProxy = new PropertyProxy(onChangeCallback);
		for(propertyName in Type.getInstanceFields(source))
		{
			
			Reflect.setProperty(newValue._storage, propertyName, Reflect.getProperty(source, propertyName));
		}
		return newValue;
	}

	/**
	 * Constructor.
	 */
	public function new(onChangeCallback:Dynamic = null)
	{
		if(onChangeCallback != null)
		{
			_onChangeCallbacks.push(onChangeCallback);
		}
		_storage = new Dictionary<String,Dynamic>();
		
	}

	/**
	 * @private
	 */
	private var _subProxyName:String;

	/**
	 * @private
	 */
	private var _onChangeCallbacks:Array<Dynamic> = new Array();

	/**
	 * @private
	 */
	private var _names:Array<String> = [];

	/**
	 * @private
	 */
	private var _storage:Dictionary<String,Dynamic> = new Dictionary<String,Dynamic>();
	public var storage(get, set):Dictionary<String,Dynamic>;
	
	@:noComplete private function get_storage():Dictionary<String,Dynamic>
	{
		return _storage;
	}
	
	@:noComplete private function set_storage(value:Dynamic):Dictionary<String,Dynamic>
	{
		for (propertyName in Reflect.fields(_storage))
		{
			if (!Reflect.hasField(value, propertyName))
				deleteProperty(propertyName);
		}
		for (propertyName in Reflect.fields(value))
			setProperty(propertyName, Reflect.field(value, propertyName));
		return _storage;
	}

	/**
	 * @private
	 */
	/*override flash_proxy*/ public function hasProperty(name:String):Bool
	{
		return this._storage.exists(name);
	}

	/**
	 * @private
	 */
	public function getProperty(nameAsString:String):Dynamic
	{
		
		if(!_storage.exists(nameAsString))
		{
			var subProxy:PropertyProxy = new PropertyProxy(subProxy_onChange);
			subProxy._subProxyName = nameAsString;
			_storage[nameAsString] = subProxy;
			_names[_names.length] = nameAsString;
			fireOnChangeCallback(nameAsString);
		}
		return _storage[nameAsString];
	
		
	}

	/**
	 * @private
	 */
	public function setProperty(nameAsString:String, value:Dynamic):Void
	{
		_storage[nameAsString]=value;
		if(_names.indexOf(nameAsString) < 0)
		{
			_names[_names.length] = nameAsString;
		}
		fireOnChangeCallback(nameAsString);
	}

	/**
	 * @private
	 */
	public function deleteProperty(name:String):Bool
	{
		//var nameAsString:String = Std.is(name, QName) ? QName(name).localName : name.toString();
		var nameAsString:String = name;
		var index:Int = this._names.indexOf(nameAsString);
		if(index == 0)
		{
			_names.shift();
		}
		else
		{
			var lastIndex:Int = _names.length - 1;
			if(index == lastIndex)
			{
				_names.pop();
			}
			else
			{
				_names.splice(index, 1);
			}
		}
		var result:Bool = _storage.remove(nameAsString);
		if(result)
		{
			fireOnChangeCallback(nameAsString);
		}
		return result;
	}

	/**
	 * @private
	 */
	/*override flash_proxy*/ function nextNameIndex(index:Int):Int
	{
		if(index < this._names.length)
		{
			return index + 1;
		}
		return 0;
	}

	/**
	 * @private
	 */
	/*override flash_proxy*/ function nextName(index:Int):String
	{
		return this._names[index - 1];
	}

	/**
	 * @private
	 */
	/*override flash_proxy*/ function nextValue(index:Int):Dynamic
	{
		var name:String = this._names[index - 1];
		return Reflect.field(this._storage, name);
	}

	/**
	 * Adds a callback to react to property changes.
	 */
	public function addOnChangeCallback(callback:Dynamic):Void
	{
		this._onChangeCallbacks[this._onChangeCallbacks.length] = callback;
	}

	/**
	 * Removes a callback.
	 */
	public function removeOnChangeCallback(callback:Dynamic):Void
	{
		var index:Int = this._onChangeCallbacks.indexOf(callback);
		if(index < 0)
		{
			return;
		}
		if(index == 0)
		{
			this._onChangeCallbacks.shift();
			return;
		}
		var lastIndex:Int = this._onChangeCallbacks.length - 1;
		if(index == lastIndex)
		{
			this._onChangeCallbacks.pop();
			return;
		}
		this._onChangeCallbacks.splice(index, 1);
	}

	/**
	 * @private
	 */
	private function toString():String
	{
		
		var result:String = "[object PropertyProxy ";
		for( propertyName in Reflect.fields(this.storage))
		{
			result += " " + propertyName + "=" + storage[propertyName];
		}
		return result + "]";
	}

	/**
	 * @private
	 */
	private function fireOnChangeCallback(forName:String):Void
	{
		var callbackCount:Int = this._onChangeCallbacks.length;
		
		for (i in 0...callbackCount)
		{
			var callback:Dynamic = this._onChangeCallbacks[i];
			//callback(this, forName);
			Reflect.callMethod(null, callback, [this, forName]);
		}
	}

	/**
	 * @private
	 */
	private function subProxy_onChange(proxy:PropertyProxy, name:String):Void
	{
		this.fireOnChangeCallback(proxy._subProxyName);
	}
}
