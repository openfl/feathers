/*
Feathers
Copyright 2012-2015 Bowler Hat LLC. All Rights Reserved.

This program is free software. You can redistribute and/or modify it in
accordance with the terms of the accompanying license agreement.
*/
package feathers.controls.supportClasses;
import feathers.controls.List;
import feathers.controls.Scroller;
import feathers.controls.renderers.DefaultListItemRenderer;
import feathers.controls.renderers.IListItemRenderer;
import feathers.core.FeathersControl;
import feathers.core.IFeathersControl;
import feathers.core.PropertyProxy;
import feathers.data.DataProperties;
import feathers.data.ListCollection;
import feathers.events.CollectionEventType;
import feathers.events.FeathersEventType;
import feathers.layout.ILayout;
import feathers.layout.ITrimmedVirtualLayout;
import feathers.layout.IVariableVirtualLayout;
import feathers.layout.IVirtualLayout;
import feathers.layout.LayoutBoundsResult;
import feathers.layout.ViewPortBounds;
import feathers.utils.type.ArrayUtil;
import feathers.utils.type.UnionMap;
import feathers.utils.type.UnionWeakMap;
import feathers.utils.type.SafeCast.safe_cast;
import haxe.ds.WeakMap;
#if 0
import openfl.utils.Object;
#end
import starling.core.RenderSupport;

import openfl.errors.ArgumentError;
import openfl.errors.IllegalOperationError;
import openfl.geom.Point;
#if 0
import openfl.utils.Dictionary;
#end

import starling.display.DisplayObject;
import starling.events.Event;
import starling.events.EventDispatcher;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;

import feathers.core.FeathersControl.INVALIDATION_FLAG_LAYOUT;

/**
 * @private
 * Used internally by List. Not meant to be used on its own.
 */
class ListDataViewPort extends FeathersControl implements IViewPort
{
	inline private static var INVALIDATION_FLAG_ITEM_RENDERER_FACTORY:String = "itemRendererFactory";

	private static var HELPER_POINT:Point = new Point();
	private static var HELPER_VECTOR:Array<Int> = new Array();

	public function new()
	{
		super();
		addEventListener(Event.REMOVED_FROM_STAGE, removedFromStageHandler);
		addEventListener(TouchEvent.TOUCH, touchHandler);
	}

	private var touchPointID:Int = -1;

	private var _viewPortBounds:ViewPortBounds = new ViewPortBounds();

	private var _layoutResult:LayoutBoundsResult = new LayoutBoundsResult();

	private var _minVisibleWidth:Float = 0;

	public var minVisibleWidth(get, set):Float;
	public function get_minVisibleWidth():Float
	{
		return _minVisibleWidth;
	}

	public function set_minVisibleWidth(value:Float):Float
	{
		if(_minVisibleWidth == value)
		{
			return _minVisibleWidth;
		}
		if(value != value) //isNaN
		{
			throw new ArgumentError("minVisibleWidth cannot be NaN");
		}
		_minVisibleWidth = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		return _minVisibleWidth;
	}

	private var _maxVisibleWidth:Float = Math.POSITIVE_INFINITY;

	public var maxVisibleWidth(get, set):Float;
	public function get_maxVisibleWidth():Float
	{
		return _maxVisibleWidth;
	}

	public function set_maxVisibleWidth(value:Float):Float
	{
		if(_maxVisibleWidth == value)
		{
			return _maxVisibleWidth;
		}
		if(value != value) //isNaN
		{
			throw new ArgumentError("maxVisibleWidth cannot be NaN");
		}
		_maxVisibleWidth = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		return _maxVisibleWidth;
	}

	private var actualVisibleWidth:Float = 0;

	private var explicitVisibleWidth:Float = Math.NaN;

	public var visibleWidth(get, set):Float;
	public function get_visibleWidth():Float
	{
		return actualVisibleWidth;
	}

	public function set_visibleWidth(value:Float):Float
	{
		if(explicitVisibleWidth == value ||
			(value != value && explicitVisibleWidth != explicitVisibleWidth)) //isNaN
		{
			return actualVisibleWidth;
		}
		explicitVisibleWidth = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		return actualVisibleWidth;
	}

	private var _minVisibleHeight:Float = 0;

	public var minVisibleHeight(get, set):Float;
	public function get_minVisibleHeight():Float
	{
		return _minVisibleHeight;
	}

	public function set_minVisibleHeight(value:Float):Float
	{
		if(_minVisibleHeight == value)
		{
			return _minVisibleHeight;
		}
		if(value != value) //isNaN
		{
			throw new ArgumentError("minVisibleHeight cannot be NaN");
		}
		_minVisibleHeight = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		return _minVisibleHeight;
	}

	private var _maxVisibleHeight:Float = Math.POSITIVE_INFINITY;

	public var maxVisibleHeight(get, set):Float;
	public function get_maxVisibleHeight():Float
	{
		return _maxVisibleHeight;
	}

	public function set_maxVisibleHeight(value:Float):Float
	{
		if(_maxVisibleHeight == value)
		{
			return _maxVisibleHeight;
		}
		if(value != value) //isNaN
		{
			throw new ArgumentError("maxVisibleHeight cannot be NaN");
		}
		_maxVisibleHeight = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		return _maxVisibleHeight;
	}

	private var actualVisibleHeight:Float = 0;

	private var explicitVisibleHeight:Float = Math.NaN;

	public var visibleHeight(get, set):Float;
	public function get_visibleHeight():Float
	{
		return actualVisibleHeight;
	}

