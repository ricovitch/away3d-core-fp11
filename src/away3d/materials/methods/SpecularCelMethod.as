package away3d.materials.methods
{
	import away3d.arcane;
	import away3d.managers.Stage3DProxy;
    import away3d.materials.compilation.MethodVO;
    import away3d.materials.compilation.ShaderLightingObject;
    import away3d.materials.compilation.ShaderObjectBase;
    import away3d.materials.compilation.ShaderRegisterCache;
	import away3d.materials.compilation.ShaderRegisterData;
	import away3d.materials.compilation.ShaderRegisterElement;
	
	use namespace arcane;
	
	/**
	 * CelSpecularMethod provides a shading method to add specular cel (cartoon) shading.
	 */
	public class SpecularCelMethod extends SpecularCompositeMethod
	{
		private var _dataReg:ShaderRegisterElement;
		private var _smoothness:Number = .1;
		private var _specularCutOff:Number = .1;
		
		/**
		 * Creates a new CelSpecularMethod object.
		 * @param specularCutOff The threshold at which the specular highlight should be shown.
		 * @param baseSpecularMethod An optional specular method on which the cartoon shading is based. If ommitted, BasicSpecularMethod is used.
		 */
		public function SpecularCelMethod(specularCutOff:Number = .5, baseSpecularMethod:SpecularBasicMethod = null)
		{
			super(clampSpecular, baseSpecularMethod);
			_specularCutOff = specularCutOff;
		}
		
		/**
		 * The smoothness of the highlight edge.
		 */
		public function get smoothness():Number
		{
			return _smoothness;
		}
		
		public function set smoothness(value:Number):void
		{
			_smoothness = value;
		}
		
		/**
		 * The threshold at which the specular highlight should be shown.
		 */
		public function get specularCutOff():Number
		{
			return _specularCutOff;
		}
		
		public function set specularCutOff(value:Number):void
		{
			_specularCutOff = value;
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function activate(shaderObject:ShaderObjectBase, methodVO:MethodVO, stage:Stage3DProxy):void
		{
			super.activate(shaderObject, methodVO, stage);
			var index:int = methodVO.secondaryFragmentConstantsIndex;
			var data:Vector.<Number> = shaderObject.fragmentConstantData;
			data[index] = _smoothness;
			data[index + 1] = _specularCutOff;
		}
		
		/**
		 * @inheritDoc
		 */
		arcane override function cleanCompilationData():void
		{
			super.cleanCompilationData();
			_dataReg = null;
		}
		
		/**
		 * Snaps the specular shading strength of the wrapped method to zero or one, depending on whether or not it exceeds the specularCutOff
		 * @param vo The MethodVO used to compile the current shader.
		 * @param t The register containing the specular strength in the "w" component, and either the half-vector or the reflection vector in "xyz".
		 * @param regCache The register cache used for the shader compilation.
		 * @param sharedRegisters The shared register data for this shader.
		 * @return The AGAL fragment code for the method.
		 */
		private function clampSpecular(methodVO:MethodVO, target:ShaderRegisterElement, regCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			return "sub " + target + ".y, " + target + ".w, " + _dataReg + ".y\n" + // x - cutoff
				"div " + target + ".y, " + target + ".y, " + _dataReg + ".x\n" + // (x - cutoff)/epsilon
				"sat " + target + ".y, " + target + ".y\n" +
				"sge " + target + ".w, " + target + ".w, " + _dataReg + ".y\n" +
				"mul " + target + ".w, " + target + ".w, " + target + ".y\n";
		}
		
		/**
		 * @inheritDoc
		 */
		override arcane function getFragmentPreLightingCode(shaderObject:ShaderLightingObject, methodVO:MethodVO, registerCache:ShaderRegisterCache, sharedRegisters:ShaderRegisterData):String
		{
			_dataReg = registerCache.getFreeFragmentConstant();
			methodVO.secondaryFragmentConstantsIndex = _dataReg.index*4;
			return super.getFragmentPreLightingCode(shaderObject, methodVO, registerCache, sharedRegisters);
		}
	}
}