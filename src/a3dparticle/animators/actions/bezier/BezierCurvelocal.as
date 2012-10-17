package a3dparticle.animators.actions.bezier
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
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Vector3D;
	
	import away3d.arcane;
	use namespace arcane;
	/**
	 * Bezier formula : P(t)=2t*(1-t)*P1+t*t*P2
	 * @author ...
	 */
	public class BezierCurvelocal extends PerParticleAction
	{
		
		private var _fun:Function;
		
		private var _p1:Vector3D;
		private var _p2:Vector3D;
		
		private var _vertices2:Vector.<Number> = new Vector.<Number>();
		private var _vertexBuffer2:VertexBuffer3D;
		/**
		 *
		 * @param	fun Function.The function return a [p1:Vector3D,p2:Vector3D].
		 */
		public function BezierCurvelocal(fun:Function=null)
		{
			dataLenght = 6;
			_name = "BezierCurvelocal";
			_fun = fun;
		}
		
		override public function genOne(param:ParticleParam):void
		{
			var temp:Array;
			if (_fun != null)
			{
				temp = _fun(param);
			}
			else
			{
				if (!param[_name]) throw new Error("there is no " + _name + " in param!");
				temp = param[_name];
			}
			_p1 = temp[0];
			_p2 = temp[1];
		}
		
		override public function distributeOne(index:int, verticeIndex:uint, subContainer:SubContainer):void
		{
			getExtraData(subContainer).push(_p1.x, _p1.y, _p1.z, _p2.x, _p2.y, _p2.z);
		}
		
		override public function getAGALVertexCode(pass : MaterialPassBase) : String
		{
			var p1Attribute:ShaderRegisterElement = shaderRegisterCache.getFreeVertexAttribute();
			saveRegisterIndex("p1Attribute", p1Attribute.index);
			var p2Attribute:ShaderRegisterElement = shaderRegisterCache.getFreeVertexAttribute();
			saveRegisterIndex("p2Attribute", p2Attribute.index);
			var temp:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var rev_time:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "x");
			var time_2:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "y");
			var time_temp:ShaderRegisterElement = new ShaderRegisterElement(temp.regName, temp.index, "z");
			shaderRegisterCache.addVertexTempUsages(temp, 1);
			var temp2:ShaderRegisterElement = shaderRegisterCache.getFreeVertexVectorTemp();
			var distance:ShaderRegisterElement = new ShaderRegisterElement(temp2.regName, temp2.index, "xyz");
			shaderRegisterCache.removeVertexTempUsage(temp);
			
			var code:String = "";
			code += "sub " + rev_time.toString() + "," + animationRegistersManager.vertexOneConst.toString() + "," + animationRegistersManager.vertexLife.toString() + "\n";
			code += "mul " + time_2.toString() + "," + animationRegistersManager.vertexLife.toString() + "," + animationRegistersManager.vertexLife.toString() + "\n";
			
			code += "mul " + time_temp.toString() + "," + animationRegistersManager.vertexLife.toString() +"," + rev_time.toString() + "\n";
			code += "mul " + time_temp.toString() + "," + time_temp.toString() +"," + animationRegistersManager.vertexTwoConst.toString() + "\n";
			code += "mul " + distance.toString() + "," + time_temp.toString() +"," + p1Attribute.toString() + "\n";
			code += "add " + animationRegistersManager.offsetTarget.toString() +".xyz," + distance.toString() + "," + animationRegistersManager.offsetTarget.toString() + ".xyz\n";
			code += "mul " + distance.toString() + "," + time_2.toString() +"," + p2Attribute.toString() + "\n";
			code += "add " + animationRegistersManager.offsetTarget.toString() +".xyz," + distance.toString() + "," + animationRegistersManager.offsetTarget.toString() + ".xyz\n";
			
			if (_animation.needVelocity)
			{
				code += "mul " + time_2.toString() + "," + animationRegistersManager.vertexLife.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "\n";
				code += "sub " + time_temp.toString() + "," + animationRegistersManager.vertexOneConst.toString() + "," + time_2.toString() + "\n";
				code += "mul " + time_temp.toString() + "," + animationRegistersManager.vertexTwoConst.toString() + "," + time_temp.toString() + "\n";
				code += "mul " + distance.toString() + "," + p1Attribute.toString() + "," + time_temp.toString() + "\n";
				code += "add " + animationRegistersManager.velocityTarget.toString() + ".xyz," + distance.toString() + "," + animationRegistersManager.velocityTarget.toString() + ".xyz\n";
				code += "mul " + distance.toString() + "," + p2Attribute.toString() + "," + time_2.toString() + "\n";
				code += "add " + animationRegistersManager.velocityTarget.toString() + ".xyz," + distance.toString() + "," + animationRegistersManager.velocityTarget.toString() + ".xyz\n";
			}
			
			return code;
		}
		
		override public function setRenderState(stage3DProxy : Stage3DProxy, renderable : IRenderable) : void
		{
			var context : Context3D = stage3DProxy._context3D;
			context.setVertexBufferAt(getRegisterIndex("p1Attribute"), getExtraBuffer(stage3DProxy, SubContainer(renderable)), 0, Context3DVertexBufferFormat.FLOAT_3);
			context.setVertexBufferAt(getRegisterIndex("p2Attribute"), getExtraBuffer(stage3DProxy,SubContainer(renderable)), 3, Context3DVertexBufferFormat.FLOAT_3);
		}
	}

}