	public function set_visibleHeight(value:Float):Float
	{
		if(explicitVisibleHeight == value ||
			(value != value && explicitVisibleHeight != explicitVisibleHeight)) //isNaN
		{
			return actualVisibleHeight;
		}
		explicitVisibleHeight = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_SIZE);
		return actualVisibleHeight;
	}

	private var _contentX:Float = 0;

	public var contentX(get, never):Float;
	public function get_contentX():Float
	{
		return _contentX;
	}

	private var _contentY:Float = 0;

	public var contentY(get, never):Float;
	public function get_contentY():Float
	{
		return _contentY;
	}

	private var _typicalItemIsInDataProvider:Bool = false;
	private var _typicalItemRenderer:IListItemRenderer;
	private var _unrenderedData:Array<Dynamic> = [];
	private var _layoutItems:Array<DisplayObject> = new Array<DisplayObject>();
	private var _inactiveRenderers:Array<IListItemRenderer> = new Array<IListItemRenderer>();
	private var _activeRenderers:Array<IListItemRenderer> = new Array<IListItemRenderer>();
	private var _rendererMap:UnionWeakMap<IListItemRenderer> = new feathers.utils.type.UnionWeakMap();
	private var _minimumItemCount:Int;

	private var _layoutIndexOffset:Int = 0;

	private var _isScrolling:Bool = false;

	private var _owner:List;

	public var owner(get, set):List;
	public function get_owner():List
	{
		return _owner;
	}

	public function set_owner(value:List):List
	{
		if(_owner == value)
		{
			return _owner;
		}
		if(_owner != null)
		{
			_owner.removeEventListener(FeathersEventType.SCROLL_START, owner_scrollStartHandler);
		}
		_owner = value;
		if(_owner != null)
		{
			_owner.addEventListener(FeathersEventType.SCROLL_START, owner_scrollStartHandler);
		}
		return _owner;
	}

	private var _updateForDataReset:Bool = false;

	private var _dataProvider:ListCollection;

	public var dataProvider(get, set):ListCollection;
	public function get_dataProvider():ListCollection
	{
		return _dataProvider;
	}

	public function set_dataProvider(value:ListCollection):ListCollection
	{
		if(_dataProvider == value)
		{
			return _dataProvider;
		}
		if(_dataProvider != null)
		{
			_dataProvider.removeEventListener(Event.CHANGE, dataProvider_changeHandler);
			_dataProvider.removeEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
			_dataProvider.removeEventListener(CollectionEventType.ADD_ITEM, dataProvider_addItemHandler);
			_dataProvider.removeEventListener(CollectionEventType.REMOVE_ITEM, dataProvider_removeItemHandler);
			_dataProvider.removeEventListener(CollectionEventType.REPLACE_ITEM, dataProvider_replaceItemHandler);
			_dataProvider.removeEventListener(CollectionEventType.UPDATE_ITEM, dataProvider_updateItemHandler);
		}
		_dataProvider = value;
		if(_dataProvider != null)
		{
			_dataProvider.addEventListener(Event.CHANGE, dataProvider_changeHandler);
			_dataProvider.addEventListener(CollectionEventType.RESET, dataProvider_resetHandler);
			_dataProvider.addEventListener(CollectionEventType.ADD_ITEM, dataProvider_addItemHandler);
			_dataProvider.addEventListener(CollectionEventType.REMOVE_ITEM, dataProvider_removeItemHandler);
			_dataProvider.addEventListener(CollectionEventType.REPLACE_ITEM, dataProvider_replaceItemHandler);
			_dataProvider.addEventListener(CollectionEventType.UPDATE_ITEM, dataProvider_updateItemHandler);
		}
		if(Std.is(_layout, IVariableVirtualLayout))
		{
			cast(_layout, IVariableVirtualLayout).resetVariableVirtualCache();
		}
		_updateForDataReset = true;
		invalidate(FeathersControl.INVALIDATION_FLAG_DATA);
		return _dataProvider;
	}

	private var _itemRendererType:Class<Dynamic>;

	public var itemRendererType(get, set):Class<Dynamic>;
	public function get_itemRendererType():Class<Dynamic>
	{
		return _itemRendererType;
	}

	public function set_itemRendererType(value:Class<Dynamic>):Class<Dynamic>
	{
		if(_itemRendererType == value)
		{
			return _itemRendererType;
		}

		_itemRendererType = value;
		invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		return _itemRendererType;
	}

	private var _itemRendererFactory:Void->IListItemRenderer;

	public var itemRendererFactory(get, set):Void->IListItemRenderer;
	public function get_itemRendererFactory():Void->IListItemRenderer
	{
		return _itemRendererFactory;
	}

	public function set_itemRendererFactory(value:Void->IListItemRenderer):Void->IListItemRenderer
	{
		if(_itemRendererFactory == value)
		{
			return _itemRendererFactory;
		}

		_itemRendererFactory = value;
		invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		return _itemRendererFactory;
	}

	private var _customItemRendererStyleName:String;

	public var customItemRendererStyleName(get, set):String;
	public function get_customItemRendererStyleName():String
	{
		return _customItemRendererStyleName;
	}

	public function set_customItemRendererStyleName(value:String):String
	{
		if(_customItemRendererStyleName == value)
		{
			return get_customItemRendererStyleName();
		}
		_customItemRendererStyleName = value;
		invalidate(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		return get_customItemRendererStyleName();
	}

	private var _typicalItem:Dynamic = null;

	public var typicalItem(get, set):Dynamic;
	public function get_typicalItem():Dynamic
	{
		return _typicalItem;
	}

	public function set_typicalItem(value:Dynamic):Dynamic
	{
		if(_typicalItem == value)
		{
			return _typicalItem;
		}
		_typicalItem = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_DATA);
		return _typicalItem;
	}

	private var _itemRendererProperties:PropertyProxy;

	public var itemRendererProperties(get, set):PropertyProxy;
	public function get_itemRendererProperties():PropertyProxy
	{
		return _itemRendererProperties;
	}

	public function set_itemRendererProperties(value:PropertyProxy):PropertyProxy
	{
		if(_itemRendererProperties == value)
		{
			return _itemRendererProperties;
		}
		if(_itemRendererProperties != null)
		{
			_itemRendererProperties.removeOnChangeCallback(childProperties_onChange);
		}
		_itemRendererProperties = value;
		if(_itemRendererProperties != null)
		{
			_itemRendererProperties.addOnChangeCallback(childProperties_onChange);
		}
		invalidate(FeathersControl.INVALIDATION_FLAG_STYLES);
		return _itemRendererProperties;
	}

	private var _ignoreLayoutChanges:Bool = false;
	private var _ignoreRendererResizing:Bool = false;

	private var _layout:ILayout;

	public var layout(get, set):ILayout;
	public function get_layout():ILayout
	{
		return _layout;
	}

	public function set_layout(value:ILayout):ILayout
	{
		if(_layout == value)
		{
			return get_layout();
		}
		if(_layout != null)
		{
			cast(_layout, EventDispatcher).removeEventListener(Event.CHANGE, layout_changeHandler);
		}
		_layout = value;
		if(_layout != null)
		{
			if(Std.is(_layout, IVariableVirtualLayout))
			{
				cast(_layout, IVariableVirtualLayout).resetVariableVirtualCache();
			}
			cast(_layout, EventDispatcher).addEventListener(Event.CHANGE, layout_changeHandler);
		}
		invalidate(FeathersControl.INVALIDATION_FLAG_LAYOUT);
		return get_layout();
	}

	public var horizontalScrollStep(get, never):Float;
	public function get_horizontalScrollStep():Float
	{
		if(_activeRenderers.length == 0)
		{
			return 0;
		}
		var itemRenderer:IListItemRenderer = _activeRenderers[0];
		var itemRendererWidth:Float = itemRenderer.width;
		var itemRendererHeight:Float = itemRenderer.height;
		if(itemRendererWidth < itemRendererHeight)
		{
			return itemRendererWidth;
		}
		return itemRendererHeight;
	}

	public var verticalScrollStep(get, never):Float;
	public function get_verticalScrollStep():Float
	{
		if(_activeRenderers.length == 0)
		{
			return 0;
		}
		var itemRenderer:IListItemRenderer = _activeRenderers[0];
		var itemRendererWidth:Float = itemRenderer.width;
		var itemRendererHeight:Float = itemRenderer.height;
		if(itemRendererWidth < itemRendererHeight)
		{
			return itemRendererWidth;
		}
		return itemRendererHeight;
	}

	private var _horizontalScrollPosition:Float = 0;

	public var horizontalScrollPosition(get, set):Float;
	public function get_horizontalScrollPosition():Float
	{
		return _horizontalScrollPosition;
	}

	public function set_horizontalScrollPosition(value:Float):Float
	{
		if(_horizontalScrollPosition == value)
		{
			return _horizontalScrollPosition;
		}
		_horizontalScrollPosition = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_SCROLL);
		return _horizontalScrollPosition;
	}

	private var _verticalScrollPosition:Float = 0;

	public var verticalScrollPosition(get, set):Float;
	public function get_verticalScrollPosition():Float
	{
		return _verticalScrollPosition;
	}

	public function set_verticalScrollPosition(value:Float):Float
	{
		if(_verticalScrollPosition == value)
		{
			return _verticalScrollPosition;
		}
		_verticalScrollPosition = value;
		invalidate(FeathersControl.INVALIDATION_FLAG_SCROLL);
		return _verticalScrollPosition;
	}

	private var _ignoreSelectionChanges:Bool = false;

	private var _isSelectable:Bool = true;

	public var isSelectable(get, set):Bool;
	public function get_isSelectable():Bool
	{
		return _isSelectable;
	}

	public function set_isSelectable(value:Bool):Bool
	{
		if(_isSelectable == value)
		{
			return _isSelectable;
		}
		_isSelectable = value;
		if(!value)
		{
			selectedIndices = null;
		}
		return _isSelectable;
	}

	private var _allowMultipleSelection:Bool = false;

	public var allowMultipleSelection(get, set):Bool;
	public function get_allowMultipleSelection():Bool
	{
		return _allowMultipleSelection;
	}

	public function set_allowMultipleSelection(value:Bool):Bool
	{
		return _allowMultipleSelection = value;
	}

	private var _selectedIndices:ListCollection;

	public var selectedIndices(get, set):ListCollection;
	public function get_selectedIndices():ListCollection
	{
		return _selectedIndices;
	}

	public function set_selectedIndices(value:ListCollection):ListCollection
	{
		if(_selectedIndices == value)
		{
			return _selectedIndices;
		}
		if(_selectedIndices != null)
		{
			_selectedIndices.removeEventListener(Event.CHANGE, selectedIndices_changeHandler);
		}
		_selectedIndices = value;
		if(_selectedIndices != null)
		{
			_selectedIndices.addEventListener(Event.CHANGE, selectedIndices_changeHandler);
		}
		invalidate(FeathersControl.INVALIDATION_FLAG_SELECTED);
		return _selectedIndices;
	}

	public function getScrollPositionForIndex(index:Int, result:Point = null):Point
	{
		if(result == null)
		{
			result = new Point();
		}
		return _layout.getScrollPositionForIndex(index, _layoutItems,
			0, 0, actualVisibleWidth, actualVisibleHeight, result);
	}

	public function getNearestScrollPositionForIndex(index:Int, result:Point = null):Point
	{
		if(result == null)
		{
			result = new Point();
		}
		return _layout.getNearestScrollPositionForIndex(index,
			_horizontalScrollPosition, _verticalScrollPosition,
			_layoutItems, 0, 0, actualVisibleWidth, actualVisibleHeight, result);
	}

	override public function dispose():Void
	{
		owner = null;
		layout = null;
		dataProvider = null;
		super.dispose();
	}

	override private function draw():Void
	{
		var dataInvalid:Bool = isInvalid(FeathersControl.INVALIDATION_FLAG_DATA);
		var scrollInvalid:Bool = isInvalid(FeathersControl.INVALIDATION_FLAG_SCROLL);
		var sizeInvalid:Bool = isInvalid(FeathersControl.INVALIDATION_FLAG_SIZE);
		var selectionInvalid:Bool = isInvalid(FeathersControl.INVALIDATION_FLAG_SELECTED);
		var itemRendererInvalid:Bool = isInvalid(INVALIDATION_FLAG_ITEM_RENDERER_FACTORY);
		var stylesInvalid:Bool = isInvalid(FeathersControl.INVALIDATION_FLAG_STYLES);
		var stateInvalid:Bool = isInvalid(FeathersControl.INVALIDATION_FLAG_STATE);
		var layoutInvalid:Bool = isInvalid(FeathersControl.INVALIDATION_FLAG_LAYOUT);

		//scrolling only affects the layout is requiresLayoutOnScroll is true
		if(!layoutInvalid && scrollInvalid && _layout != null && _layout.requiresLayoutOnScroll)
		{
			layoutInvalid = true;
		}

		var basicsInvalid:Bool = sizeInvalid || dataInvalid || layoutInvalid || itemRendererInvalid;

		var oldIgnoreRendererResizing:Bool = _ignoreRendererResizing;
		_ignoreRendererResizing = true;
		var oldIgnoreLayoutChanges:Bool = _ignoreLayoutChanges;
		_ignoreLayoutChanges = true;

		if(scrollInvalid || sizeInvalid)
		{
			refreshViewPortBounds();
		}
		if(basicsInvalid)
		{
			refreshInactiveRenderers(itemRendererInvalid);
		}
		if(dataInvalid || layoutInvalid || itemRendererInvalid)
		{
			refreshLayoutTypicalItem();
		}
		if(basicsInvalid)
		{
			refreshRenderers();
		}
		if(stylesInvalid || basicsInvalid)
		{
			refreshItemRendererStyles();
		}
		if(selectionInvalid || basicsInvalid)
		{
			//unlike resizing renderers and layout changes, we only want to
			//stop listening for selection changes when we're forcibly
			//updating selection. other property changes on item renderers
			//can validly change selection, and we need to detect that.
			var oldIgnoreSelectionChanges:Bool = _ignoreSelectionChanges;
			_ignoreSelectionChanges = true;
			refreshSelection();
			_ignoreSelectionChanges = oldIgnoreSelectionChanges;
		}
		if(stateInvalid || basicsInvalid)
		{
			refreshEnabled();
		}
		_ignoreLayoutChanges = oldIgnoreLayoutChanges;

		if(stateInvalid || selectionInvalid || stylesInvalid || basicsInvalid)
		{
			_layout.layout(_layoutItems, _viewPortBounds, _layoutResult);
		}

		_ignoreRendererResizing = oldIgnoreRendererResizing;

		_contentX = _layoutResult.contentX;
		_contentY = _layoutResult.contentY;
		setSizeInternal(_layoutResult.contentWidth, _layoutResult.contentHeight, false);
		actualVisibleWidth = _layoutResult.viewPortWidth;
		actualVisibleHeight = _layoutResult.viewPortHeight;

		//final validation to avoid juggler next frame issues
		validateItemRenderers();
	}

	private function invalidateParent(flag:String = FeathersControl.INVALIDATION_FLAG_ALL):Void
	{
		cast(parent, Scroller).invalidate(flag);
	}

	private function validateItemRenderers():Void
	{
		var rendererCount:Int = _activeRenderers.length;
		for(i in 0 ... rendererCount)
		{
			var renderer:IListItemRenderer = _activeRenderers[i];
			renderer.validate();
		}
	}

	private function refreshLayoutTypicalItem():Void
	{
		var virtualLayout:IVirtualLayout = cast(_layout, IVirtualLayout);
		if(virtualLayout == null || !virtualLayout.useVirtualLayout)
		{
			//the old layout was virtual, but this one isn't
			if(!_typicalItemIsInDataProvider && _typicalItemRenderer != null)
			{
				//it's safe to destroy this renderer
				destroyRenderer(_typicalItemRenderer);
				_typicalItemRenderer = null;
			}
			return;
		}
		var typicalItemIndex:Int = 0;
		var newTypicalItemIsInDataProvider:Bool = false;
		var typicalItem:Dynamic = _typicalItem;
		if(typicalItem != null)
		{
			if(_dataProvider != null)
			{
				typicalItemIndex = _dataProvider.getItemIndex(typicalItem);
				newTypicalItemIsInDataProvider = typicalItemIndex >= 0;
			}
			if(typicalItemIndex < 0)
			{
				typicalItemIndex = 0;
			}
		}
		else
		{
			newTypicalItemIsInDataProvider = true;
			if(_dataProvider != null && _dataProvider.length > 0)
			{
				typicalItem = _dataProvider.getItemAt(0);
			}
		}

		var typicalRenderer:IListItemRenderer = null;
		if(typicalItem != null)
		{
			typicalRenderer = _rendererMap.get(typicalItem);
			if(typicalRenderer != null)
			{
				//the index may have changed if items were added, removed or
				//reordered in the data provider
				typicalRenderer.index = typicalItemIndex;
			}
			if(typicalRenderer == null && _typicalItemRenderer != null)
			{
				//we can reuse the typical item renderer if the old typical item
				//wasn't in the data provider.
				var canReuse:Bool = !_typicalItemIsInDataProvider;
				if(!canReuse)
				{
					//we can also reuse the typical item renderer if the old
					//typical item was in the data provider, but it isn't now.
					canReuse = _dataProvider.getItemIndex(_typicalItemRenderer.data) < 0;
				}
				if(canReuse)
				{
					//if the old typical item was in the data provider, remove
					//it from the renderer map.
					if(_typicalItemIsInDataProvider)
					{
						_rendererMap.remove(_typicalItemRenderer.data);
					}
					typicalRenderer = _typicalItemRenderer;
					typicalRenderer.data = typicalItem;
					typicalRenderer.index = typicalItemIndex;
					//if the new typical item is in the data provider, add it
					//to the renderer map.
					if(newTypicalItemIsInDataProvider)
					{
						_rendererMap.set(typicalItem, typicalRenderer);
					}
				}
			}
			if(typicalRenderer == null)
			{
				//if we still don't have a typical item renderer, we need to
				//create a new one.
				typicalRenderer = createRenderer(typicalItem, typicalItemIndex, false, !newTypicalItemIsInDataProvider);
				if(!_typicalItemIsInDataProvider && _typicalItemRenderer != null)
				{
					//get rid of the old typical item renderer if it isn't
					//needed anymore.  since it was not in the data provider, we
					//don't need to mess with the renderer map dictionary.
					destroyRenderer(_typicalItemRenderer);
					_typicalItemRenderer = null;
				}
			}
		}

		virtualLayout.typicalItem = safe_cast(typicalRenderer, DisplayObject);
		_typicalItemRenderer = typicalRenderer;
		_typicalItemIsInDataProvider = newTypicalItemIsInDataProvider;
		if(_typicalItemRenderer != null && !_typicalItemIsInDataProvider)
		{
			//we need to know if this item renderer resizes to adjust the
			//layout because the layout may use this item renderer to resize
			//the other item renderers
			_typicalItemRenderer.addEventListener(FeathersEventType.RESIZE, renderer_resizeHandler);
		}
	}

	private function refreshItemRendererStyles():Void
	{
		for (renderer in _activeRenderers)
		{
			refreshOneItemRendererStyles(renderer);
		}
	}

	private function refreshOneItemRendererStyles(renderer:IListItemRenderer):Void
	{
		if (_itemRendererProperties == null)
			return;
			
		var displayRenderer:DisplayObject = cast(renderer, DisplayObject);
		DataProperties.copyValuesFromDictionaryTo(_itemRendererProperties.storage, displayRenderer);
		/*
		for (propertyName in _itemRendererProperties.storage.iterator()) {
			var propertyValue:Dynamic = _itemRendererProperties.storage.get(propertyName);
			Reflect.setProperty(displayRenderer, propertyName, propertyValue);
		}*/
	}

	private function refreshSelection():Void
	{
		var rendererCount:Int = _activeRenderers.length;
		for(i in 0 ... rendererCount)
		{
			var renderer:IListItemRenderer = _activeRenderers[i];
			renderer.isSelected = _selectedIndices.getItemIndex(renderer.index) >= 0;
		}
	}

	private function refreshEnabled():Void
	{
		var rendererCount:Int = _activeRenderers.length;
		for(i in 0...rendererCount)
		{
			var itemRenderer:IFeathersControl = cast(_activeRenderers[i], IFeathersControl);
			itemRenderer.isEnabled = _isEnabled;
		}
	}

	private function refreshViewPortBounds():Void
	{
		_viewPortBounds.x = _viewPortBounds.y = 0;
		_viewPortBounds.scrollX = _horizontalScrollPosition;
		_viewPortBounds.scrollY = _verticalScrollPosition;
		_viewPortBounds.explicitWidth = explicitVisibleWidth;
		_viewPortBounds.explicitHeight = explicitVisibleHeight;
		_viewPortBounds.minWidth = _minVisibleWidth;
		_viewPortBounds.minHeight = _minVisibleHeight;
		_viewPortBounds.maxWidth = _maxVisibleWidth;
		_viewPortBounds.maxHeight = _maxVisibleHeight;
	}

	private function refreshInactiveRenderers(itemRendererTypeIsInvalid:Bool):Void
	{
		var temp:Array<IListItemRenderer> = _inactiveRenderers;
		_inactiveRenderers = _activeRenderers;
		_activeRenderers = temp;
		
		if(_activeRenderers.length > 0)
		{
			if (_activeRenderers[0] !=null){
				throw new IllegalOperationError("ListDataViewPort: active renderers should be empty.");
			}else {
			
				_activeRenderers = new Array<IListItemRenderer>();
			}
		}
		
		if(itemRendererTypeIsInvalid)
		{
			recoverInactiveRenderers();
			freeInactiveRenderers(false);
			if(_typicalItemRenderer != null)
			{
				if(_typicalItemIsInDataProvider)
				{
					_rendererMap.remove(_typicalItemRenderer.data);
				}
				destroyRenderer(_typicalItemRenderer);
				_typicalItemRenderer = null;
				_typicalItemIsInDataProvider = false;
			}
		}
		
		_layoutItems.splice(0, _layoutItems.length);
		
	}

	private function refreshRenderers():Void
	{
		if(_typicalItemRenderer != null)
		{
			if(_typicalItemIsInDataProvider)
			{
				//this renderer is already is use by the typical item, so we
				//don't want to allow it to be used by other items.
				var inactiveIndex:Int = _inactiveRenderers.indexOf(_typicalItemRenderer);
				if(inactiveIndex >= 0)
				{
					_inactiveRenderers[inactiveIndex] = null;
				}
				//if refreshLayoutTypicalItem() was called, it will have already
				//added the typical item renderer to the active renderers. if
				//not, we need to do it here.
				var activeRendererCount:Int = _activeRenderers.length;
				if(activeRendererCount == 0)
				{
					_activeRenderers[activeRendererCount] = _typicalItemRenderer;
				}
			}
			//we need to set the typical item renderer's properties here
			//because they may be needed for proper measurement in a virtual
			//layout.
			refreshOneItemRendererStyles(_typicalItemRenderer);
		}

		findUnrenderedData();
		recoverInactiveRenderers();
		renderUnrenderedData();
		freeInactiveRenderers(true);
		_updateForDataReset = false;
	}

	private function findUnrenderedData():Void
	{
		var itemCount:Int = _dataProvider != null ? _dataProvider.length : 0;
		var virtualLayout:IVirtualLayout = cast(_layout, IVirtualLayout);
		var useVirtualLayout:Bool = virtualLayout != null && virtualLayout.useVirtualLayout;
		if(useVirtualLayout)
		{
			virtualLayout.measureViewPort(itemCount, _viewPortBounds, HELPER_POINT);
			virtualLayout.getVisibleIndicesAtScrollPosition(_horizontalScrollPosition, _verticalScrollPosition, HELPER_POINT.x, HELPER_POINT.y, itemCount, HELPER_VECTOR);
		}

		var unrenderedItemCount:Int = useVirtualLayout ? HELPER_VECTOR.length : itemCount;
		if(useVirtualLayout && _typicalItemIsInDataProvider && _typicalItemRenderer != null &&
			HELPER_VECTOR.indexOf(_typicalItemRenderer.index) >= 0)
		{
			//add an extra item renderer if the typical item is from the
			//data provider and it is visible. this helps keep the number of
			//item renderers constant!
			_minimumItemCount = unrenderedItemCount + 1;
		}
		else
		{
			_minimumItemCount = unrenderedItemCount;
		}
		var canUseBeforeAndAfter:Bool = Std.is(_layout, ITrimmedVirtualLayout) && useVirtualLayout &&
			(!Std.is(_layout, IVariableVirtualLayout) || !cast(_layout, IVariableVirtualLayout).hasVariableItemDimensions) &&
			unrenderedItemCount > 0;
		var index:Int;
		if(canUseBeforeAndAfter)
		{
			var minIndex:Int = HELPER_VECTOR[0];
			var maxIndex:Int = minIndex;
			for(i in 1 ... unrenderedItemCount)
			{
				index = HELPER_VECTOR[i];
				if(index < minIndex)
				{
					minIndex = index;
				}
				if(index > maxIndex)
				{
					maxIndex = index;
				}
			}
			var beforeItemCount:Int = minIndex - 1;
			if(beforeItemCount < 0)
			{
				beforeItemCount = 0;
			}
			var afterItemCount:Int = itemCount - 1 - maxIndex;
			var sequentialVirtualLayout:ITrimmedVirtualLayout = cast(_layout, ITrimmedVirtualLayout);
			sequentialVirtualLayout.beforeVirtualizedItemCount = beforeItemCount;
			sequentialVirtualLayout.afterVirtualizedItemCount = afterItemCount;
			ArrayUtil.resize(_layoutItems, itemCount - beforeItemCount - afterItemCount);
			_layoutIndexOffset = -beforeItemCount;
		}
		else
		{
			_layoutIndexOffset = 0;
			ArrayUtil.resize(_layoutItems, itemCount);
		}

		var activeRenderersLastIndex:Int = _activeRenderers.length;
		var unrenderedDataLastIndex:Int = _unrenderedData.length;
		for(i in 0 ... unrenderedItemCount)
		{
			index = useVirtualLayout ? HELPER_VECTOR[i] : i;
			if(index < 0 || index >= itemCount)
			{
				continue;
			}
			var item:Dynamic = _dataProvider.getItemAt(index);
			var renderer:IListItemRenderer = safe_cast(_rendererMap.get(item), IListItemRenderer);
			if(renderer != null)
			{
				//the index may have changed if items were added, removed or
				//reordered in the data provider
				renderer.index = index;
				//if this item renderer used to be the typical item
				//renderer, but it isn't anymore, it may have been set invisible!
				renderer.visible = true;
				if(_updateForDataReset)
				{
					//similar to calling updateItemAt(), replacing the data
					//provider or resetting its source means that we should
					//trick the item renderer into thinking it has new data.
					//many developers seem to expect this behavior, so while
					//it's not the most optimal for performance, it saves on
					//support time in the forums. thankfully, it's still
					//somewhat optimized since the same item renderer will
					//receive the same data, and the children generally
					//won't have changed much, if at all.
					renderer.data = null;
					renderer.data = item;

				}

				//the typical item renderer is a special case, and we will
				//have already put it into the active renderers, so we don't
				//want to do it again!
				if(_typicalItemRenderer != renderer)
				{
					_activeRenderers[activeRenderersLastIndex] = renderer;
					activeRenderersLastIndex++;
					var inactiveIndex:Int = _inactiveRenderers.indexOf(renderer);
					if(inactiveIndex >= 0)
					{
						_inactiveRenderers[inactiveIndex] = null;
					}
					else
					{
						throw new IllegalOperationError("ListDataViewPort: renderer map contains bad data.");
					}
				}
				_layoutItems[index + _layoutIndexOffset] = cast(renderer, DisplayObject);
			}
			else
			{
				_unrenderedData[unrenderedDataLastIndex] = item;
				unrenderedDataLastIndex++;
			}
		}
		//update the typical item renderer's visibility
		if(_typicalItemRenderer != null)
		{
			if(useVirtualLayout && _typicalItemIsInDataProvider)
			{
				index = HELPER_VECTOR.indexOf(_typicalItemRenderer.index);
				if(index >= 0)
				{
					_typicalItemRenderer.visible = true;
				}
				else
				{
					_typicalItemRenderer.visible = false;

					//uncomment these lines to see a hidden typical item for
					//debugging purposes...
					/*_typicalItemRenderer.visible = true;
					_typicalItemRenderer.x = _horizontalScrollPosition;
					_typicalItemRenderer.y = _verticalScrollPosition;*/
				}
			}
			else
			{
				_typicalItemRenderer.visible = _typicalItemIsInDataProvider;
			}
		}
		HELPER_VECTOR.splice(0, HELPER_VECTOR.length);
	}

	private function renderUnrenderedData():Void
	{
		var itemCount:Int = _unrenderedData.length;
		for(i in 0 ... itemCount)
		{
			
			var item:Dynamic = _unrenderedData.shift();
			var index:Int = _dataProvider.getItemIndex(item);
			var renderer:IListItemRenderer = createRenderer(item, index, true, false);
			renderer.visible = true;
			_layoutItems[index + _layoutIndexOffset] = cast(renderer, DisplayObject);
		}
	}

	private function recoverInactiveRenderers():Void
	{
		var itemCount:Int = _inactiveRenderers.length;
		for(i in 0 ... itemCount)
		{
			var renderer:IListItemRenderer = _inactiveRenderers[i];
			if(renderer == null)
			{
				continue;
			}
			_owner.dispatchEventWith(FeathersEventType.RENDERER_REMOVE, false, renderer);
			_rendererMap.remove(renderer.data);
		}
	}

	private function freeInactiveRenderers(allowKeep:Bool):Void
	{
		//we may keep around some extra renderers to avoid too much
		//allocation and garbage collection. they'll be hidden.
		var itemCount:Int = _inactiveRenderers.length;
		var keepCount:Int;
		if(allowKeep)
		{
			keepCount = _minimumItemCount - _activeRenderers.length;
		}
		else
		{
			keepCount = 0;
		}
		if(itemCount < keepCount)
		{
			keepCount = itemCount;
		}
		//for(var i:Int = 0; i < keepCount; i++)
		var renderer:IListItemRenderer;
		for(i in 0 ... keepCount)
		{
			renderer = _inactiveRenderers.shift();
			if(renderer == null)
			{
				keepCount++;
				if(itemCount < keepCount)
				{
					keepCount = itemCount;
				}
				continue;
			}
			renderer.data = null;
			renderer.index = -1;
			renderer.visible = false;
			_activeRenderers.push(renderer);
		}
		itemCount -= keepCount;
		//for(i = 0; i < itemCount; i++)
		for(i in 0 ... itemCount)
		{
			renderer = _inactiveRenderers.shift();
			if(renderer == null)
			{
				continue;
			}
			destroyRenderer(renderer);
		}
	}

	private function createRenderer(item:Dynamic, index:Int, useCache:Bool, isTemporary:Bool):IListItemRenderer
	{
		
		var renderer:IListItemRenderer;
		do
		{
			if(!useCache || isTemporary || _inactiveRenderers.length == 0)
			{
				if(_itemRendererFactory != null)
				{
					
					renderer = _itemRendererFactory();
				}
				else
				{
					
					renderer = Type.createInstance(_itemRendererType, []);
				}
				var uiRenderer:IFeathersControl = cast(renderer, IFeathersControl);
				if(_customItemRendererStyleName != null && _customItemRendererStyleName.length > 0)
				{
					
					uiRenderer.styleNameList.add(_customItemRendererStyleName);
				}
				
				addChild(cast(renderer, DisplayObject));
			}
			else
			{
				renderer = _inactiveRenderers.shift();
				
			}
			//wondering why this all is in a loop?
			//_inactiveRenderers.shift() may return null because we're
			//storing null values instead of calling splice() to improve
			//performance.
		}
		while (renderer == null);
		renderer.data = item;
		renderer.index = index;
		renderer.owner = _owner;

		if(!isTemporary)
		{
			_rendererMap.set(item, renderer);
			_activeRenderers[_activeRenderers.length] = renderer;
			renderer.addEventListener(Event.TRIGGERED, renderer_triggeredHandler);
			renderer.addEventListener(Event.CHANGE, renderer_changeHandler);
			renderer.addEventListener(FeathersEventType.RESIZE, renderer_resizeHandler);
			_owner.dispatchEventWith(FeathersEventType.RENDERER_ADD, false, renderer);
		}

		return renderer;
	}

	private function destroyRenderer(renderer:IListItemRenderer):Void
	{
		renderer.removeEventListener(Event.TRIGGERED, renderer_triggeredHandler);
		renderer.removeEventListener(Event.CHANGE, renderer_changeHandler);
		renderer.removeEventListener(FeathersEventType.RESIZE, renderer_resizeHandler);
		renderer.owner = null;
		renderer.data = null;
		removeChild(cast(renderer, DisplayObject), true);
	}

	private function childProperties_onChange(proxy:PropertyProxy, name:String):Void
	{
		invalidate(FeathersControl.INVALIDATION_FLAG_STYLES);
	}

	private function owner_scrollStartHandler(event:Event):Void
	{
		_isScrolling = true;
	}

	private function dataProvider_changeHandler(event:Event):Void
	{
		invalidate(FeathersControl.INVALIDATION_FLAG_DATA);
	}

	private function dataProvider_addItemHandler(event:Event, index:Int):Void
	{
		var layout:IVariableVirtualLayout = cast(_layout, IVariableVirtualLayout);
		if(layout == null || !layout.hasVariableItemDimensions)
		{
			return;
		}
		layout.addToVariableVirtualCacheAtIndex(index);
	}

	private function dataProvider_removeItemHandler(event:Event, index:Int):Void
	{
		var layout:IVariableVirtualLayout = cast(_layout, IVariableVirtualLayout);
		if(layout == null || !layout.hasVariableItemDimensions)
		{
			return;
		}
		layout.removeFromVariableVirtualCacheAtIndex(index);
	}

	private function dataProvider_replaceItemHandler(event:Event, index:Int):Void
	{
		var layout:IVariableVirtualLayout = cast(_layout, IVariableVirtualLayout);
		if(layout == null || !layout.hasVariableItemDimensions)
		{
			return;
		}
		layout.resetVariableVirtualCacheAtIndex(index);
	}

	private function dataProvider_resetHandler(event:Event):Void
	{
		_updateForDataReset = true;

		var layout:IVariableVirtualLayout = cast(_layout, IVariableVirtualLayout);
		if(layout == null || !layout.hasVariableItemDimensions)
		{
			return;
		}
		layout.resetVariableVirtualCache();
	}

	private function dataProvider_updateItemHandler(event:Event, index:Int):Void
	{
		var item:Dynamic = _dataProvider.getItemAt(index);
		var renderer:IListItemRenderer = _rendererMap.get(item);
		if(renderer == null)
		{
			return;
		}
		renderer.data = null;
		renderer.data = item;
		trace("*");
		trace("updating here item data(2):"+item.label);
	}

	private function layout_changeHandler(event:Event):Void
	{
		if(_ignoreLayoutChanges)
		{
			return;
		}
		invalidate(FeathersControl.INVALIDATION_FLAG_LAYOUT);
		invalidateParent(FeathersControl.INVALIDATION_FLAG_LAYOUT);
	}

	private function renderer_resizeHandler(event:Event):Void
	{
		if(_ignoreRendererResizing)
		{
			return;
		}
		invalidate(INVALIDATION_FLAG_LAYOUT);
		invalidateParent(INVALIDATION_FLAG_LAYOUT);
		if((cast event.currentTarget) == _typicalItemRenderer && !_typicalItemIsInDataProvider)
		{
			return;
		}
		var layout:IVariableVirtualLayout = safe_cast(_layout, IVariableVirtualLayout);
		if(layout == null || !layout.hasVariableItemDimensions)
		{
			return;
		}
		var renderer:IListItemRenderer = cast(event.currentTarget, IListItemRenderer);
		layout.resetVariableVirtualCacheAtIndex(renderer.index, cast(renderer, DisplayObject));
	}

	private function renderer_triggeredHandler(event:Event):Void
	{
		var renderer:IListItemRenderer = cast(event.currentTarget, IListItemRenderer);
		parent.dispatchEventWith(Event.TRIGGERED, false, renderer.data);
	}

	private function renderer_changeHandler(event:Event):Void
	{
		if(_ignoreSelectionChanges)
		{
			return;
		}
		var renderer:IListItemRenderer = cast(event.currentTarget, IListItemRenderer);
		if(!_isSelectable || _isScrolling)
		{
			renderer.isSelected = false;
			return;
		}
		var isSelected:Bool = renderer.isSelected;
		var index:Int = renderer.index;
		if(_allowMultipleSelection)
		{
			var indexOfIndex:Int = _selectedIndices.getItemIndex(index);
			if(isSelected && indexOfIndex < 0)
			{
				_selectedIndices.addItem(index);
			}
			else if(!isSelected && indexOfIndex >= 0)
			{
				_selectedIndices.removeItemAt(indexOfIndex);
			}
		}
		else if(isSelected)
		{
			_selectedIndices.data = [index];
		}
		else
		{
			_selectedIndices.removeAll();
		}
	}

	private function selectedIndices_changeHandler(event:Event):Void
	{
		invalidate(FeathersControl.INVALIDATION_FLAG_SELECTED);
	}

	private function removedFromStageHandler(event:Event):Void
	{
		touchPointID = -1;
	}

	private function touchHandler(event:TouchEvent):Void
	{
		if(!_isEnabled)
		{
			touchPointID = -1;
			return;
		}

		if(touchPointID >= 0)
		{
			var touch:Touch = event.getTouch(this, TouchPhase.ENDED, touchPointID);
			if(touch == null)
			{
				return;
			}
			touchPointID = -1;
		}
		else
		{
			var touch:Touch = event.getTouch(this, TouchPhase.BEGAN);
			if(touch == null)
			{
				return;
			}
			touchPointID = touch.id;
			_isScrolling = false;
		}
	}
}