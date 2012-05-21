package com.Elements 
{
	import flash.display.Shape;
	
	public class Element extends Shape
	{
		protected var _direction:String;
		//IF IT IS AN APPLE ->
		protected var _catchValue:Number;
		
		//color,alpha,width,height				
		public function Element(_c:uint,_a:Number,_w:Number,_h:Number) 
		{
			graphics.lineStyle(0, _c, _a);
			graphics.beginFill(_c, _a);
			graphics.drawRect(0, 0, _w, _h);
			graphics.endFill();
			
			_catchValue = 0;
		}
		
		//ONLY USED IN CASE OF A PART OF THE SNAKE
		public function set direction(value:String):void
		{
			_direction = value;
		}
		public function get direction():String
		{
			return _direction;
		}
		
		//ONLY USED IN CASE OF AN APPLE
		public function set catchValue(value:Number):void
		{
			_catchValue = value;
		}
		public function get catchValue():Number
		{
			return _catchValue;
		}
	}

}