package feathers.data;
import feathers.core.PropertyProxy;
import openfl.utils.Dictionary;

/**
 * ...
 * @author Jaime Dominguez
 */
class DataProperties{

	public function new() {
		
	}
	
	
	public static function copyValuesFromDictionaryTo(srcObj:Dictionary<String, Dynamic>, destObj:Dynamic) {
		for (propertyName in srcObj.iterator()) {
			var propertyValue:Dynamic = srcObj.get(propertyName);
			Reflect.setProperty(destObj, propertyName, propertyValue);
		}	
	}
	
	public static function copyValuesFromObjectTo(srcObj:Dynamic, destObj:Dynamic) {
		if (Std.is(srcObj,Dictionary)==false){
			for (propertyName in Reflect.fields(srcObj)) {
				var propertyValue:Dynamic = srcObj.get(propertyName);
				Reflect.setProperty(destObj, propertyName, propertyValue);
			}	
		}else {
			copyValuesFromDictionaryTo(srcObj, destObj);
		}
	}
	
}