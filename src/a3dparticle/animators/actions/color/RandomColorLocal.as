package a3dparticle.animators.actions.color
{
	import a3dparticle.animators.actions.PerParticleAction;
	import a3dparticle.core.SubContainer;
	import a3dparticle.particle.ParticleParam;
	import away3d.core.base.IRenderable;
	import away3d.core.managers.Stage3DProxy;
	import away3d.materials.passes.MaterialPassBase;
	import away3d.materials.compilation.ShaderRegisterElement;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.geom.ColorTransform;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * ...
	 * @author ...
	 */
	public class RandomColorLocal extends PerParticleAction
	{
		private var _colorFun:Function;
		
		private var _tempColor:ColorTransform;
		
		private var _hasMult:Boolean;
		private var _hasOffset:Boolean;
		
		private var multiplierAtt:ShaderRegisterElement;
		private var multiplierVary:ShaderRegisterElement;
		private var offsetAtt:ShaderRegisterElement;
		private var offsetVary:ShaderRegisterElement;
		
		
		public function RandomColorLocal(fun:Function=null,hasMult:Boolean=true,hasOffset:Boolean=true)
		{
			_colorFun = fun;
			_hasMult = hasMult;
			_hasOffset = hasOffset;
			_name = "RandomColorLocal";
			if (_hasMult && _hasOffset) dataLenght = 8;
			if (_hasMult && !_hasOffset) dataLenght = 4;
			if (!_hasMult && _hasOffset) dataLenght = 4;
			if (!_hasMult && !_hasOffset) throw(new Error("no change!"));
		}
		
		override public function genOne(param:ParticleParam):void
		{
			if (_colorFun != null)
			{
				_tempColor = _colorFun(param);
			}
			else
			{
				if (!param[_name]) throw new Error("there is no " + _name + " in param!");
				_tempColor = param[_name];
			}
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			if (_hasMult)
			{
				getExtraData(subContainer).push(_tempColor.redMultiplier,_tempColor.greenMultiplier,_tempColor.blueMultiplier,_tempColor.alphaMultiplier);
			}
			if (_hasOffset)
			{
				getExtraData(subContainer).push(_tempColor.redOffset,_tempColor.greenOffset,_tempColor.blueOffset,_tempColor.alphaOffset);
			}
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var code:String = "";
			if (animationRegistersManager.needFragmentAnimation)
			{
				if (_hasMult)
				{
					multiplierAtt = shaderRegisterCache.getFreeVertexAttribute();
					saveRegisterIndex("multiplierAtt", multiplierAtt.index);
					multiplierVary = shaderRegisterCache.getFreeVarying();
					code += "mov " + multiplierVary.toString() + "," + multiplierAtt.toString() + "\n";
				}
				if (_hasOffset)
				{
					offsetAtt = shaderRegisterCache.getFreeVertexAttribute();
					saveRegisterIndex("offsetAtt", offsetAtt.index);
					offsetVary = shaderRegisterCache.getFreeVarying();
					code += "mov " + offsetVary.toString() + "," + offsetAtt.toString() + "\n";
				}
			}
			return code;
		}
		
		override public function getAGALFragmentCode(pass : MaterialPassBase) : String
		{
			
			var code:String = "";
			
			if (_hasMult)
			{
				code += "mul " + animationRegistersManager.colorTarget.toString() +"," + multiplierVary.toString() + "," + animationRegistersManager.colorTarget.toString() + "\n";
			}
			if (_hasOffset)
			{
				code += "add " + animationRegistersManager.colorTarget.toString() +"," +offsetVary.toString() + "," + animationRegistersManager.colorTarget.toString() + "\n";
			}
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			if (animationRegistersManager.needFragmentAnimation)
			{
				var context : Context3D = stage3DProxy._context3D;
				if (_hasMult)
				{
					context.setVertexBufferAt(getRegisterIndex("multiplierAtt"), getExtraBuffer(stage3DProxy,SubContainer(renderable)), 0, Context3DVertexBufferFormat.FLOAT_4);
					if (_hasOffset)
						context.setVertexBufferAt(getRegisterIndex("offsetAtt"), getExtraBuffer(stage3DProxy,SubContainer(renderable)), 4, Context3DVertexBufferFormat.FLOAT_4);
				}
				else
				{
					context.setVertexBufferAt(getRegisterIndex("offsetAtt"), getExtraBuffer(stage3DProxy,SubContainer(renderable)), 0, Context3DVertexBufferFormat.FLOAT_4);
				}
			}
		}
		
	}

}